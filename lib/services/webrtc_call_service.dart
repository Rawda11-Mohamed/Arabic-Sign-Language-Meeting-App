import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:meeting/utils/app_config.dart';

/// Simple 1-on-1 WebRTC call service using a WebSocket signaling server.
class WebRtcCallService {
  final ValueNotifier<bool> inCall = ValueNotifier<bool>(false);
  final ValueNotifier<bool> partnerPresent = ValueNotifier<bool>(false);
  final ValueNotifier<bool> micEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> camEnabled = ValueNotifier<bool>(true);

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);
  final ValueNotifier<String> remoteTranslatedText = ValueNotifier<String>('');
  final ValueNotifier<String> remoteCaptions = ValueNotifier<String>('');
  /// Partner's speech only (filtered — excludes our own transcription).
  final ValueNotifier<String> partnerCaptions = ValueNotifier<String>('');
  /// The local user's own speech as transcribed by the STT bot.
  final ValueNotifier<String> myOwnCaptions = ValueNotifier<String>('');
  final ValueNotifier<bool> hasRemoteVideo = ValueNotifier<bool>(false);

  // Diagnostics notifiers for UI
  final ValueNotifier<String> pcState = ValueNotifier<String>('new');
  final ValueNotifier<String> iceConnectionState = ValueNotifier<String>('new');
  final ValueNotifier<String> signalingState = ValueNotifier<String>('new');
  final ValueNotifier<int> localIceCount = ValueNotifier<int>(0);
  final ValueNotifier<int> remoteIceCount = ValueNotifier<int>(0);
  final ValueNotifier<int> sdpOfferLength = ValueNotifier<int>(0);
  final ValueNotifier<int> sdpAnswerLength = ValueNotifier<int>(0);

  WebSocketChannel? _ws;
  RTCPeerConnection? _pc;

  // Dedicated STT bot connection
  RTCPeerConnection? _sttPc;

  MediaStream? _localStream;
  bool _isOfferer = false;
  bool _sttEnabled = false;
  String? _roomId;
  String? _myClientId; // Our own WebSocket client ID (set on 'joined')
  final String signalingUrl;
  Completer<void>? _joinCompleter;

  WebRtcCallService({required this.signalingUrl});

  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  Future<void> dispose() async {
    await hangUp();
    await localRenderer.dispose();
    await remoteRenderer.dispose();
  }

  Future<void> joinRoom(String roomId, {bool enableStt = false}) async {
    _roomId = roomId;
    _sttEnabled = enableStt;
    _joinCompleter = Completer<void>();

    try {
      _ws = WebSocketChannel.connect(Uri.parse(signalingUrl));
    } catch (e) {
      _error('Failed to connect to signaling server: $e');
      _joinCompleter = null;
      rethrow;
    }

    _ws!.stream.listen(
      _onSignalMessage,
      onDone: () {
        _onSignalClosed();
        if (_joinCompleter != null && !_joinCompleter!.isCompleted) {
          _joinCompleter!.completeError(
            Exception('Signaling connection closed'),
          );
        }
      },
      onError: (e) {
        _error('WebSocket error: $e');
        if (_joinCompleter != null && !_joinCompleter!.isCompleted) {
          _joinCompleter!.completeError(e);
        }
        _onSignalClosed();
      },
    );

    _ws!.sink.add(jsonEncode({'type': 'join', 'roomId': roomId, 'enableStt': enableStt}));

    try {
      await _joinCompleter!.future.timeout(const Duration(seconds: 15));
    } catch (e) {
      try {
        await _ws?.sink.close();
      } catch (_) {}
      _ws = null;
      _joinCompleter = null;
      rethrow;
    }
    _joinCompleter = null;
  }

  Future<void> triggerSttBot(String roomId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/start_bot'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'roomId': roomId,
          'signalingUrl': AppConfig.signalingUrl,
        }),
      );
      if (response.statusCode == 200) {
        debugPrint('STT Bot triggered successfully');
      } else {
        debugPrint('Failed to trigger STT Bot: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error triggering STT Bot: $e');
    }
  }

  Future<void> _createSttConnection() async {
    if (_sttPc != null) {
      debugPrint('STT connection already exists, skipping');
      return;
    }
    
    debugPrint('Creating STT peer connection...');
    final configuration = {
      'iceServers': AppConfig.turnServers,
      'sdpSemantics': 'unified-plan',
    };
    try {
      _sttPc = await createPeerConnection(configuration);
      debugPrint('STT peer connection created successfully');
      
      // Monitor connection state
      _sttPc!.onConnectionState = (state) {
        debugPrint('STT Connection State: $state');
      };
      
      _sttPc!.onIceConnectionState = (state) {
        debugPrint('STT ICE Connection State: $state');
      };
      
      _sttPc!.onIceCandidate = (candidate) {
        if (candidate.candidate != null) {
          debugPrint('STT: Sending ICE candidate');
          _ws?.sink.add(
            jsonEncode({
              'type': 'stt-ice-candidate',
              'roomId': _roomId,
              'payload': {
                'candidate': candidate.candidate,
                'sdpMid': candidate.sdpMid,
                'sdpMLineIndex': candidate.sdpMLineIndex,
              },
            }),
          );
        }
      };

      // Add audio tracks
      if (_localStream != null) {
        final audioTracks = _localStream!.getAudioTracks();
        debugPrint('STT: Found ${audioTracks.length} audio tracks in local stream');
        
        for (final track in audioTracks) {
          debugPrint('STT: Adding audio track - enabled: ${track.enabled}, kind: ${track.kind}, id: ${track.id}');
          
          // Ensure track is enabled
          track.enabled = true;
          
          await _sttPc!.addTrack(track, _localStream!);
          debugPrint('STT: Audio track added successfully');
        }
      } else {
        debugPrint('STT ERROR: Local stream is null, cannot add audio tracks!');
      }

      final offer = await _sttPc!.createOffer();
      await _sttPc!.setLocalDescription(offer);
      debugPrint('STT: Offer created and set, SDP length: ${offer.sdp?.length ?? 0}');
      
      _ws?.sink.add(
        jsonEncode({
          'type': 'stt-offer',
          'roomId': _roomId,
          'payload': <String, dynamic>{
            ...offer.toMap(),
          },
        }),
      );
      debugPrint('STT: Offer sent to signaling server');
    } catch (e) {
      debugPrint('Error creating STT connection: $e');
    }
  }

  Future<void> _createPeerConnection() async {
    if (_pc != null) return;

    final configuration = {
      'iceServers': AppConfig.turnServers,
      'bundlePolicy': 'max-bundle',
      'sdpSemantics': 'unified-plan',
    };

    try {
      _pc = await createPeerConnection(configuration);
    } catch (e) {
      errorMessage.value = 'Failed to create peer connection: $e';
      _error('Failed to create peer connection: $e');
      rethrow;
    }

    _pc!.onConnectionState = (state) {
      pcState.value = state.toString();
    };
    _pc!.onIceConnectionState = (state) {
      iceConnectionState.value = state.toString();
    };
    _pc!.onSignalingState = (state) {
      signalingState.value = state.toString();
    };

    _pc!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        localIceCount.value = localIceCount.value + 1;
        _ws?.sink.add(
          jsonEncode({
            'type': 'ice-candidate',
            'payload': {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            },
          }),
        );
      }
    };

    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams[0];
        if (event.track.kind == 'video') {
          hasRemoteVideo.value = true;
        }
      }
      event.track.enabled = true;
    };

    try {
      _pc!.onAddStream = (stream) {
        remoteRenderer.srcObject = stream;
        if (stream.getVideoTracks().isNotEmpty) {
          hasRemoteVideo.value = true;
        }
      };
    } catch (_) {}

    try {
      await _getUserMedia();
    } catch (e) {
      errorMessage.value = 'Failed to access camera/microphone: $e';
      rethrow;
    }

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        track.enabled = true;
        await _pc!.addTrack(track, _localStream!);
      }
    }
  }

  void setLocalStream(MediaStream stream) {
    _localStream = stream;
    localRenderer.srcObject = _localStream;
  }

  Future<void> _getUserMedia() async {
    if (_localStream == null) {
      throw Exception('Local stream not set.');
    }
  }

  void _onSignalMessage(dynamic data) async {
    try {
      final msg = jsonDecode(data as String);
      final type = msg['type'];

      if (type == 'joined') {
        final peersCount = msg['peersCount'] as int;
        _isOfferer = peersCount > 1;
        // Store our own client ID so we can filter our own captions out later
        _myClientId = msg['clientId'] as String?;
        await _createPeerConnection();

        if (_isOfferer) {
          final offer = await _pc!.createOffer();
          sdpOfferLength.value = offer.sdp?.length ?? 0;
          await _pc!.setLocalDescription(offer);
          _ws?.sink.add(
            jsonEncode({'type': 'offer', 'payload': offer.toMap()}),
          );
        }

        // Wait for 'bot-ready' signal from the server-side bot before connecting.
        // This ensures the bot has loaded Whisper and joined the room.
        debugPrint('Waiting for bot-ready signal...');

        inCall.value = true;
        if (peersCount > 1) {
          partnerPresent.value = true;
        }

        if (_joinCompleter != null && !_joinCompleter!.isCompleted) {
          _joinCompleter!.complete();
        }
      } else if (type == 'peer_joined') {
        partnerPresent.value = true;
      } else if (type == 'offer') {
        await _createPeerConnection();
        await _pc?.setRemoteDescription(
          RTCSessionDescription(msg['payload']['sdp'], msg['payload']['type']),
        );
        final answer = await _pc!.createAnswer();
        sdpAnswerLength.value = answer.sdp?.length ?? 0;
        await _pc!.setLocalDescription(answer);
        _ws?.sink.add(
          jsonEncode({'type': 'answer', 'payload': answer.toMap()}),
        );
      } else if (type == 'answer') {
        await _pc?.setRemoteDescription(
          RTCSessionDescription(msg['payload']['sdp'], msg['payload']['type']),
        );
      } else if (type == 'stt-answer') {
        await _sttPc?.setRemoteDescription(
          RTCSessionDescription(msg['payload']['sdp'], msg['payload']['type']),
        );
      } else if (type == 'stt-ice-candidate') {
        final c = msg['payload'];
        try {
          await _sttPc?.addCandidate(
            RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']),
          );
        } catch (_) {}
      } else if (type == 'ice-candidate') {
        final c = msg['payload'];
        remoteIceCount.value = remoteIceCount.value + 1;
        try {
          await _pc?.addCandidate(
            RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']),
          );
        } catch (_) {}
      } else if (type == 'text-update') {
        remoteTranslatedText.value = msg['payload']['text'] as String? ?? '';
      } else if (type == 'caption-update') {
        final text = msg['payload']['text'] as String? ?? '';
        remoteCaptions.value = text;
        // Filter: only surface captions that are NOT from our own mic.
        // The STT bot labels each caption as "[clientSuffix]: text".
        // We compare that suffix to our own client ID suffix.
        final labelMatch = RegExp(r'^\[(\w+)\]:\s*').firstMatch(text);
        final speakerSuffix = labelMatch?.group(1);
        final mySuffix = _myClientId?.split('_').last;
        final isOwnCaption = mySuffix != null && speakerSuffix == mySuffix;
        final cleanText = labelMatch != null
            ? text.substring(labelMatch.end).trim()
            : text.trim();
        if (isOwnCaption) {
          // Show the user their own transcribed speech
          myOwnCaptions.value = cleanText;
        } else {
          // Strip the [id]: prefix for clean display
          partnerCaptions.value = cleanText;
        }
      } else if (type == 'peer_left') {
        await _closePeerConnection();
        partnerPresent.value = false;
        inCall.value = true;
      } else if (type == 'bot-ready') {
        if (_sttEnabled) {
          debugPrint('STT Bot is ready! Establishing connection...');
          _createSttConnection();
        } else {
          debugPrint('STT Bot is ready, but STT is disabled for this user.');
        }
      } else if (type == 'room_full') {
        if (_joinCompleter != null && !_joinCompleter!.isCompleted) {
          _joinCompleter!.completeError(Exception('Room is full'));
        }
      }
    } catch (e) {
      debugPrint('Error processing signal message: $e');
      debugPrint('Raw message: $data');
    }
  }

  void _onSignalClosed() {
    _closePeerConnection();
    inCall.value = false;
    partnerPresent.value = false;
  }

  Future<void> hangUp() async {
    try {
      if (_ws != null) {
        _ws?.sink.add(jsonEncode({'type': 'leave'}));
      }
    } catch (_) {}
    await _closePeerConnection();
    try {
      await _ws?.sink.close();
    } catch (_) {}
    _ws = null;
    _roomId = null;
    inCall.value = false;
    partnerPresent.value = false;
  }

  Future<void> _closePeerConnection() async {
    try {
      await _sttPc?.close();
    } catch (_) {}
    _sttPc = null;
    try {
      await _pc?.close();
    } catch (_) {}
    _pc = null;
    remoteRenderer.srcObject = null;
    localRenderer.srcObject = null;
    hasRemoteVideo.value = false;
  }

  void toggleMic() {
    if (_localStream == null) return;
    final enabled = !micEnabled.value;
    for (final t in _localStream!.getAudioTracks()) {
      t.enabled = enabled;
    }
    micEnabled.value = enabled;
  }

  void toggleCamera() {
    if (_localStream == null) return;
    final enabled = !camEnabled.value;
    for (final t in _localStream!.getVideoTracks()) {
      t.enabled = enabled;
    }
    camEnabled.value = enabled;
  }

  void sendTextUpdate(String text) {
    if (_ws != null) {
      _ws?.sink.add(jsonEncode({
        'type': 'text-update',
        'roomId': _roomId,
        'payload': {
          'text': text,
        },
      }));
    }
  }

  void sendCaptionUpdate(String text) {
    if (_ws != null && inCall.value) {
      _ws?.sink.add(jsonEncode({
        'type': 'caption-update',
        'roomId': _roomId,
        'payload': {
          'text': text,
        },
      }));
    }
  }

  Future<void> retryGetUserMedia() async {
    // Basic implementation to satisfy old screen references
  }

  void _error(String msg) {
    debugPrint('WebRTC error: $msg');
  }
}
