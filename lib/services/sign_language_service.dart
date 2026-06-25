import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'sign_language_api_service.dart';

/// Arabic Sign Language recognition service
/// Integrates with Flask API for sign language recognition
class SignLanguageService {
  bool _isRecognizing = false;
  bool _isPickerActive = false; // Track if image picker is currently active
  final ValueNotifier<String> _translatedText = ValueNotifier<String>('');
  final ValueNotifier<int?> _currentPrediction = ValueNotifier<int?>(null);
  final ValueNotifier<double?> _confidence = ValueNotifier<double?>(null);
  final ValueNotifier<String?> _errorMessage = ValueNotifier<String?>(null);
  final ValueNotifier<String> _debugInfo = ValueNotifier<String>('Initializing...');
  final ValueNotifier<String> _recognitionMode = ValueNotifier<String>('words');
  final ValueNotifier<String> _letterBuffer = ValueNotifier<String>('');
  final ValueNotifier<bool> _suggestLettersMode = ValueNotifier<bool>(false);
  
  Timer? _pauseTimer;
  String? _lastLetter;
  DateTime? _lastLetterTime;
  int _failedWordsCounter = 0;
  String _finalizedTextHistory = ''; // Track finalized words/phrases

  ValueNotifier<String> get translatedText => _translatedText;
  ValueNotifier<int?> get currentPrediction => _currentPrediction;
  ValueNotifier<double?> get confidence => _confidence;
  ValueNotifier<String?> get errorMessage => _errorMessage;
  ValueNotifier<String> get debugInfo => _debugInfo;
  ValueNotifier<String> get recognitionMode => _recognitionMode;
  ValueNotifier<String> get letterBuffer => _letterBuffer;
  ValueNotifier<bool> get suggestLettersMode => _suggestLettersMode;

  final ImagePicker _imagePicker = ImagePicker();
  Timer? _autoSequenceTimer; // kept for backward compatibility (unused in new loop)
  Timer? _clearTimer;

  SignLanguageService() {
    _translatedText.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _translatedText.value;
    if (text.isNotEmpty &&
        text != 'Processing...' &&
        text != 'Encoding image...' &&
        text != 'Sending image to API...') {
      _clearTimer?.cancel();
      _clearTimer = Timer(const Duration(seconds: 5), () {
        clearText();
      });
    }
  }

  /// Start sign language recognition
  /// Note: Continuous auto-capture is disabled - use manual capture button
  Future<void> startRecognition() async {
    if (_isRecognizing) return;
    _isRecognizing = true;
    _errorMessage.value = null;
    _translatedText.value = '';
    
    // Start continuous recognition (but it won't auto-capture)
    _continuousRecognition();
  }

  /// Stop sign language recognition
  Future<void> stopRecognition() async {
    _isRecognizing = false;
    _autoSequenceTimer?.cancel(); // no-op in new loop but safe
    _autoSequenceTimer = null;
    _isPickerActive = false; // Reset picker flag when stopping
    _translatedText.value = '';
    _currentPrediction.value = null;
    _confidence.value = null;
    _errorMessage.value = null;
    _clearTimer?.cancel();
  }

  /// Continuous recognition loop
  /// Re-enabled for real-time automatic recognition.
  Future<void> _continuousRecognition() async {
    // This now just acts as a heartbeat. 
    // The actual capture is handled by startAutoSequenceFromWebRTC or startAutoSequenceFromCamera.
    debugPrint('Recognition loop active');
    while (_isRecognizing) {
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  /// Process a single image and get prediction
  Future<void> processImageFromFile(String imagePath) async {
    await _processImage(imagePath);
  }

  /// Process image and send to API
  Future<void> _processImage(String imagePath) async {
    try {
      _errorMessage.value = null;
      _translatedText.value = 'Processing...';
      
      final imageFile = File(imagePath);
      
      // Check if file exists
      if (!await imageFile.exists()) {
        _errorMessage.value = 'Image file not found';
        _translatedText.value = '';
        return;
      }
      
      _translatedText.value = 'Encoding image...';
      final base64Image = await SignLanguageApiService.imageToBase64(imageFile);

      _translatedText.value = 'Sending image to API...';
      
      // Note: Removed health check before prediction as it was causing delays
      // The prediction call itself will handle connection errors properly
      
      // Send to API with timeout handling
      final result = await SignLanguageApiService.predictSignLanguage(base64Image)
          .timeout(
            const Duration(seconds: 125),
            onTimeout: () {
              throw Exception('Request timeout after 125 seconds');
            },
          );

      if (result.containsKey('success') && result['success'] == true) {
        final prediction = result['prediction'] as int?;
        final conf = (result['confidence'] as num?)?.toDouble();
        final label = result['label']?.toString();

        if (label != null) {
          _currentPrediction.value = prediction;
          _confidence.value = conf;
          _errorMessage.value = null;


          // Append with a space for readability if not empty AND not a duplicate of the last char
            final currentText = _translatedText.value.trim();
            
            // Only append if it's different from the entire last recognized label/phrase
            if (label != currentText && !currentText.endsWith(label)) {
              if (currentText.isEmpty) {
                _translatedText.value = label;
              } else {
                _translatedText.value = '$currentText $label';
              }
              debugPrint('TRANS: Added sign "$label". New text length: ${_translatedText.value.length}');
            }
        } else {
          _errorMessage.value = 'API returned no label';
        }
      } else {
        final errorMsg = result['error'] ?? result['message'] ?? 'API returned unsuccessful response';
        _errorMessage.value = errorMsg.toString();
        _currentPrediction.value = null;
        _confidence.value = null;
      }

    } catch (e) {
      String errorMsg = e.toString();
      debugPrint('Error in _processImage: $errorMsg');
      
      // Make error message more readable
      if (errorMsg.contains('timeout') || errorMsg.contains('Timeout')) {
        // Check if it's a connection timeout (fast) or processing timeout (slow)
        if (errorMsg.contains('Connection timeout') || errorMsg.contains('after') && errorMsg.contains('s') && errorMsg.contains('Cannot reach')) {
          _errorMessage.value = '❌ Cannot connect to Flask server\n\n'
              'URL: ${SignLanguageApiService.currentUrl}\n\n'
              'The server is not reachable.\n\n'
              '🔧 Quick Fix:\n'
              '1. Start Flask server:\n'
              '   cd flask_api\n'
              '   python app.py\n\n'
              '2. Verify IP address:\n'
              '   • Find PC IP: ipconfig (Windows)\n'
              '   • Update: lib/services/sign_language_api_service.dart\n'
              '   • Current: ${SignLanguageApiService.currentUrl}\n\n'
              '3. Test connection:\n'
              '   • Open browser on phone\n'
              '   • Go to: ${SignLanguageApiService.currentUrl}/test\n'
              '   • Should see: {"status":"ok"}\n\n'
              '4. Check network:\n'
              '   • Both devices on same WiFi\n'
              '   • Disable VPN\n'
              '   • Check firewall allows port 5000';
        } else {
          _errorMessage.value = '⏱ Request timeout\n\n'
              'The API took too long to respond.\n\n'
              'Possible causes:\n'
              '• Model processing is very slow\n'
              '• Flask server stopped responding\n'
              '• Network connection issue\n\n'
              'Solutions:\n'
              '1. Check Flask console for errors\n'
              '2. Restart Flask server\n'
              '3. Verify model file exists and is valid';
        }
      } else if (errorMsg.contains('Failed to connect') || 
                 errorMsg.contains('SocketException') ||
                 errorMsg.contains('Cannot reach') ||
                 errorMsg.contains('getaddrinfo failed') ||
                 errorMsg.contains('Connection refused')) {
        _errorMessage.value = '❌ Cannot connect to API\n\n'
            'Current URL: ${SignLanguageApiService.currentUrl}\n\n'
            'The Flask server is not reachable.\n\n'
            '🔧 Step-by-step fix:\n\n'
            '1️⃣ Start Flask Server:\n'
            '   • Open terminal in flask_api folder\n'
            '   • Run: python app.py\n'
            '   • Should see: "Starting server on http://0.0.0.0:5000"\n\n'
            '2️⃣ Find Your PC IP:\n'
            '   • Windows: Open CMD, run: ipconfig\n'
            '   • Look for "IPv4 Address" under WiFi adapter\n'
            '   • Example: 192.168.1.100\n\n'
            '3️⃣ Update IP in Code:\n'
            '   • File: lib/services/sign_language_api_service.dart\n'
            '   • Line 31: static const String _realDeviceIp = ...\n'
            '   • Replace with your PC IP\n\n'
            '4️⃣ Test in Browser:\n'
            '   • On phone, open browser\n'
            '   • Go to: http://YOUR_IP:5000/test\n'
            '   • If this works, app will work too\n\n'
            '5️⃣ Check Network:\n'
            '   • Both devices on SAME WiFi\n'
            '   • Disable VPN if active\n'
            '   • Windows Firewall: Allow Python/port 5000';
      } else {
        _errorMessage.value = 'Error: $errorMsg\n\n'
            'Check Flask console for details.\n'
            'URL: ${SignLanguageApiService.currentUrl}';
      }
      _currentPrediction.value = null;
      _confidence.value = null;
      _translatedText.value = ''; // Clear "Sending to API..." message
    }
  }

  /// Process a single base64 frame (legacy sequence handler refactored for hierarchical model)
  Future<void> _processSingleFrame(String base64Image) async {
    try {
      _errorMessage.value = null;
      
      final result = await SignLanguageApiService.predictSignLanguage(
        base64Image, 
        mode: _recognitionMode.value
      );

      if (result.containsKey('success') && result['success'] == true) {
        final status = result['status']?.toString();
        final quality = result['quality'] as double?;
        
        if (status == 'prediction_ready') {
          final prediction = result['prediction'] as int?;
          final conf = (result['confidence'] as num?)?.toDouble();
          final label = result['label']?.toString();
          
          if (label != null) {
            _currentPrediction.value = prediction;
            _confidence.value = conf;
            _errorMessage.value = null;

            if (_recognitionMode.value == 'words') {
              _debugInfo.value = 'Sign: $label (Q: ${quality?.toStringAsFixed(2)})';
              final currentText = _translatedText.value.trim();
              if (label != currentText && !currentText.endsWith(label)) {
                if (currentText.isEmpty) {
                  _translatedText.value = label;
                } else {
                  _translatedText.value = '$currentText $label';
                }
                _failedWordsCounter = 0; // Reset counter on success
                _suggestLettersMode.value = false;
              }
            } else {
              // Letters Mode Logic
              _handleLetterPrediction(label, conf ?? 0.0);
            }
          }
        } else if (status == 'buffering') {
          final progress = result['buffer_progress']?.toString() ?? "";
          _debugInfo.value = 'Buffering: $progress (Q: ${quality?.toStringAsFixed(2)})';
          
          // If we finished a buffer but didn't get a prediction (server returns buffering after a full cycle)
          if (progress.startsWith("1/") && _recognitionMode.value == 'words') {
             _failedWordsCounter++;
             if (_failedWordsCounter > 5) {
               _suggestLettersMode.value = true;
             }
          }
        } else if (status == 'searching') {
          _debugInfo.value = 'Searching for signs...';
        }
      } else {
        final errorMsg = result['error'] ?? result['message'] ?? 'API error';
        // Only show fatal errors, ignore common MediaPipe failures in log
        if (!errorMsg.toString().contains('No hand detected')) {
           _debugInfo.value = 'Status: $errorMsg';
        } else {
           _debugInfo.value = 'No hand detected';
        }
      }
    } catch (e) {
      debugPrint('Capture Error: $e');
      _debugInfo.value = 'Connection error';
    }
  }


  /// Capture image from camera and process
  Future<void> captureAndPredict() async {
    // Prevent concurrent picker calls
    if (_isPickerActive) {
      _errorMessage.value = 'Camera is already in use. Please wait...';
      return;
    }

    try {
      _errorMessage.value = null;
      _isPickerActive = true;
      
      XFile? image;
      try {
        image = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 640,
          maxHeight: 640,
        );
      } catch (e) {
        if (e.toString().contains('already_active')) {
          throw Exception('Camera is already in use. Please wait and try again.');
        }
        throw e; // Re-throw other errors
      } finally {
        _isPickerActive = false; // Reset flag when done
      }

      if (image != null) {
        await _processImage(image.path);
      }
    } catch (e) {
      _isPickerActive = false; // Reset flag on error
      _errorMessage.value = 'Failed to capture image: ${e.toString()}';
    }
  }

  /// Start automatic sequence capture using a WebRTC MediaStream.
  ///
  /// Awaits each HTTP call so the capture rate is naturally paced by the
  /// server's MediaPipe processing time (~700 ms/frame → ~1.4 FPS).
  /// This matches the temporal spacing the model was trained on in Colab,
  /// while removing the old explicit 300 ms delay for a ~40% speed gain.
  Future<void> startAutoSequenceFromWebRTC(MediaStream stream) async {
    // Ensure we are in a recognizing state
    _isRecognizing = true;

    // Validate stream
    final videoTracks = stream.getVideoTracks();
    if (videoTracks.isEmpty) {
      _errorMessage.value = 'No video track found in stream';
      return;
    }

    _isRecognizing = true;
    _errorMessage.value = null;
    _translatedText.value = '';

    // Use the first video track
    final track = videoTracks.first;

    () async {
      // Short warm-up so camera stabilises
      await Future.delayed(const Duration(milliseconds: 500));

      while (_isRecognizing) {
        try {
          if (track.kind != 'video') {
            _debugInfo.value = 'Track not ready';
            await Future.delayed(const Duration(seconds: 1));
            continue;
          }

          if (!track.enabled) {
            _debugInfo.value = 'Camera paused';
            await Future.delayed(const Duration(seconds: 1));
            continue;
          }

          final byteBuffer = await track.captureFrame();

          if (byteBuffer.lengthInBytes > 0) {
            final bytes = byteBuffer.asUint8List();
            final base64String = base64Encode(bytes);
            // Await the HTTP call — its round-trip time (~700 ms) provides
            // natural pacing that matches the model's training cadence.
            // No extra delay needed.
            await _processSingleFrame(base64String);
          }
        } catch (e) {
          debugPrint('Auto-recognition capture error: $e');
          _debugInfo.value = 'Capture Error';
          await Future.delayed(const Duration(seconds: 2));
        }

        if (!_isRecognizing) break;
        // No explicit delay — HTTP round-trip is sufficient pacing.
      }
    }();


  }

  /// Start automatic sequence capture using a live camera controller.
  Future<void> startAutoSequenceFromCamera(dynamic controller) async {
    // If no valid controller, do not start
    if (controller == null) return;
    if (_isRecognizing) return;

    _isRecognizing = true;
    _errorMessage.value = null;
    _translatedText.value = '';

    // Capture a sequence every few seconds in a single async loop to
    // avoid overlapping takePicture() calls.
    const sequenceLength = 15;
    const frameDelay = Duration(milliseconds: 150);
    const betweenSequencesDelay = Duration(seconds: 1);

    () async {
      while (_isRecognizing) {
        try {
          final value = controller.value;
          if (value == null || value.isInitialized != true) {
            _debugInfo.value = 'Camera not ready';
            await Future.delayed(const Duration(seconds: 1));
            continue;
          }

          _debugInfo.value = 'Capturing...';
          final XFile xfile = await controller.takePicture();
          final file = File(xfile.path);
          final base64String = await SignLanguageApiService.imageToBase64(file);
          await _processSingleFrame(base64String);
          
          // Cleanup the temporary file
          if (await file.exists()) await file.delete();
          
        } catch (e) {
          debugPrint('Auto-camera capture error: $e');
        }

        if (!_isRecognizing) break;
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }();


  }

  /// Select image from gallery and process
  Future<void> selectAndPredict() async {
    // Prevent concurrent picker calls
    if (_isPickerActive) {
      _errorMessage.value = 'Image picker is already in use. Please wait...';
      return;
    }

    try {
      _errorMessage.value = null;
      _isPickerActive = true;
      
      XFile? image;
      try {
        image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 640,
          maxHeight: 640,
        );
      } catch (e) {
        if (e.toString().contains('already_active')) {
          throw Exception('Image picker is already in use. Please wait and try again.');
        }
        throw e; // Re-throw other errors
      } finally {
        _isPickerActive = false; // Reset flag when done
      }

      if (image != null) {
        await _processImage(image.path);
      }
    } catch (e) {
      _isPickerActive = false; // Reset flag on error
      _errorMessage.value = 'Failed to select image: ${e.toString()}';
    }
  }

  /// Map prediction number to Arabic sign language text
  /// TODO: Replace with your actual class mapping based on your model
  String _mapPredictionToText(int prediction) {
    // Precise mapping for 31 classes based on your model labels:
    // 0: Ain, 1: Al, 2: Alef, 3: Beh, 4: Dad, 5: Dal, 6: Feh, 7: Ghain, 8: Hah, 9: Heh,
    // 10: Jeem, 11: Kaf, 12: Khah, 13: Laa, 14: Lam, 15: Meem, 16: Noon, 17: Qaf, 18: Reh, 19: Sad,
    // 20: Seen, 21: Sheen, 22: Tah, 23: Teh, 24: Teh_Marbuta, 25: Thal, 26: Theh, 27: Waw, 28: Yeh, 29: Zah, 30: Zain
    const Map<int, String> predictionMap = {
      0: 'ع', 1: 'ال', 2: 'أ', 3: 'ب', 4: 'ض', 5: 'د', 6: 'ف', 7: 'غ', 8: 'ح', 9: 'هـ',
      10: 'ج', 11: 'ك', 12: 'خ', 13: 'لا', 14: 'ل', 15: 'م', 16: 'ن', 17: 'ق', 18: 'ر', 19: 'ص',
      20: 'س', 21: 'ش', 22: 'ط', 23: 'ت', 24: 'ة', 25: 'ذ', 26: 'ث', 27: 'و', 28: 'ي', 29: 'ظ', 30: 'ز'
    };

    return predictionMap[prediction] ?? 'غير معروف';
  }

  bool get isRecognizing => _isRecognizing;
  
  /// Clear the accumulated translated text
  void clearText() {
    _clearTimer?.cancel();
    _translatedText.value = '';
    _letterBuffer.value = '';
    _currentPrediction.value = null;
    _confidence.value = null;
    _lastLetter = null;
    _lastLetterTime = null;
    _finalizedTextHistory = '';
    _pauseTimer?.cancel();
  }

  /// Switch recognition mode
  void setMode(String mode) {
    if (mode == _recognitionMode.value) return;
    _recognitionMode.value = mode;
    _letterBuffer.value = '';
    _lastLetter = null;
    _lastLetterTime = null;
    _finalizedTextHistory = _translatedText.value.trim(); // Save current state
    _failedWordsCounter = 0;
    _suggestLettersMode.value = false;
    _pauseTimer?.cancel();
    debugPrint('Service Mode Switched to: $mode');
  }

  /// Logic for handling letters with pause detection and duplicate filtering
  void _handleLetterPrediction(String letter, double confidence) {
    final now = DateTime.now();
    
    // 1. Duplicate filtering & 900ms debounce
    if (_lastLetter == letter) {
      if (_lastLetterTime != null && now.difference(_lastLetterTime!).inMilliseconds < 900) {
        return; // Too fast, ignore duplicate
      }
    }

    _lastLetter = letter;
    _lastLetterTime = now;
    _debugInfo.value = 'Letter: $letter (${(confidence * 100).toStringAsFixed(0)}%)';

    // Update buffer
    _letterBuffer.value += letter;
    
    // Update main text for display (typing effect)
    _updateTranslatedTextFromBuffer();

    // 2. Pause detection (3.0s) - allows more time between signs for continuous word building
    _pauseTimer?.cancel();
    _pauseTimer = Timer(const Duration(milliseconds: 3000), () {
      _finalizeWord();
    });
  }

  void _updateTranslatedTextFromBuffer() {
    // Display finalized history + current active buffer with a cursor
    // For Arabic letters, we want them connected, so we avoid adding spaces between chunks
    if (_letterBuffer.value.isEmpty) {
      _translatedText.value = _finalizedTextHistory;
    } else {
      _translatedText.value = '$_finalizedTextHistory${_letterBuffer.value}_';
    }
  }

  void _finalizeWord() {
    if (_letterBuffer.value.isEmpty) return;
    
    final word = _letterBuffer.value;
    // Append the word to history with a space for separation
    _finalizedTextHistory = '$_finalizedTextHistory$word ';
    
    _translatedText.value = _finalizedTextHistory;
    _letterBuffer.value = '';
    _lastLetter = null;
    debugPrint('Word segment finalized: $word');
  }

  /// Manually finalize the current word
  void finalizeManually() {
    _finalizeWord();
    _pauseTimer?.cancel();
  }
}
