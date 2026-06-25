import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:meeting/utils/app_routes.dart';
import 'package:meeting/utils/app_config.dart';
import 'package:meeting/services/sign_language_service.dart';
import 'package:meeting/services/webrtc_call_service.dart';
import 'package:meeting/localization/app_localizations.dart';
import 'package:meeting/services/speech_to_text_service.dart';
import 'package:provider/provider.dart';
import 'package:meeting/utils/locale_provider.dart';
import 'package:meeting/models/quick_phrase.dart';
import 'package:meeting/services/quick_phrase_service.dart';
import 'package:meeting/widgets/quick_phrase_sheet.dart';
import 'package:meeting/widgets/quick_phrase_overlay.dart';

/// Meeting screen using sign language recognition
class MeetingUsingSignLanguageScreen extends StatefulWidget {
  const MeetingUsingSignLanguageScreen({super.key});

  @override
  State<MeetingUsingSignLanguageScreen> createState() =>
      _MeetingUsingSignLanguageScreenState();
}

class _MeetingUsingSignLanguageScreenState
    extends State<MeetingUsingSignLanguageScreen>
    with TickerProviderStateMixin {
  final _signLanguageService = SignLanguageService();
  final _webRtcCallService = WebRtcCallService(
    signalingUrl: AppConfig.signalingUrl,
  );
  final _speechToTextService = SpeechToTextService();

  bool _isCameraOn = true;
  MediaStream? _localStream;
  bool _isRendererInitialized = false;
  bool _isMuted = false;
  String? _roomId;
  String? _overlayPhrase;
  final QuickPhraseService _phraseService = QuickPhraseService();

  // Animation Controllers for UI Entry
  late AnimationController _entryController;
  late Animation<double> _controlBarSlide;
  late Animation<double> _panelSlide;
  late Animation<double> _pipScale;
  late AnimationController _pulseController;
  late AnimationController _bgController;

  // Scroll controllers for independent caption sections
  final ScrollController _partnerScrollController = ScrollController();
  final ScrollController _youScrollController = ScrollController();

  // Merged partner text: prefers remoteCaptions (STT from hearing partner)
  // and falls back to remoteTranslatedText (signs from a signing partner).
  final ValueNotifier<String> _partnerText = ValueNotifier<String>('');
  Timer? _partnerClearTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args.containsKey('roomId')) {
      setState(() {
        _roomId = args['roomId'] as String;
      });
      debugPrint('Room ID received: $_roomId');
    }
  }

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _controlBarSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _panelSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _pipScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.7, 1.0, curve: Curves.elasticOut),
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _initialize();
    _entryController.forward();

    // Keep _partnerText in sync: STT captions take priority over sign text
    _webRtcCallService.partnerCaptions.addListener(_updatePartnerText);
    _webRtcCallService.remoteTranslatedText.addListener(_updatePartnerText);

    // Auto-scroll each section to the bottom when text updates
    _partnerText.addListener(_scrollPartnerToBottom);
    _signLanguageService.translatedText.addListener(_scrollYouToBottom);
  }

  void _scrollPartnerToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_partnerScrollController.hasClients) {
        _partnerScrollController.animateTo(
          _partnerScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollYouToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_youScrollController.hasClients) {
        _youScrollController.animateTo(
          _youScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _updatePartnerText() {
    final captions =
        _webRtcCallService.partnerCaptions.value; // filtered partner speech
    final signText = _webRtcCallService.remoteTranslatedText.value;
    // Speech captions take priority; fall back to sign language text
    final text = captions.isNotEmpty ? captions : signText;
    
    _partnerText.value = text;
    
    _partnerClearTimer?.cancel();
    if (text.isNotEmpty) {
      _partnerClearTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          _partnerText.value = '';
          _webRtcCallService.partnerCaptions.value = '';
          _webRtcCallService.remoteTranslatedText.value = '';
        }
      });
    }
  }

  @override
  void dispose() {
    _partnerClearTimer?.cancel();
    _webRtcCallService.partnerCaptions.removeListener(_updatePartnerText);
    _webRtcCallService.remoteTranslatedText.removeListener(_updatePartnerText);
    _partnerText.removeListener(_scrollPartnerToBottom);
    _signLanguageService.translatedText.removeListener(_scrollYouToBottom);
    _partnerText.dispose();
    _partnerScrollController.dispose();
    _youScrollController.dispose();
    _signLanguageService.stopRecognition();
    _localStream?.dispose();
    _webRtcCallService.dispose();
    _speechToTextService.dispose();
    _entryController.dispose();
    _pulseController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      _signLanguageService.debugInfo.value = 'Requesting permissions...';

      final cameraStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();

      if (cameraStatus.isGranted && micStatus.isGranted) {
        _signLanguageService.debugInfo.value =
            'Permissions granted. Initializing renderers...';
        await _webRtcCallService.initRenderers();

        _signLanguageService.debugInfo.value = 'Initialising camera...';
        await _initCamera();

        if (_roomId != null) {
          _signLanguageService.debugInfo.value = 'Joining meeting...';
          debugPrint('Joining room: $_roomId');
          // STT bot is NOT enabled here — sign language users communicate via
          // sign recognition, not audio. Audio STT is only for the audio screen.
          await _webRtcCallService.joinRoom(_roomId!, enableStt: false);
        } else {
          _signLanguageService.debugInfo.value = 'Error: Room ID missing';
          debugPrint('Warning: roomId is null in _initialize');
        }
      } else {
        String errorMsg = 'Permissions denied.';
        if (cameraStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied) {
          errorMsg =
              'Permissions permanently denied. Please enable in settings.';
          if (mounted) {
            _showPermissionDialog();
          }
        }
        _signLanguageService.debugInfo.value = 'Error: Permissions denied';
        _signLanguageService.errorMessage.value = errorMsg;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: openAppSettings,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Initialization failed: $e');
      _signLanguageService.debugInfo.value =
          'Error: ${e.toString().split('\n').first}';
      _signLanguageService.errorMessage.value = e.toString();
    }
  }

  void _showPermissionDialog() {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              localizations?.translate('permissionsRequired') ??
                  'Permissions Required',
            ),
            content: Text(
              localizations?.translate('permissionsRequiredMsg') ??
                  'Camera and Microphone permissions are required for this meeting. Please enable them in settings to continue.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations?.translate('cancel') ?? 'Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: Text(
                  localizations?.translate('openSettings') ?? 'Open Settings',
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _initCamera() async {
    try {
      final Map<String, dynamic> mediaConstraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 640},
          'height': {'ideal': 480},
        },
      };

      _localStream = await navigator.mediaDevices.getUserMedia(
        mediaConstraints,
      );

      if (_localStream != null) {
        _webRtcCallService.localRenderer.srcObject = _localStream;
        _webRtcCallService.setLocalStream(_localStream!);

        if (mounted) {
          setState(() {
            _isRendererInitialized = true;
          });
        }

        // Robust recognition trigger
        _signLanguageService.debugInfo.value = 'Starting recognition loop...';
        void tryStartRecognition() {
          if (mounted && _isCameraOn && _localStream != null) {
            debugPrint('DEBUG: Attempting to start recognition sequence...');
            _signLanguageService.startAutoSequenceFromWebRTC(_localStream!);
          } else if (mounted) {
            debugPrint('DEBUG: Camera not ready yet, retrying in 1s...');
            Future.delayed(const Duration(seconds: 1), tryStartRecognition);
          }
        }

        Future.delayed(const Duration(seconds: 3), tryStartRecognition);

        _signLanguageService.translatedText.addListener(() {
          final text = _signLanguageService.translatedText.value;
          debugPrint(
            'DEBUG: Local sign updated: "$text", sending to partner...',
          );
          _webRtcCallService.sendTextUpdate(text);
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _toggleCamera() {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        final enabled = !videoTracks.first.enabled;
        videoTracks.first.enabled = enabled;
        setState(() => _isCameraOn = enabled);
        _webRtcCallService.camEnabled.value = enabled;

        // Force-refresh the renderer when re-enabling the camera.
        // RTCVideoRenderer shows a black screen after track.enabled = true
        // unless srcObject is reassigned.
        if (enabled) {
          _webRtcCallService.localRenderer.srcObject = _localStream;
        }
      }
    }
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _webRtcCallService.toggleMic();
    // Speech recognition is not used in the sign language screen.
    // Do NOT start or stop _speechToTextService here.
  }

  void _endCall() {
    _webRtcCallService.hangUp();
    Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: const Color(0xFF0D2652)),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF0D2652).withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.meeting_room_outlined,
                size: 14,
                color: Color(0xFF0D2652),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'ID: ${_roomId ?? ''}',
                    style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // 1. Remote Video (Full Screen)
          Positioned.fill(child: _buildRemoteVideoFull()),

          // 2. Translation & Captions Panel (Bottom)
          Positioned(
            bottom: 140,
            left: 20,
            right: 20,
            child: _buildTranslationPanel(),
          ),

          // 3. Local Video (PIP)
          Positioned(top: 20, right: 20, child: _buildLocalVideoPIP()),

          // 4. Control Bar
          Positioned(bottom: 0, left: 0, right: 0, child: _buildControlBar()),

          // 5. Quick Phrase Overlay
          if (_overlayPhrase != null)
            QuickPhraseOverlay(
              text: _overlayPhrase!,
              onDismiss: () => setState(() => _overlayPhrase = null),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Stack(
          children: [
            Container(color: const Color(0xFFF8FAFC)),

            // Pulsing Background Circles
            _buildBlurCircle(
              color: Color(0xFF3B82F6).withOpacity(0.15),
              offset: Offset(
                MediaQuery.of(context).size.width * (0.2 + 0.1 * (1 + (1 / 2))),
                MediaQuery.of(context).size.height * 0.3,
              ),
              size: 500,
            ),
            _buildBlurCircle(
              color: Color(0xFF8B5CF6).withOpacity(0.1),
              offset: Offset(
                MediaQuery.of(context).size.width * (0.8 - 0.1 * (1 + (1 / 2))),
                MediaQuery.of(context).size.height * 0.6,
              ),
              size: 600,
            ),

            // Frost Overlay
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlurCircle({
    required Color color,
    required Offset offset,
    required double size,
  }) {
    return Positioned(
      left: offset.dx - size / 2,
      top: offset.dy - size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
        ),
      ),
    );
  }

  Widget _buildRemoteVideoFull() {
    return ValueListenableBuilder<bool>(
      valueListenable: _webRtcCallService.partnerPresent,
      builder: (context, present, child) {
        if (!present) {
          return Container(
            color: Color(0xFFD4E3FF).withOpacity(0.4),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            ),
          );
        }

        return ValueListenableBuilder<bool>(
          valueListenable: _webRtcCallService.hasRemoteVideo,
          builder: (context, hasVideo, _) {
            if (hasVideo) {
              return RTCVideoView(
                _webRtcCallService.remoteRenderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              );
            } else {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.videocam_off,
                    color: Color(0xFF94A3B8),
                    size: 80,
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildLocalVideoPIP() {
    final localizations = AppLocalizations.of(context);
    return Container(
      width: 120,
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFF0D2652),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (_isRendererInitialized)
            RTCVideoView(
              _webRtcCallService.localRenderer,
              mirror: true,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
          else
            const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),

          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                localizations?.translate('youLabel') ?? 'You',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationPanel() {
    final localizations = AppLocalizations.of(context);
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(_panelSlide),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF0D2652).withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mode Toggle Switch
            _buildModeToggle(),
            const SizedBox(height: 10),
            _buildSuggestionBanner(),
            const SizedBox(height: 10),
            _buildTranslationRow(
              label: localizations?.translate('partnerLabel') ?? 'Partner',
              color: Colors.cyanAccent,
              stream: _partnerText,
              localizations: localizations,
              scrollController: _partnerScrollController,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Color(0xFFE2E8F0), height: 1),
            ),
            _buildTranslationRow(
              label: localizations?.translate('youLabel') ?? 'You',
              color: Colors.blueAccent,
              stream: _signLanguageService.translatedText,
              showDoneButton: true,
              localizations: localizations,
              scrollController: _youScrollController,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    final localizations = AppLocalizations.of(context);
    return ValueListenableBuilder<String>(
      valueListenable: _signLanguageService.recognitionMode,
      builder: (context, mode, _) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF0D2652).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModeOption(
                'words',
                localizations?.translate('wordsLabel') ?? 'Words',
                mode == 'words',
              ),
              _buildModeOption(
                'letters',
                localizations?.translate('lettersLabel') ?? 'Letters',
                mode == 'letters',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeOption(String mode, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        _signLanguageService.setMode(mode);
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ]
                  : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                isSelected
                    ? const Color(0xFF0D2652)
                    : const Color(0xFF0D2652).withOpacity(0.5),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionBanner() {
    final localizations = AppLocalizations.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: _signLanguageService.suggestLettersMode,
      builder: (context, suggest, _) {
        if (!suggest) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () {
            _signLanguageService.setMode('letters');
            HapticFeedback.mediumImpact();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lightbulb_outline, size: 14, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  localizations?.translate('tryLettersMode') ??
                      'Struggling? Try Letters Mode',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTranslationRow({
    required String label,
    required Color color,
    required ValueNotifier<String> stream,
    required AppLocalizations? localizations,
    bool showDoneButton = false,
    ScrollController? scrollController,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 90),
            child: ValueListenableBuilder<String>(
              valueListenable: stream,
              builder: (context, text, _) {
                final displayText = text.isEmpty
                    ? (localizations?.translate('silentMode') ?? 'Silent Mode...')
                    : text;
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Text(
                    displayText,
                    style: const TextStyle(
                      color: Color(0xFF0D2652),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                );
              },
            ),
          ),
        ),
        if (showDoneButton)
          ValueListenableBuilder<String>(
            valueListenable: _signLanguageService.recognitionMode,
            builder: (context, mode, _) {
              if (mode != 'letters') return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(left: 12),
                child: InkWell(
                  onTap: () {
                    _signLanguageService.finalizeManually();
                    HapticFeedback.heavyImpact();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'تم',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildControlBar() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_controlBarSlide),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D2652),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  onTap: _toggleMute,
                  isActive: !_isMuted,
                ),
                _buildActionButton(
                  icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
                  onTap: _toggleCamera,
                  isActive: _isCameraOn,
                ),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  onTap: _showQuickPhrases,
                  isActive: true,
                ),
                _buildActionButton(
                  icon: Icons.call_end,
                  onTap: _endCall,
                  color: Colors.red,
                  isActive: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              color ??
              (isActive ? Colors.white.withOpacity(0.2) : Colors.transparent),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  void _showQuickPhrases() {
    debugPrint('DEBUG: Opening Quick Phrases Sheet...');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => QuickPhraseSheet(
            onPhraseSelected: (phrase) {
              Navigator.pop(context);
              _onPhraseSelected(phrase);
            },
          ),
    );
  }

  void _onPhraseSelected(QuickPhrase phrase) {
    setState(() {
      _overlayPhrase = phrase.text;
    });

    // Send to partner via signaling
    _webRtcCallService.sendTextUpdate("📢 ${phrase.text}");
  }

  Future<void> _showFavoritesPopup() async {
    final favorites = await _phraseService.getFavorites();
    if (favorites.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'لا توجد جمل مفضلة حالياً',
              textAlign: TextAlign.right,
            ),
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<QuickPhrase>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items:
          favorites
              .map(
                (p) => PopupMenuItem<QuickPhrase>(
                  value: p,
                  child: Text(
                    p.preview,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              )
              .toList(),
    );

    if (selected != null) {
      _onPhraseSelected(selected);
    }
  }
}
