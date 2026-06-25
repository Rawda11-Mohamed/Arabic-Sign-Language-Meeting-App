import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meeting/services/notification_service.dart';

class ScheduledMeeting {
  final String id;
  final String name;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> participants;

  ScheduledMeeting({
    required this.id,
    required this.name,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.participants,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'date': date.toIso8601String(),
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'participants': participants,
      };

  factory ScheduledMeeting.fromJson(Map<String, dynamic> json) => ScheduledMeeting(
        id: json['id'],
        name: json['name'],
        date: DateTime.parse(json['date']),
        startTime: DateTime.parse(json['startTime']),
        endTime: DateTime.parse(json['endTime']),
        participants: List<String>.from(json['participants']),
      );
}

/// Meeting service with local persistence and notifications
class MeetingService {
  static const String _meetingsKey = 'scheduled_meetings';

  /// Mock join meeting
  Future<String?> joinMeeting({
    required String meetingId,
    required String screenName,
    required MeetingRole role,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    if (meetingId.isEmpty) return 'Meeting ID is required';
    return null; // Success
  }

  /// Mock start meeting
  Future<String?> startMeeting({
    required String meetingName,
    required MeetingRole role,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    if (meetingName.isEmpty) return 'Meeting name is required';
    return null; // Success
  }

  /// Real schedule meeting with persistence and notifications
  Future<bool> scheduleMeeting({
    required String meetingName,
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
    required List<String> participants,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Validation
    if (startTime.isBefore(DateTime.now())) return false;
    if (endTime.isBefore(startTime)) return false;

    final prefs = await SharedPreferences.getInstance();
    
    final List<ScheduledMeeting> meetings = await getScheduledMeetings();
    
    final newMeeting = ScheduledMeeting(
      id: 'MTG-${DateTime.now().millisecondsSinceEpoch}',
      name: meetingName,
      date: date,
      startTime: startTime,
      endTime: endTime,
      participants: participants,
    );

    meetings.add(newMeeting);
    
    // Schedule a notification
    debugPrint('DEBUG: Requesting notification for meeting: ${newMeeting.name} at ${newMeeting.startTime}');
    await NotificationService().scheduleMeetingNotification(
      id: newMeeting.id.hashCode,
      title: 'Meeting Starting Soon!',
      body: '${newMeeting.name} starts in 5 minutes.',
      scheduledDate: newMeeting.startTime,
    );

    final List<String> meetingStrings = meetings.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList(_meetingsKey, meetingStrings);
    
    return true;
  }

  /// Get list of scheduled meetings
  Future<List<ScheduledMeeting>> getScheduledMeetings() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? meetingStrings = prefs.getStringList(_meetingsKey);
    
    if (meetingStrings == null) return [];
    
    return meetingStrings.map((s) => ScheduledMeeting.fromJson(jsonDecode(s))).toList();
  }

  /// Get meeting ID (mock)
  String getCurrentMeetingId() {
    return 'MOCK-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Delete a scheduled meeting
  Future<bool> deleteMeeting(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<ScheduledMeeting> meetings = await getScheduledMeetings();
    
    final int index = meetings.indexWhere((m) => m.id == id);
    if (index == -1) return false;

    // Remove from list
    meetings.removeAt(index);
    
    // Save updated list
    final List<String> meetingStrings = meetings.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList(_meetingsKey, meetingStrings);
    
    // Cancel notification
    await NotificationService().cancelNotification(id.hashCode);
    
    return true;
  }
}

enum MeetingRole {
  audio,
  signLanguage,
}
