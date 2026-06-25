import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'package:meeting/utils/app_config.dart';

/// Service for communicating with Flask API for sign language recognition
class SignLanguageApiService {
  // API base URL configuration
  // IMPORTANT: For real Android devices, set AppConfig.apiHost to your PC's local IP
  // For Android Emulator: use http://10.0.2.2:5000 (set AppConfig.apiHost accordingly)
  // For iOS Simulator: http://localhost:5000 (AppConfig.apiHost can be 'localhost')

  static const int _port = 5000;

  static String get baseUrl {
    // Prefer explicit AppConfig value, but provide sane defaults for emulators
    final configuredHost = AppConfig.apiHost;

    if (kDebugMode) {
      if (Platform.isAndroid) {
        // On Android emulator, 10.0.2.2 forwards to host loopback
        if (configuredHost == 'localhost' || configuredHost == '127.0.0.1') {
          return 'http://10.0.2.2:$_port';
        }
        return 'http://$configuredHost:$_port';
      } else {
        // iOS Simulator can use localhost
        if (configuredHost == '10.0.2.2') {
          // If user put emulator host accidentally, map back to localhost for iOS
          return 'http://localhost:$_port';
        }
        return 'http://$configuredHost:$_port';
      }
    }

    // Production: use configured host
    return 'http://${AppConfig.apiHost}:$_port';
  }

  /// Get the current API URL (for debugging)
  static String get currentUrl => baseUrl;

  /// Convert image file to base64 string
  static Future<String> imageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      throw Exception('Failed to convert image to base64: $e');
    }
  }

  /// Convert image bytes to base64 string
  static String imageBytesToBase64(List<int> imageBytes) {
    try {
      return base64Encode(imageBytes);
    } catch (e) {
      throw Exception('Failed to convert image bytes to base64: $e');
    }
  }

  /// Send image to Flask API and get prediction
  static Future<Map<String, dynamic>> predictSignLanguage(String base64Image, {String mode = 'words'}) async {
    try {
      final url = Uri.parse('$baseUrl/predict');
      developer.log('Sending request to: $url (Mode: $mode)');
      developer.log('Image size: ${base64Image.length} characters');
      
      final stopwatch = Stopwatch()..start();
      
      // Create a client with timeout configuration
      final client = http.Client();
      
      try {
        // First, try to establish connection with a shorter timeout
        // This helps catch connection issues faster
        developer.log('Attempting to connect to: $url');
        
        final response = await client.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'image': base64Image,
            'mode': mode,
          }),
        ).timeout(
          const Duration(seconds: 120), // Total timeout for request + processing
          onTimeout: () {
            stopwatch.stop();
            final elapsed = stopwatch.elapsed.inSeconds;
            if (elapsed < 10) {
              // If it times out quickly, it's likely a connection issue
              throw TimeoutException(
                'Connection timeout after ${elapsed}s\n\n'
                'Cannot reach Flask server at: $baseUrl\n\n'
                'Quick fixes:\n'
                '1. Check Flask is running: python flask_api/app.py\n'
                '2. Verify IP address in sign_language_api_service.dart\n'
                '3. Test in browser: http://YOUR_IP:5000/test\n'
                '4. Ensure both devices on same WiFi',
                const Duration(seconds: 120),
              );
            } else {
              // If it took longer, it might be processing
              throw TimeoutException(
                'Request timeout after ${elapsed}s\n\n'
                'The API took too long to respond.\n\n'
                'Possible causes:\n'
                '• Model processing is very slow\n'
                '• Flask server not responding\n'
                '• Network connection issue\n\n'
                'Check Flask console for errors.',
                const Duration(seconds: 120),
              );
            }
          },
        );
        
        stopwatch.stop();
        developer.log('Response received in ${stopwatch.elapsed.inSeconds}s');
        developer.log('Status code: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return data;
        } else {
          String errorMessage = 'API request failed with status ${response.statusCode}';
          try {
            final errorData = jsonDecode(response.body) as Map<String, dynamic>;
            errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
          } catch (_) {
            errorMessage = '${response.statusCode}: ${response.body}';
          }
          throw Exception(errorMessage);
        }
      } finally {
        client.close();
      }
    } on TimeoutException catch (e) {
      throw Exception(e.message ?? 'Request timeout');
    } on SocketException {
      throw Exception(
        'Failed to connect to API at $baseUrl\n\n'
        'For Real Device:\n'
        '1. Ensure Flask server is running on your PC\n'
        '2. Check your PC\'s IP address (run: ipconfig on Windows)\n'
        '3. Update AppConfig.apiHost in lib/utils/app_config.dart\n'
        '4. Ensure phone and PC are on same WiFi network\n'
        '5. Check Windows Firewall allows port 5000'
      );
    } on http.ClientException catch (e) {
      throw Exception(
        'Connection error: ${e.message}\n\n'
        'Current API URL: $baseUrl\n\n'
        'Troubleshooting:\n'
        '• Is Flask server running? (python flask_api/app.py)\n'
        '• Is API host correct? (check lib/utils/app_config.dart)\n'
        '• Are devices on same WiFi?\n'
        '• Check firewall settings'
      );
    } on FormatException {
      throw Exception('Invalid response from server.');
    } catch (e) {
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('Network is unreachable')) {
        throw Exception(
          'Cannot reach API server\n\n'
          'URL: $baseUrl\n\n'
          'Solutions:\n'
          '1. Find your PC\'s IP: Windows (ipconfig) or Mac/Linux (ifconfig)\n'
          '2. Update AppConfig.apiHost in lib/utils/app_config.dart\n'
          '3. Ensure Flask is running: python flask_api/app.py\n'
          '4. Check both devices are on same WiFi\n'
          '5. Disable VPN if active'
        );
      }
      // Re-throw TimeoutException if it was already caught
      if (e is TimeoutException) {
        rethrow;
      }
      throw Exception('Error: ${e.toString()}');
    }
  }

  // predictSignLanguageSequence was removed because the backend now uses a single-frame YOLOv8 model.
  // Use predictSignLanguage for all recognition tasks.


  /// Check API health with detailed diagnostics
  static Future<Map<String, dynamic>> checkHealth() async {
    final url = baseUrl;
    final uri = Uri.parse('$url/health');
    
    try {
      // Try to connect
      final response = await http.get(uri).timeout(
        const Duration(seconds: 30), // Increased timeout for real devices and slow networks
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Health check failed with status ${response.statusCode}');
      }
    } on SocketException catch (e) {
      // Provide very specific error message
      final errorDetails = '''
❌ Connection Failed

Current API URL: $url

Error: ${e.message}

🔧 How to Fix:

1️⃣ Find Your PC's IP Address:
   • Windows: Open CMD, run: ipconfig
   • Look for "IPv4 Address" (e.g., 192.168.1.100)
   
2️⃣ Update the Code:
   • Open: lib/utils/app_config.dart
   • Set AppConfig.apiHost to YOUR PC's IP from step 1
   
3️⃣ Start Flask Server:
   • Open terminal in flask_api folder
   • Run: python app.py
   • Should see: "Starting server on http://0.0.0.0:5000"
   
4️⃣ Check Network:
   • Phone and PC must be on SAME WiFi
   • Disable VPN if active
   • Check Windows Firewall allows Python

5️⃣ Test Connection:
   • On phone browser, try: http://YOUR_PC_IP:5000/health
   • If browser works, app will work too

Current API host being used: ${AppConfig.apiHost}
''';
      throw Exception(errorDetails);
    } on TimeoutException {
      throw Exception(
        '⏱ Connection Timeout\n\n'
        'URL: $url\n\n'
        'Possible causes:\n'
        '• Flask server not running\n'
        '• Wrong IP address\n'
        '• Firewall blocking connection\n'
        '• Devices on different networks\n\n'
        'Fix:\n'
        '1. Ensure Flask is running: python flask_api/app.py\n'
        '2. Check IP address is correct\n'
        '3. Test in phone browser first'
      );
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('Failed host lookup') || 
          errorMsg.contains('Network is unreachable') ||
          errorMsg.contains('getaddrinfo failed')) {
        throw Exception(
          '🌐 Network Error\n\n'
          'Cannot resolve host: $url\n\n'
          'This means the IP address is wrong or unreachable.\n\n'
          '✅ Solution:\n'
          '1. Find PC IP: ipconfig (Windows) or ifconfig (Mac/Linux)\n'
          '2. Update AppConfig.apiHost in lib/utils/app_config.dart\n'
          '3. Current API host setting: ${AppConfig.apiHost}\n'
          '4. Restart app after changing API host'
        );
      }
      throw Exception('Connection error: $errorMsg\n\nURL: $url');
    }
  }
}
