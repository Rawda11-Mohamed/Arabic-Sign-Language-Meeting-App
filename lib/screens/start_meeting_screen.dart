import 'package:flutter/material.dart';
import 'package:meeting/utils/app_routes.dart';
import 'package:meeting/widgets/app_logo.dart';
import 'package:meeting/widgets/app_button.dart';
import 'package:meeting/widgets/app_text_field.dart';
import 'package:meeting/widgets/app_radio_group.dart';
import 'package:meeting/services/meeting_service.dart';
import 'package:meeting/localization/app_localizations.dart';

/// Start meeting screen
class StartMeetingScreen extends StatefulWidget {
  const StartMeetingScreen({super.key});

  @override
  State<StartMeetingScreen> createState() => _StartMeetingScreenState();
}

class _StartMeetingScreenState extends State<StartMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _meetingNameController = TextEditingController();
  final _meetingService = MeetingService();
  MeetingRole? _selectedRole;
  bool _isLoading = false;

  @override
  void dispose() {
    _meetingNameController.dispose();
    super.dispose();
  }

  Future<void> _handleStartMeeting() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final error = await _meetingService.startMeeting(
      meetingName: 'Meeting',
      role: _selectedRole!,
    );

    setState(() => _isLoading = false);

    if (error == null && mounted) {
      // Navigate directly into the video call for the new meeting.
      // Navigate directly into the video call for the new meeting.
      final meetingId = _meetingService.getCurrentMeetingId();
      
      if (_selectedRole == MeetingRole.signLanguage) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.meetingUsingSignLanguage,
          arguments: {'roomId': meetingId},
        );
      } else {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.meetingUsingAudio,
          arguments: {'roomId': meetingId},
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Failed to start meeting')),
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
                  localizations?.translate('startMeeting') ?? 'Start a Meeting',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 100),
                Text(
                  localizations?.translate('selectRole') ?? 'Choose a Role',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildRoleOption(localizations?.translate('useAudio') ?? 'Use Audio', MeetingRole.audio),
                _buildRoleOption(localizations?.translate('useSignLanguage') ?? 'Use Sign Language', MeetingRole.signLanguage),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: AppButton(
            label: localizations?.translate('startMeeting') ?? 'Start Meeting',
            onPressed: _handleStartMeeting,
            isLoading: _isLoading,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption(String label, MeetingRole role) {
    final isSelected = _selectedRole == role;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey[400]!,
                  width: isSelected ? 5 : 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
