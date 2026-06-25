import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:meeting/services/webrtc_call_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// In-call screen for 1-on-1 WebRTC video calls.
class CallScreen extends StatefulWidget {
  final WebRtcCallService callService;
  final String roomId;

  const CallScreen({
    super.key,
    required this.callService,
    required this.roomId,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _startCall();
  }

  @override
  void dispose() {
    // Ensure hangUp when leaving the screen
    widget.callService.hangUp();
    _localStream?.dispose();
    super.dispose();
  }

  MediaStream? _localStream;

  Future<void> _startCall() async {
    setState(() => _isJoining = true);

    try {
      // 1. Request permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      if (!statuses[Permission.camera]!.isGranted || !statuses[Permission.microphone]!.isGranted) {
        throw Exception('Camera and Microphone permissions are required.');
      }

      // 2. Initialize Renderers
      await widget.callService.initRenderers();

      // 3. Get User Media
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 640},
          'height': {'ideal': 480},
        },
      };

      try {
        _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      } catch (e) {
        debugPrint('Standard media constraints failed, retrying defaults: $e');
        _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': true});
      }

      // 4. Set stream in service
      if (_localStream != null) {
        widget.callService.setLocalStream(_localStream!);
      } else {
         throw Exception('Failed to get camera stream');
      }

      // 5. Join Room
      await widget.callService.joinRoom(widget.roomId);
      
    } catch (e) {
      final msg = e.toString();
      widget.callService.errorMessage.value = 'Failed to join: $msg';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to join: $msg')));
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  Widget _diagChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: Colors.blueGrey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final callService = widget.callService;

    return WillPopScope(
      onWillPop: () async {
        await callService.hangUp();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text('Room: ${widget.roomId}'),
          backgroundColor: Colors.black,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Joining indicator
              if (_isJoining)
                LinearProgressIndicator(color: Colors.blueAccent),

              // Error banner (signaling / media errors)
              ValueListenableBuilder<String?>(
                valueListenable: callService.errorMessage,
                builder: (context, error, _) {
                  if (error == null) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    color: Colors.redAccent.withOpacity(0.9),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            error,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            // Try to reacquire media
                            await callService.retryGetUserMedia();
                          },
                          child: const Text('Retry', style: TextStyle(color: Colors.white)),
                        ),
                        TextButton(
                          onPressed: () async {
                            // Open OS settings to grant permissions
                            await openAppSettings();
                          },
                          child: const Text('Open Settings', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Diagnostics panel showing internal WebRTC state for debugging
              Container(
                width: double.infinity,
                color: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ValueListenableBuilder<String>(
                        valueListenable: callService.pcState,
                        builder: (_, v, __) => _diagChip('PC', v),
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<String>(
                        valueListenable: callService.iceConnectionState,
                        builder: (_, v, __) => _diagChip('ICE', v),
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<String>(
                        valueListenable: callService.signalingState,
                        builder: (_, v, __) => _diagChip('SIG', v),
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<int>(
                        valueListenable: callService.localIceCount,
                        builder: (_, v, __) => _diagChip('LocalICE', v.toString()),
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<int>(
                        valueListenable: callService.remoteIceCount,
                        builder: (_, v, __) => _diagChip('RemoteICE', v.toString()),
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<int>(
                        valueListenable: callService.sdpOfferLength,
                        builder: (_, v, __) => _diagChip('Offer', v.toString()),
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<int>(
                        valueListenable: callService.sdpAnswerLength,
                        builder: (_, v, __) => _diagChip('Answer', v.toString()),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: RTCVideoView(
                          callService.localRenderer,
                          mirror: true,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: RTCVideoView(
                          callService.remoteRenderer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: callService.micEnabled,
                      builder: (_, enabled, __) {
                        return CircleAvatar(
                          backgroundColor: Colors.grey[800],
                          radius: 28,
                          child: IconButton(
                            icon: Icon(
                              enabled ? Icons.mic : Icons.mic_off,
                              color: Colors.white,
                            ),
                            onPressed: callService.toggleMic,
                          ),
                        );
                      },
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: callService.camEnabled,
                      builder: (_, enabled, __) {
                        return CircleAvatar(
                          backgroundColor: Colors.grey[800],
                          radius: 28,
                          child: IconButton(
                            icon: Icon(
                              enabled ? Icons.videocam : Icons.videocam_off,
                              color: Colors.white,
                            ),
                            onPressed: () async {
                              // If no local stream, try to reacquire media first
                              if (callService.localRenderer.srcObject == null) {
                                await callService.retryGetUserMedia();
                              }
                              callService.toggleCamera();
                            },
                          ),
                        );
                      },
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.red,
                      radius: 28,
                      child: IconButton(
                        icon: const Icon(Icons.call_end, color: Colors.white),
                        onPressed: () async {
                          await callService.hangUp();
                          if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
