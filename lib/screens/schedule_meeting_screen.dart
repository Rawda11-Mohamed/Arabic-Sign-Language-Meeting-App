import 'package:flutter/material.dart';
import 'package:meeting/widgets/app_button.dart';
import 'package:meeting/widgets/app_text_field.dart';
import 'package:meeting/services/meeting_service.dart';
import 'package:meeting/localization/app_localizations.dart';
import 'package:intl/intl.dart';

/// Schedule meeting screen
class ScheduleMeetingScreen extends StatefulWidget {
  const ScheduleMeetingScreen({super.key});

  @override
  State<ScheduleMeetingScreen> createState() => _ScheduleMeetingScreenState();
}

class _ScheduleMeetingScreenState extends State<ScheduleMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _meetingNameController = TextEditingController();
  final _participantsController = TextEditingController();
  final _meetingService = MeetingService();
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _meetingNameController.dispose();
    _participantsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _handleScheduleMeeting() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );
    final endDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    final participants = _participantsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final success = await _meetingService.scheduleMeeting(
      meetingName: _meetingNameController.text.trim(),
      date: _selectedDate!,
      startTime: startDateTime,
      endTime: endDateTime,
      participants: participants,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting scheduled successfully')),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      String errorMessage = 'Failed to schedule meeting';
      if (startDateTime.isBefore(DateTime.now())) {
        errorMessage = 'Start time cannot be in the past';
      } else if (endDateTime.isBefore(startDateTime)) {
        errorMessage = 'End time must be after start time';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Theme.of(context).colorScheme.primary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Text(
                  localizations?.translate('scheduleMeeting') ?? 'Schedule Meeting',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                AppTextField(
                  label: localizations?.translate('meetingName') ?? 'Meeting Name',
                  controller: _meetingNameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations?.translate('meetingNameRequired') ?? 'Please enter meeting name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: localizations?.translate('meetingDate') ?? 'Meeting Date',
                      suffixIcon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                    ),
                    child: Text(
                      _selectedDate != null
                          ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                          : (localizations?.translate('selectDate') ?? 'Select date'),
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _selectStartTime(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: localizations?.translate('startTime') ?? 'Start Time',
                      suffixIcon: Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
                    ),
                    child: Text(
                      _startTime != null
                          ? _startTime!.format(context)
                          : (localizations?.translate('selectStartTime') ?? 'Select start time'),
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _selectEndTime(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: localizations?.translate('endTime') ?? 'End Time',
                      suffixIcon: Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
                    ),
                    child: Text(
                      _endTime != null
                          ? _endTime!.format(context)
                          : (localizations?.translate('selectEndTime') ?? 'Select end time'),
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: localizations?.translate('participants') ?? 'Participants',
                  controller: _participantsController,
                  hint: localizations?.translate('participantsHint') ?? 'Email addresses separated by commas',
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: AppButton(
            label: localizations?.translate('save') ?? 'Save',
            onPressed: _handleScheduleMeeting,
            isLoading: _isLoading,
          ),
        ),
      ),
    );
  }
}

