import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:meeting/utils/app_routes.dart';
import 'package:meeting/utils/app_config.dart';
import 'package:meeting/services/webrtc_call_service.dart';
import 'package:meeting/localization/app_localizations.dart';
import 'package:meeting/services/speech_to_text_service.dart';
import 'package:provider/provider.dart';
import 'package:meeting/utils/locale_provider.dart';

/// Meeting screen using audio (speech-to-text) with WebRTC support
class MeetingUsingAudioScreen extends StatefulWidget {
  const MeetingUsingAudioScreen({super.key});

  @override
  State<MeetingUsingAudioScreen> createState() => _MeetingUsingAudioScreenState();
}

class _MeetingUsingAudioScreenState extends State<MeetingUsingAudioScreen> with TickerProviderStateMixin {
  final _webRtcCallService = WebRtcCallService(signalingUrl: AppConfig.signalingUrl);
  final _speechToTextService = SpeechToTextService();

  bool _isCameraOn = true;
  MediaStream? _localStream;
  bool _isRendererInitialized = false;
  bool _isMuted = false;
  String? _roomId;

  // Animation Controllers for UI Entry
  late AnimationController _entryController;
  late Animation<double> _controlBarSlide;
  late Animation<double> _panelSlide;
  late Animation<double> _pipScale;
  late AnimationController _pulseController;
  late AnimationController _bgController;

  /// Merged partner text: prefers speech captions (Normal partner)
  /// and falls back to sign language text (Deaf partner).
  final ValueNotifier<String> _partnerText = ValueNotifier<String>('');

  // Scroll controllers for independent caption sections
  final ScrollController _partnerScrollController = ScrollController();
  final ScrollController _youScrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args.containsKey('roomId')) {
      setState(() {
        _roomId = args['roomId'] as String;
      });
      debugPrint('Audio Room ID received: $_roomId');
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
      CurvedAnimation(parent: _entryController, curve: const Interval(0.5, 1.0, curve: Curves.easeOutBack)),
    );

    _panelSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic)),
    );

    _pipScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.7, 1.0, curve: Curves.elasticOut)),
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
    
    // Keep _partnerText in sync with whichever partner type is active
    _webRtcCallService.partnerCaptions.addListener(_updatePartnerText);
    _webRtcCallService.remoteTranslatedText.addListener(_updatePartnerText);

    // Auto-scroll each section to the bottom when text updates
    _partnerText.addListener(_scrollPartnerToBottom);
    _webRtcCallService.myOwnCaptions.addListener(_scrollYouToBottom);
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
    final speech = _webRtcCallService.partnerCaptions.value;    // Normal partner
    final signs  = _webRtcCallService.remoteTranslatedText.value; // Deaf partner
    // Speech captions take priority; fall back to sign text
    _partnerText.value = speech.isNotEmpty ? speech : signs;
  }

  Future<void> _initialize() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      if (statuses[Permission.camera]!.isGranted && statuses[Permission.microphone]!.isGranted) {
        await _webRtcCallService.initRenderers();
        await _initCamera();
        
        if (_roomId != null) {
          // Enable Server-Side STT Bot
          await _webRtcCallService.joinRoom(_roomId!, enableStt: true);
        }
      }
    } catch (e) {
      debugPrint('Initialization failed: $e');
    }
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

      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

      if (_localStream != null) {
        _webRtcCallService.localRenderer.srcObject = _localStream;
        _webRtcCallService.setLocalStream(_localStream!);

        if (mounted) {
          setState(() {
            _isRendererInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _webRtcCallService.partnerCaptions.removeListener(_updatePartnerText);
    _webRtcCallService.remoteTranslatedText.removeListener(_updatePartnerText);
    _partnerText.removeListener(_scrollPartnerToBottom);
    _webRtcCallService.myOwnCaptions.removeListener(_scrollYouToBottom);
    _partnerText.dispose();
    _partnerScrollController.dispose();
    _youScrollController.dispose();
    _localStream?.dispose();
    _webRtcCallService.dispose();
    _speechToTextService.stopListening();
    _entryController.dispose();
    _pulseController.dispose();
    _bgController.dispose();
    super.dispose();
  }
  
  void _toggleCamera() {
    if (_localStream != null) {
       final videoTracks = _localStream!.getVideoTracks();
       if (videoTracks.isNotEmpty) {
          final enabled = !videoTracks.first.enabled;
          videoTracks.first.enabled = enabled;
          setState(() => _isCameraOn = enabled);
          _webRtcCallService.camEnabled.value = enabled;

          if (enabled) {
            _webRtcCallService.localRenderer.srcObject = _localStream;
          }
       }
    }
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _webRtcCallService.toggleMic();
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
              const Icon(Icons.audio_file_outlined, size: 14, color: Color(0xFF0D2652)),
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
                      letterSpacing: 1.2
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
          Positioned.fill(
            child: _buildRemoteVideoFull(),
          ),

          // 2. Captions Panel (Bottom)
          Positioned(
            bottom: 140,
            left: 20,
            right: 20,
            child: _buildCaptionPanel(),
          ),

          // 3. Local Video (PIP)
          Positioned(
            top: 20,
            right: 20,
            child: _buildLocalVideoPIP(),
          ),

          // 4. Control Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildControlBar(),
          ),
        ],
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
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.blueAccent),
                ],
              ),
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
                  child: Icon(Icons.videocam_off, color: Color(0xFF94A3B8), size: 80),
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
    return ScaleTransition(
      scale: _pipScale,
      child: Container(
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFF0D2652),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2), 
            width: 2
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
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
              const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  localizations?.translate('youLabel') ?? 'You', 
                  style: const TextStyle(color: Colors.white, fontSize: 10)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptionPanel() {
    final localizations = AppLocalizations.of(context);
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(_panelSlide),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF0D2652).withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCaptionRow(
              label: localizations?.translate('partnerLabel') ?? 'Partner',
              color: Colors.cyanAccent.shade700,
              stream: _partnerText,
              localizations: localizations,
              scrollController: _partnerScrollController,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Color(0xFFE2E8F0), height: 1),
            ),
            _buildCaptionRow(
              label: localizations?.translate('youLabel') ?? 'You',
              color: Colors.blueAccent,
              stream: _webRtcCallService.myOwnCaptions,
              localizations: localizations,
              isListening: true,
              scrollController: _youScrollController,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptionRow({
    required String label,
    required Color color,
    required ValueNotifier<String> stream,
    required AppLocalizations? localizations,
    bool isListening = false,
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
              style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 80),
            child: ValueListenableBuilder<String>(
              valueListenable: stream,
              builder: (context, text, _) {
                String displayText = text;
                if (text.isEmpty) {
                  displayText = isListening
                    ? (localizations?.translate('listening') ?? '🎤 Listening...')
                    : '';
                }
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Text(
                    displayText,
                    style: const TextStyle(
                      color: Color(0xFF0D2652),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlBar() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(_controlBarSlide),
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
          color: color ?? (isActive ? Colors.white.withOpacity(0.2) : Colors.transparent),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
