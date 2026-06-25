import 'package:flutter/material.dart';
import 'package:meeting/services/webrtc_call_service.dart';

/// Simple lobby screen to join or create a 1-on-1 video call room.
class CallLobbyScreen extends StatefulWidget {
  final WebRtcCallService callService;

  const CallLobbyScreen({super.key, required this.callService});

  @override
  State<CallLobbyScreen> createState() => _CallLobbyScreenState();
}

class _CallLobbyScreenState extends State<CallLobbyScreen> {
  final TextEditingController _roomController = TextEditingController();
  bool _joining = false;

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final roomId = _roomController.text.trim();
    if (roomId.isEmpty) return;

    setState(() => _joining = true);
    try {
      await widget.callService.initRenderers();
      await widget.callService.joinRoom(roomId);

      if (!mounted) return;
      Navigator.of(context).pushNamed(
        '/video-call',
        arguments: {'roomId': roomId},
      );
    } catch (e) {
      // Clean up any partially-initialized resources
      try {
        await widget.callService.hangUp();
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join room: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Call')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter Room ID',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _roomController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. ishara123',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _joining ? null : _join,
              child: _joining
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Join / Create Room'),
            ),
          ],
        ),
      ),
    );
  }
}
