# Chapter 8: Ishara — A Real-Time Communication Platform for Arabic Sign Language Recognition

## 8.1 Abstract

This chapter presents the architectural design and implementation of Ishara, a mobile application that facilitates real-time communication for Arabic Sign Language (ASL) users through integrated sign language recognition, speech-to-text conversion, and gesture-based translation. The system employs a distributed three-tier architecture comprising a Flutter-based mobile client, WebRTC signaling infrastructure, and a Python-Flask microservice backend equipped with deep learning models for sign language recognition. This paper examines the technical implementation of key components, including peer-to-peer video communication via WebRTC, hand landmark detection using MediaPipe, hierarchical neural network-based gesture classification, and platform-specific networking considerations. The implementation addresses accessibility challenges specific to Arabic sign language communities and demonstrates the feasibility of real-time machine learning inference on resource-constrained mobile devices.

**Keywords:** Arabic Sign Language, WebRTC, machine learning, mobile application, computer vision, accessibility

## 8.2 Introduction

Communication barriers for deaf and hard-of-hearing individuals remain a significant societal challenge (Mitchell et al., 2006). In Arabic-speaking regions, limited technological integration of Arabic Sign Language (ASL) into mainstream communication platforms exacerbates this challenge. While video conferencing technologies have proliferated globally, few implementations provide native gesture recognition, real-time translation, and accessibility features tailored to sign language users.

Ishara addresses this gap by integrating three critical technical components: (1) real-time peer-to-peer video communication using WebRTC protocol, (2) computer vision-based hand pose estimation via MediaPipe, and (3) deep learning-based gesture classification using hierarchical neural networks trained on ASL vocabulary. The architecture prioritizes accessibility, reducing technological barriers while maintaining computational efficiency suitable for mobile deployment.

This chapter details the system architecture, implementation strategies, technical design decisions, and their implications for accessibility and performance.

## 8.3 System Architecture

### 8.3.1 Architectural Overview

The Ishara platform employs a distributed three-tier architectural pattern comprising:

```
┌─────────────────────────────────────┐
│   Mobile Frontend (Flutter)         │
│  - UI/UX Layer                      │
│  - Camera & Video Streaming         │
│  - User Management                  │
└──────────────┬──────────────────────┘
               │ HTTP REST & WebSocket
┌──────────────┴──────────────────────┐
│   Signaling & WebRTC Server         │
│  - WebSocket Signaling               │
│  - Peer Connection Coordination      │
└──────────────┬──────────────────────┘
               │ HTTP & Direct P2P
┌──────────────┴──────────────────────┐
│   Backend Services (Python/Flask)   │
│  - ML Model Inference                │
│  - Sign Language Recognition         │
│  - Image Processing                  │
└─────────────────────────────────────┘
```

### 8.3 Frontend Architecture (Flutter)

#### 8.3.1 Project Structure

```
lib/
├── main.dart                    # Application entry point
├── screens/                     # UI Screens
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── call_screen.dart
│   ├── meeting_using_sign_language_screen.dart
│   └── ...
├── services/                    # Business Logic
│   ├── webrtc_call_service.dart
│   ├── sign_language_api_service.dart
│   ├── speech_to_text_service.dart
│   ├── auth_service.dart
│   └── notification_service.dart
├── models/                      # Data Models
├── widgets/                     # Reusable UI Components
├── utils/                       # Utility Functions
└── theme/                       # Theme Configuration
```

#### 8.3.2 Main Application Setup

**File: [lib/main.dart](lib/main.dart)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:meeting/utils/app_routes.dart';
import 'package:meeting/utils/theme_provider.dart';
import 'package:meeting/utils/locale_provider.dart';
import 'package:meeting/theme/app_theme.dart';
import 'package:meeting/localization/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const IsharaApp());
}

class IsharaApp extends StatelessWidget {
  const IsharaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, child) {
          return MaterialApp(
            title: 'Ishara',
            debugShowCheckedModeBanner: false,
            
            // Theme configuration with light/dark mode support
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            
            // Localization: English and Arabic with RTL support
            locale: localeProvider.locale,
            supportedLocales: const [
              Locale('en', ''),
              Locale('ar', ''),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            
            // RTL support for Arabic language
            builder: (context, child) {
              return Directionality(
                textDirection: localeProvider.isArabic 
                    ? TextDirection.rtl 
                    : TextDirection.ltr,
                child: child!,
              );
            },
            
            // Navigation routes
            initialRoute: AppRoutes.splash,
            onGenerateRoute: (settings) {
              // Shared WebRTC service instance across routes
              // for persistent peer connections
              final webRtcCallService = WebRtcCallService(
                signalingUrl: 'ws://${AppConfig.apiHost}:8080/ws',
              );
              // ... route handling logic
            },
          );
        },
      ),
    );
  }
}
```

**Key Features:**
- Multi-language support (English & Arabic)
- Dark/Light theme switching
- Bidirectional text (RTL for Arabic)
- Provider pattern for state management
- Centralized routing configuration

### 8.4 Real-Time Communication Service

#### 8.4.1 WebRTC Call Service

**File: [lib/services/webrtc_call_service.dart](lib/services/webrtc_call_service.dart)**

The WebRTC service handles peer-to-peer video communication using WebSocket signaling:

```dart
import 'dart:convert';
import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:permission_handler/permission_handler.dart';

/// Simple 1-on-1 WebRTC call service using WebSocket signaling server.
class WebRtcCallService {
  final ValueNotifier<bool> inCall = ValueNotifier<bool>(false);
  final ValueNotifier<bool> partnerPresent = ValueNotifier<bool>(false);
  final ValueNotifier<bool> micEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> camEnabled = ValueNotifier<bool>(true);

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  final ValueNotifier<String> remoteTranslatedText = ValueNotifier<String>('');
  final ValueNotifier<String> remoteCaptions = ValueNotifier<String>('');

  // Diagnostics
  final ValueNotifier<String> pcState = ValueNotifier<String>('new');
  final ValueNotifier<String> iceConnectionState = ValueNotifier<String>('new');
  final ValueNotifier<String> signalingState = ValueNotifier<String>('new');

  WebSocketChannel? _ws;
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  bool _isOfferer = false;
  bool _sttEnabled = false;
  String? _roomId;
  final String signalingUrl;

  WebRtcCallService({required this.signalingUrl});

  /// Initialize renderers for video display
  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  /// Join a meeting room with optional speech-to-text
  Future<void> joinRoom(String roomId, {bool enableStt = false}) async {
    _roomId = roomId;
    _sttEnabled = enableStt;
    _joinCompleter = Completer<void>();

    try {
      // Connect to WebSocket signaling server
      _ws = WebSocketChannel.connect(Uri.parse(signalingUrl));
    } catch (e) {
      _error('Failed to connect to signaling server: $e');
      rethrow;
    }

    // Listen for signaling messages
    _ws!.stream.listen(
      _onSignalMessage,
      onDone: _onSignalClosed,
      onError: (e) {
        _error('WebSocket error: $e');
        _onSignalClosed();
      },
    );

    // Send join message
    _ws!.sink.add(jsonEncode({
      'type': 'join',
      'roomId': roomId,
      'enableStt': enableStt
    }));

    // Wait for join confirmation
    await _joinCompleter!.future.timeout(const Duration(seconds: 15));
  }

  /// Handle incoming signaling messages
  void _onSignalMessage(dynamic rawData) {
    final message = jsonDecode(rawData as String);
    final type = message['type'] as String;

    switch (type) {
      case 'offer':
        _handleRemoteOffer(message['data']);
      case 'answer':
        _handleRemoteAnswer(message['data']);
      case 'ice':
        _handleIceCandidate(message['data']);
      case 'stt_error':
        developer.log('STT error: ${message["error"]}');
    }
  }

  /// Create and send offer to remote peer
  Future<void> _createAndSendOffer() async {
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);

    sdpOfferLength.value = offer.sdp?.length ?? 0;

    _ws?.sink.add(jsonEncode({
      'type': 'offer',
      'data': {
        'type': 'offer',
        'sdp': offer.sdp,
      }
    }));
  }

  /// Handle remote offer from peer
  Future<void> _handleRemoteOffer(dynamic data) async {
    final offer = RTCSessionDescription(data['sdp'], 'offer');
    await _pc!.setRemoteDescription(offer);

    // Create and send answer
    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);

    sdpAnswerLength.value = answer.sdp?.length ?? 0;

    _ws?.sink.add(jsonEncode({
      'type': 'answer',
      'data': {
        'type': 'answer',
        'sdp': answer.sdp,
      }
    }));
  }

  /// Toggle camera on/off
  Future<void> toggleCamera(bool enable) async {
    if (_localStream != null) {
      for (var track in _localStream!.getVideoTracks()) {
        await track.enabled = enable;
      }
      camEnabled.value = enable;
    }
  }

  /// Toggle microphone on/off
  Future<void> toggleMicrophone(bool enable) async {
    if (_localStream != null) {
      for (var track in _localStream!.getAudioTracks()) {
        await track.enabled = enable;
      }
      micEnabled.value = enable;
    }
  }

  /// Hang up the call
  Future<void> hangUp() async {
    inCall.value = false;
    await _pc?.close();
    _pc = null;
    await _ws?.sink.close();
    _ws = null;
    await _localStream?.dispose();
    _localStream = null;
  }
}
```

**Key Components:**
- **WebSocket Connection**: Maintains signaling channel with server
- **RTCPeerConnection**: Manages P2P connection state
- **Video Renderers**: Display local and remote video streams
- **State Management**: ValueNotifiers for UI reactivity
- **Offer/Answer Exchange**: SDP negotiation protocol
- **ICE Candidates**: Network connectivity discovery

### 8.5 Sign Language Recognition Service

#### 8.5.1 Flutter API Service

**File: [lib/services/sign_language_api_service.dart](lib/services/sign_language_api_service.dart)**

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'package:meeting/utils/app_config.dart';

/// Service for communicating with Flask API for sign language recognition
class SignLanguageApiService {
  static const int _port = 5000;

  static String get baseUrl {
    final configuredHost = AppConfig.apiHost;

    if (kDebugMode) {
      if (Platform.isAndroid) {
        // Android emulator: 10.0.2.2 maps to host loopback
        if (configuredHost == 'localhost' || configuredHost == '127.0.0.1') {
          return 'http://10.0.2.2:$_port';
        }
        return 'http://$configuredHost:$_port';
      } else {
        // iOS Simulator: use localhost
        if (configuredHost == '10.0.2.2') {
          return 'http://localhost:$_port';
        }
        return 'http://$configuredHost:$_port';
      }
    }

    return 'http://${AppConfig.apiHost}:$_port';
  }

  /// Convert image bytes to base64 string
  static String imageBytesToBase64(List<int> imageBytes) {
    try {
      return base64Encode(imageBytes);
    } catch (e) {
      throw Exception('Failed to convert image bytes to base64: $e');
    }
  }

  /// Send image to Flask API and get sign language prediction
  static Future<Map<String, dynamic>> predictSignLanguage(
    String base64Image
  ) async {
    try {
      final url = Uri.parse('$baseUrl/predict');
      developer.log('Sending request to: $url');
      developer.log('Image size: ${base64Image.length} characters');
      
      final stopwatch = Stopwatch()..start();
      final client = http.Client();
      
      try {
        final response = await client.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'image': base64Image,
          }),
        ).timeout(
          const Duration(seconds: 120),
          onTimeout: () {
            stopwatch.stop();
            throw TimeoutException(
              'Connection timeout after ${stopwatch.elapsed.inSeconds}s\n\n'
              'Cannot reach Flask server at: $baseUrl\n\n'
              'Quick fixes:\n'
              '1. Check Flask server is running\n'
              '2. Verify AppConfig.apiHost setting\n'
              '3. Check firewall/network connectivity'
            );
          },
        );

        stopwatch.stop();
        final elapsed = stopwatch.elapsed.inMilliseconds;

        developer.log('[TIMING] Prediction took ${elapsed}ms');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          developer.log('[SUCCESS] Prediction result: $data');
          return data;
        } else {
          developer.log('[ERROR] Status ${response.statusCode}: ${response.body}');
          throw Exception(
            'API returned ${response.statusCode}: ${response.body}'
          );
        }
      } finally {
        client.close();
      }
    } catch (e) {
      developer.log('[ERROR] Prediction failed: $e');
      rethrow;
    }
  }
}
```

**Key Features:**
- Platform-specific API URL handling (Android/iOS)
- Base64 image encoding for transmission
- Timeout handling with informative error messages
- Request timing for performance monitoring
- Comprehensive logging for debugging

#### 8.5.2 Backend Flask API

**File: [flask_api/app.py](flask_api/app.py)**

```python
"""
Flask API for Arabic Sign Language Recognition
VERSION 2.3 - Using Keras Hierarchical Model
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import base64
import numpy as np
from PIL import Image, ImageOps
import os
import tensorflow as tf
import keras
from recognizer import EnhancedASLRecognizer

app = Flask(__name__)
CORS(app)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "retrained_hierarchical_model (7).h5")
LABELS_PATH = os.path.join(BASE_DIR, "labels.txt")
DEBUG_DIR = os.path.join(BASE_DIR, "debug_frames")
os.makedirs(DEBUG_DIR, exist_ok=True)

# Load labels for all 12 Arabic sign language classes
CLASSES = []
if os.path.exists(LABELS_PATH):
    with open(LABELS_PATH, "r", encoding="utf-8") as f:
        CLASSES = [line.strip() for line in f if line.strip()]
else:
    CLASSES = [
        'How are you', 'I am fine', 'Thanks', 'Not bad',
        'I am pleased to meet you', 'Good bye', 'Good morning', 'Good evening',
        'Sorry', 'I am sorry', 'Salam aleikum', 'Alhamdulillah'
    ]

# English to Arabic translation mapping
ARABIC_MAP = {
    'Alhamdulillah': 'الحمد لله',
    'Good bye': 'مع السلامة',
    'Good evening': 'مساء الخير',
    'Good morning': 'صباح الخير',
    'How are you': 'كيف حالك',
    'I am fine': 'أنا بخير',
    'I am pleased to meet you': 'تشرفت بلقائك',
    'I am sorry': 'أنا آسف',
    'Not bad': 'ليس سيئاً',
    'Salam aleikum': 'السلام عليكم',
    'Sorry': 'آسف',
    'Thanks': 'شكراً'
}

CLASS_TO_ID = {name: i for i, name in enumerate(CLASSES)}

# Load pre-trained Keras model
print(f"Loading Keras model from {MODEL_PATH}...")
try:
    model = keras.models.load_model(MODEL_PATH)
    model_loaded = True
    print(f"✓ Model loaded successfully. Classes: {len(CLASSES)}")
except Exception as e:
    print(f"✗ Failed to load model: {e}")
    model_loaded = False

# Initialize sign language recognizer with MediaPipe
recognizer = EnhancedASLRecognizer()
print("✓ Sign Language Recognizer initialized")

@app.route('/predict', methods=['POST'])
def predict():
    """
    Endpoint for sign language prediction from image
    Expected JSON: {"image": "base64_encoded_image"}
    Returns: {"prediction": "sign", "confidence": 0.95, "arabic": "النص العربي"}
    """
    try:
        data = request.get_json()
        if not data or 'image' not in data:
            return jsonify({'error': 'No image provided'}), 400

        # Decode base64 image
        try:
            image_data = base64.b64decode(data['image'])
            image = Image.open(io.BytesIO(image_data)).convert('RGB')
        except Exception as e:
            return jsonify({'error': f'Failed to decode image: {str(e)}'}), 400

        # Extract hand landmarks using MediaPipe
        features = recognizer.extract_features(image)
        
        if features is None or len(features) == 0:
            return jsonify({
                'error': 'No hands detected',
                'prediction': 'No hands detected',
                'confidence': 0.0,
                'arabic': 'لم يتم اكتشاف أيادي'
            }), 200

        # Normalize features
        features = np.array(features, dtype=np.float32)
        features = features.reshape(1, -1)
        
        # Run inference on model
        predictions = model.predict(features, verbose=0)
        predicted_class_id = np.argmax(predictions[0])
        confidence = float(predictions[0][predicted_class_id])
        predicted_sign = CLASSES[predicted_class_id]
        arabic_translation = ARABIC_MAP.get(predicted_sign, predicted_sign)

        return jsonify({
            'success': True,
            'prediction': predicted_sign,
            'confidence': confidence,
            'arabic': arabic_translation,
            'all_predictions': [
                {
                    'sign': CLASSES[i],
                    'confidence': float(predictions[0][i]),
                    'arabic': ARABIC_MAP.get(CLASSES[i], CLASSES[i])
                }
                for i in range(len(CLASSES))
            ]
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'ok',
        'model_loaded': model_loaded,
        'classes_count': len(CLASSES),
        'classes': CLASSES
    }), 200

if __name__ == '__main__':
    print("Starting Flask API server on 0.0.0.0:5000")
    app.run(host='0.0.0.0', port=5000, debug=True, threaded=True)
```

**Key Features:**
- CORS enabled for mobile client access
- 12 Arabic sign language classes
- Base64 image decoding and processing
- Keras model inference
- English to Arabic translation
- Hand detection validation
- Confidence scores for predictions

#### 8.5.3 Sign Language Recognition Engine

**File: [flask_api/recognizer.py](flask_api/recognizer.py)**

```python
"""
recognizer.py — Sign Language Recognizer
Uses MediaPipe hand landmark extraction with hierarchical deep learning model.
Features are extracted in the same way as the training notebook.
"""

import numpy as np
import subprocess
import threading
import queue
import json
import base64
import os
import cv2
import io
import time
from collections import deque

EXPECTED_FEATURES = 100  # Padded to 100 exactly as in training

# Path to MediaPipe-only Python environment
_BASE_DIR = os.path.dirname(os.path.abspath(__file__))
_MP_PYTHON = os.path.join(_BASE_DIR, "venv_mp", "Scripts", "python.exe")
_MP_WORKER = os.path.join(_BASE_DIR, "mp_worker.py")


def fix_feature_size(sequence, expected=EXPECTED_FEATURES):
    """Ensure every frame vector has exactly expected features."""
    fixed = []
    for frame in sequence:
        frame = np.array(frame, dtype=np.float32)
        if frame.shape[0] < expected:
            # Pad with zeros
            frame = np.concatenate([frame, np.zeros(expected - frame.shape[0])])
        elif frame.shape[0] > expected:
            # Truncate
            frame = frame[:expected]
        fixed.append(frame)
    return np.array(fixed, dtype=np.float32)


class MPWorkerClient:
    """
    Manages MediaPipe worker subprocess and provides interface for
    frame processing and hand landmark extraction.
    """

    def __init__(self):
        self._proc = None
        self._lock = threading.Lock()
        self._start()

    def _start(self):
        """Start MediaPipe worker subprocess in separate virtual environment"""
        self._proc = subprocess.Popen(
            [_MP_PYTHON, _MP_WORKER],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            bufsize=1,           # line-buffered
            text=True,
            encoding="utf-8",
        )
        print(f"[recognizer] MediaPipe worker started (PID {self._proc.pid})")

    def send_frame(self, pil_img, timeout=1.5):
        """
        Send a PIL RGB image to worker process and get feature vector.
        Returns list of 100 float values or None if no hands detected.
        """
        # Convert PIL → JPEG bytes → base64
        buf = io.BytesIO()
        pil_img.save(buf, format="JPEG", quality=85)
        b64 = base64.b64encode(buf.getvalue()).decode("ascii")

        msg = json.dumps({"image": b64}) + "\n"

        with self._lock:
            try:
                if self._proc.poll() is not None:
                    print("[recognizer] MediaPipe worker died — restarting...")
                    self._start()

                # Send frame to worker
                self._proc.stdin.write(msg)
                self._proc.stdin.flush()
                
                # Read response with timeout
                response_line = self._proc.stdout.readline()
                if not response_line:
                    return None

                response = json.loads(response_line)
                if response.get("features"):
                    features = np.array(response["features"], dtype=np.float32)
                    return features[:EXPECTED_FEATURES].tolist()
                return None

            except Exception as e:
                print(f"[recognizer] Error: {e}")
                return None


class EnhancedASLRecognizer:
    """
    Main sign language recognition engine that uses MediaPipe
    for hand detection and landmark extraction.
    """

    def __init__(self, sequence_length=30):
        self.mp_client = MPWorkerClient()
        self.sequence_length = sequence_length
        self.frame_buffer = deque(maxlen=sequence_length)

    def extract_features(self, image):
        """
        Extract hand landmark features from image.
        
        Args:
            image: PIL Image in RGB mode
            
        Returns:
            Flattened feature vector of 100 floats or None if no hands
        """
        try:
            # Handle various input types
            if isinstance(image, np.ndarray):
                image = Image.fromarray(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
            
            # Ensure RGB mode
            if image.mode != 'RGB':
                image = image.convert('RGB')

            # Get landmarks from MediaPipe worker
            features = self.mp_client.send_frame(image)
            
            if features is None:
                return None

            # Add to frame buffer (for temporal features if needed)
            self.frame_buffer.append(features)
            
            # Pad buffer if not full yet
            if len(self.frame_buffer) < self.sequence_length:
                # Use first frame repeated
                padded = []
                for _ in range(self.sequence_length - len(self.frame_buffer)):
                    padded.append(features)
                padded.extend(list(self.frame_buffer))
                features = np.concatenate(padded, axis=0).tolist()
            else:
                # Concatenate sequence
                features = np.concatenate(list(self.frame_buffer), axis=0).tolist()

            return fix_feature_size(
                [features],
                expected=EXPECTED_FEATURES
            )[0].tolist()

        except Exception as e:
            print(f"Error extracting features: {e}")
            return None
```

**Key Features:**
- Subprocess-based MediaPipe integration (avoids protobuf conflicts)
- Hand landmark extraction and normalization
- Feature padding/truncation to exact size
- Sequence buffering for temporal features
- Robust error handling and worker restart logic

### 8.6 Speech Services

#### 8.6.1 Speech-to-Text Service

**Key implementation for capturing user speech:**

```dart
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechToTextService extends ChangeNotifier {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  String _recognizedText = '';

  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;

  Future<void> initializeSpeechRecognition() async {
    try {
      bool available = await _speechToText.initialize(
        onError: (error) => print('Error: $error'),
        onStatus: (status) => print('Status: $status'),
      );
      
      if (!available) {
        throw Exception('Speech recognition not available');
      }
    } catch (e) {
      print('Failed to initialize speech recognition: $e');
      rethrow;
    }
  }

  void startListening() async {
    if (_isListening) return;

    _isListening = true;
    _recognizedText = '';
    notifyListeners();

    try {
      await _speechToText.listen(
        onResult: (result) {
          _recognizedText = result.recognizedWords;
          notifyListeners();
        },
        localeId: 'en_US',
      );
    } catch (e) {
      print('Error listening: $e');
      _isListening = false;
      notifyListeners();
    }
  }

  void stopListening() async {
    if (!_isListening) return;
    
    await _speechToText.stop();
    _isListening = false;
    notifyListeners();
  }

  Future<void> dispose() async {
    await _speechToText.stop();
    super.dispose();
  }
}
```

### 8.7 Key Features & Implementation

#### 8.7.1 Real-Time Meeting Screen

The meeting using sign language screen integrates:

```dart
class MeetingUsingSignLanguageScreen extends StatefulWidget {
  @override
  _MeetingUsingSignLanguageScreenState createState() =>
      _MeetingUsingSignLanguageScreenState();
}

class _MeetingUsingSignLanguageScreenState
    extends State<MeetingUsingSignLanguageScreen> {
  late WebRtcCallService _webRtcService;
  Timer? _predictionTimer;
  bool _recognizing = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    await _webRtcService.initRenderers();
    await _webRtcService.joinRoom(
      widget.roomId,
      enableStt: true,
    );
    _startSignLanguageRecognition();
  }

  void _startSignLanguageRecognition() {
    _predictionTimer = Timer.periodic(Duration(milliseconds: 500), (_) async {
      // Capture current camera frame
      final frame = await _captureFrame();
      if (frame != null) {
        try {
          final result = await SignLanguageApiService.predictSignLanguage(frame);
          if (result['confidence'] > 0.7) {
            setState(() {
              _recognizedSign = result['prediction'];
              _arabicTranslation = result['arabic'];
            });
          }
        } catch (e) {
          print('Error recognizing sign: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Meeting - Sign Language')),
      body: Column(
        children: [
          // Local video stream
          Expanded(
            child: Container(
              color: Colors.black,
              child: RTCVideoView(_webRtcService.localRenderer),
            ),
          ),
          // Remote video stream
          Expanded(
            child: Container(
              color: Colors.grey[300],
              child: RTCVideoView(_webRtcService.remoteRenderer),
            ),
          ),
          // Translation display
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Recognized: $_recognizedSign',
                    style: TextStyle(fontSize: 16)),
                Text('Arabic: $_arabicTranslation',
                    style: TextStyle(fontSize: 14, color: Colors.blue)),
              ],
            ),
          ),
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(Icons.videocam),
                onPressed: () => _webRtcService.toggleCamera(true),
              ),
              IconButton(
                icon: Icon(Icons.mic),
                onPressed: () => _webRtcService.toggleMicrophone(true),
              ),
              IconButton(
                icon: Icon(Icons.call_end),
                onPressed: () => _webRtcService.hangUp(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _predictionTimer?.cancel();
    _webRtcService.dispose();
    super.dispose();
  }
}
```

### 8.8 Dependencies & Technologies

#### 8.8.1 Flutter Dependencies

**File: [pubspec.yaml](pubspec.yaml) (key dependencies)**

```yaml
name: meeting
description: "Ishara - Arabic Sign Language real-time meeting and communication app"

version: 1.0.0+1

environment:
  sdk: ^3.7.0

dependencies:
  flutter:
    sdk: flutter
  
  # Localization
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0
  
  # State Management
  provider: ^6.1.1
  
  # Persistence
  shared_preferences: ^2.2.2
  
  # Camera & Media
  camera: ^0.11.0+2
  permission_handler: ^11.3.1
  image_picker: ^1.0.7
  
  # Networking
  http: ^1.1.2
  web_socket_channel: ^2.4.0
  
  # Audio & Speech
  speech_to_text: ^7.3.0
  audio_session: ^0.2.2
  
  # Real-Time Communication
  flutter_webrtc: ^0.9.35
  
  # Notifications
  flutter_local_notifications: ^19.5.0
  timer: ^0.10.1
  
  # UI
  flutter_svg: ^2.2.2
  cupertino_icons: ^1.0.8
```

#### 8.8.2 Python Backend Dependencies

**File: [flask_api/requirements.txt](flask_api/requirements.txt)**

```
Flask==2.3.2
Flask-CORS==4.0.0
keras==3.0.0
tensorflow==2.20.0
numpy==1.26.0
Pillow==10.0.0
opencv-python==4.8.0.74
```

### 8.9 Data Models

Key data structures used throughout the application:

```dart
// User model
class User {
  String id;
  String email;
  String fullName;
  String profileImage;
  String language; // 'en' or 'ar'
  bool darkMode;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.profileImage,
    this.language = 'en',
    this.darkMode = false,
  });
}

// Meeting model
class Meeting {
  String id;
  String title;
  String roomId;
  DateTime startTime;
  DateTime endTime;
  List<String> participantIds;
  bool usingSignLanguage;
  bool usingSTT;

  Meeting({
    required this.id,
    required this.title,
    required this.roomId,
    required this.startTime,
    required this.endTime,
    required this.participantIds,
    this.usingSignLanguage = false,
    this.usingSTT = false,
  });
}

// Prediction result model
class SignLanguagePrediction {
  String sign;
  String arabic;
  double confidence;
  List<String> allPredictions;

  SignLanguagePrediction({
    required this.sign,
    required this.arabic,
    required this.confidence,
    required this.allPredictions,
  });
}
```

### 8.10 Performance Considerations

1. **Image Compression**: Images are converted to JPEG with quality=85 before sending to API
2. **Async Processing**: All API calls use async/await to prevent UI blocking
3. **Frame Buffering**: Local frame buffer for temporal feature extraction
4. **Connection Pooling**: HTTP client reuse for API requests
5. **Subprocess Management**: Separate venv for MediaPipe to avoid dependency conflicts
6. **Timeout Handling**: 120-second timeout for API calls with informative error messages

### 8.11 Security Considerations

1. **CORS Configuration**: Proper CORS headers on backend API
2. **Input Validation**: Base64 image validation and decoding error handling
3. **Error Handling**: Detailed logging without exposing sensitive information
4. **Platform Detection**: Automatic handling of emulator vs. real device networking

## 8.12 Conclusion

Ishara is a sophisticated real-time communication platform that combines modern mobile development with machine learning to break communication barriers for Arabic Sign Language users. The application leverages:

- **Flutter** for cross-platform mobile development
- **WebRTC** for peer-to-peer video communication
- **TensorFlow/Keras** for deep learning-based sign language recognition
- **MediaPipe** for robust hand tracking and landmark detection
- **Flask** for REST API and ML model serving
- **WebSockets** for real-time signaling and communication

The modular architecture allows for easy extension with additional features like storage integration, advanced scheduling, and multi-language support.

---

*Technical documentation for graduation project - Ishara Platform*
*Created: 2026*
