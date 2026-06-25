import 'package:flutter/material.dart';
import 'package:meeting/services/meeting_service.dart';
import 'package:intl/intl.dart';

class ScheduledMeetingsListScreen extends StatefulWidget {
  const ScheduledMeetingsListScreen({super.key});

  @override
  State<ScheduledMeetingsListScreen> createState() => _ScheduledMeetingsListScreenState();
}

class _ScheduledMeetingsListScreenState extends State<ScheduledMeetingsListScreen> {
  final MeetingService _meetingService = MeetingService();
  List<ScheduledMeeting> _meetings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    setState(() => _isLoading = true);
    final meetings = await _meetingService.getScheduledMeetings();
    // Sort by date/time
    meetings.sort((a, b) => a.startTime.compareTo(b.startTime));
    setState(() {
      _meetings = meetings;
      _isLoading = false;
    });
  }

  Future<void> _confirmDelete(ScheduledMeeting meeting) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meeting'),
        content: Text('Are you sure you want to delete "${meeting.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _meetingService.deleteMeeting(meeting.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meeting deleted successfully')),
        );
        _loadMeetings();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Meetings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _meetings.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadMeetings,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _meetings.length,
                    itemBuilder: (context, index) {
                      final meeting = _meetings[index];
                      final bool isPast = meeting.startTime.isBefore(DateTime.now());

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: isPast ? Colors.grey : Theme.of(context).primaryColor,
                            child: Icon(
                              isPast ? Icons.history : Icons.event,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            meeting.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(DateFormat('MMM dd, yyyy').format(meeting.date)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${DateFormat('hh:mm a').format(meeting.startTime)} - ${DateFormat('hh:mm a').format(meeting.endTime)}',
                                  ),
                                ],
                              ),
                              if (meeting.participants.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Participants: ${meeting.participants.join(", ")}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                                ),
                              ],
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _confirmDelete(meeting),
                          ),
                          onTap: () {
                            // Logic to join or view details
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Meeting ID: ${meeting.id}')),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No meetings scheduled yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Go back to start meeting/schedule
            },
            child: const Text('Schedule Now'),
          ),
        ],
      ),
    );
  }
}
