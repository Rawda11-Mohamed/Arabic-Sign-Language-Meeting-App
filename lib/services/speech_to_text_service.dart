import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:developer' as developer;
import 'package:audio_session/audio_session.dart';

/// Real-time Speech-to-Text service
/// Supports Arabic and English speech recognition
class SpeechToTextService {
  bool _isListening = false;
  final ValueNotifier<String> _recognizedText = ValueNotifier<String>('');
  final ValueNotifier<String?> _errorMessage = ValueNotifier<String?>(null);
  final ValueNotifier<bool> _isAvailable = ValueNotifier<bool>(false);
  final ValueNotifier<String> _status = ValueNotifier<String>('idle');
  final ValueNotifier<String> _activeLocaleId = ValueNotifier<String>('en_US');
  final ValueNotifier<bool> _hasPermission = ValueNotifier<bool>(false);

  final stt.SpeechToText _speech = stt.SpeechToText();
  String _currentLocaleId = 'en_US'; 
  bool _shouldBeListening = false;
  Timer? _monitorTimer;

  ValueNotifier<String> get recognizedText => _recognizedText;
  ValueNotifier<String?> get errorMessage => _errorMessage;
  ValueNotifier<bool> get isAvailable => _isAvailable;
  ValueNotifier<String> get status => _status;
  ValueNotifier<String> get activeLocaleId => _activeLocaleId;
  ValueNotifier<bool> get hasPermission => _hasPermission;

  /// Initialize speech recognition
  Future<bool> initialize() async {
    try {
      developer.log('STT: Starting initialization...');
      
      final micPermission = await Permission.microphone.request();
      _hasPermission.value = micPermission.isGranted;
      developer.log('STT: Microphone permission: ${micPermission.isGranted}');
      
      if (!micPermission.isGranted) {
        _status.value = 'permissionDenied';
        _errorMessage.value = 'Microphone permission denied.';
        _isAvailable.value = false;
        developer.log('STT: Permission denied, cannot initialize');
        return false;
      }

      developer.log('STT: Calling _speech.initialize()...');
      final available = await _speech.initialize(
        debugLogging: true, // Crucial for debugging Samsung mic conflicts
        onError: (error) async {
          developer.log('STT Error [${error.permanent ? "Perm" : "Trans"}]: ${error.errorMsg}');
          if (error.errorMsg.contains('error_busy') || error.errorMsg.contains('error_audio')) {
             developer.log('Mic Busy: Attempting Session Reset');
             await _resetAudioSession();
          }
          _errorMessage.value = 'Speech recognition error: ${error.errorMsg}';
          _isListening = false;
          _status.value = 'error';
          if (_shouldBeListening) _handleAutoRestart();
        },
        onStatus: (status) {
          developer.log('STT Status Change: $status');
          _status.value = status;
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            if (_shouldBeListening) {
               developer.log('STT finished while it should be listening - triggering restart');
               _handleAutoRestart();
            }
          } else if (status == 'listening') {
            _isListening = true;
          }
        },
      );

      developer.log('STT: Initialize returned: $available');
      _isAvailable.value = available;
      
      if (!available) {
        _status.value = 'notAvailable';
        _errorMessage.value = 'Speech recognition not available on this device.';
        developer.log('STT: Speech recognition NOT available on device');
        return false;
      }

      developer.log('STT: Fetching available locales...');
      final availableLocales = await _speech.locales();
      developer.log('STT: Found ${availableLocales.length} locales');
      
      final localeExists = availableLocales.any((locale) => locale.localeId == _currentLocaleId);
      if (!localeExists && availableLocales.isNotEmpty) {
        developer.log('STT: Locale $_currentLocaleId not found, using ${availableLocales.first.localeId}');
        _currentLocaleId = availableLocales.first.localeId;
      }
      _activeLocaleId.value = _currentLocaleId;
      developer.log('STT: Active locale set to: $_currentLocaleId');

      developer.log('STT: Initialization successful!');
      return true;
    } catch (e) {
      developer.log('STT: Initialization exception: $e');
      _errorMessage.value = 'Failed to initialize: $e';
      _isAvailable.value = false;
      return false;
    }
  }

  Future<void> setLanguage(String localeId) async {
    _currentLocaleId = localeId;
    _activeLocaleId.value = _currentLocaleId;
  }

  Future<List<stt.LocaleName>> getAvailableLanguages() async {
    return await _speech.locales();
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com')).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> startListening({bool force = false}) async {
    _shouldBeListening = true;
    if (force) {
      developer.log('STT Force Restart: Stopping current session');
      await _speech.stop();
      _isListening = false;
    }
    _startMonitor();
    await _performListen();
  }

  /// Specialized recovery for when WebRTC takes the mic
  Future<void> recoverMic() async {
    developer.log('STT: Recovering Mic from hardware conflict...');
    _shouldBeListening = true;
    await _speech.cancel(); // Complete reset
    _isListening = false;
    await Future.delayed(const Duration(milliseconds: 500));
    final ok = await initialize(); // Re-init hardware
    if (ok) {
      await _performListen();
    }
  }

  void _startMonitor() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_shouldBeListening && !_isListening && !_speech.isListening) {
        _handleAutoRestart();
      }
    });
  }

  void _handleAutoRestart() {
    if (!_shouldBeListening) return;
    Future.delayed(const Duration(milliseconds: 1000), () async {
      if (_shouldBeListening && !_isListening) {
        developer.log('Executing STT auto-restart...');
        await _performListen();
      }
    });
  }

  Future<void> _performListen() async {
    if (!_isAvailable.value) return;
    if (_isListening) return;

    try {
      await _resetAudioSession();
      _errorMessage.value = null;
      _status.value = 'starting';

      await _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            _recognizedText.value = result.recognizedWords;
          }
        },
        localeId: _currentLocaleId,
        pauseFor: const Duration(seconds: 3),
        listenFor: const Duration(minutes: 5),
        listenOptions: stt.SpeechListenOptions(
          cancelOnError: false,
          partialResults: true,
        ),
      );
      _isListening = true;
      _status.value = 'listening';
    } catch (e) {
      _isListening = false;
      _errorMessage.value = 'Failed to start listening: $e';
    }
  }

  Future<void> stopListening() async {
    _shouldBeListening = false;
    _monitorTimer?.cancel();
    await _speech.stop();
    _isListening = false;
    _status.value = 'stopped';
  }

  Future<void> cancel() async {
    _shouldBeListening = false;
    await _speech.cancel();
    _isListening = false;
    _recognizedText.value = '';
    _status.value = 'canceled';
  }

  void clearText() {
    _recognizedText.value = '';
  }

  bool get isListening => _isListening;

  Future<void> _resetAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth | 
                                      AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      ));
      await session.setActive(true);
      developer.log('AudioSession Unified for STT/WebRTC');
    } catch (e) {
      developer.log('Failed to configure AudioSession: $e');
    }
  }

  void dispose() {
    _shouldBeListening = false;
    _monitorTimer?.cancel();
    _speech.cancel();
  }
}
