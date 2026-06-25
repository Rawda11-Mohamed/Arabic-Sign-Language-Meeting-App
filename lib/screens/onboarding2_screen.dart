import 'package:flutter/material.dart';
import 'package:meeting/utils/app_routes.dart';
import 'package:meeting/widgets/app_button.dart';
import 'package:meeting/localization/app_localizations.dart';

/// Second onboarding screen - Speech Recognition
class Onboarding2Screen extends StatelessWidget {
  const Onboarding2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background section
          Positioned.fill(
            child: Container(
              color: Colors.white,
              child: Center(
                child: Icon(
                  Icons.mic_none,
                  size: 150,
                  color: const Color(0xFF0D2652).withOpacity(0.8),
                ),
              ),
            ),
          ),
          
          // Overlapping bottom container
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Skip button to allow users to skip onboarding
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.onboarding3),
                      child: Text(localizations?.translate('skip') ?? 'Skip'),
                    ),
                  ),
                  Text(
                    localizations?.translate('speechRecognitionTitle') ?? 'Speak Without Barriers',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D2652),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations?.translate('speechRecognitionDescription') ?? 'AI-powered recognition for accurate conversations.',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == 1 ? const Color(0xFF0D2652) : Colors.grey[300],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    label: localizations?.continueText ?? 'Next',
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.onboarding3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
