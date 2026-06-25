import 'package:flutter/material.dart';
import 'package:meeting/utils/app_routes.dart';
import 'package:meeting/widgets/app_button.dart';
import 'package:meeting/localization/app_localizations.dart';

/// First onboarding screen - Welcome
class Onboarding1Screen extends StatelessWidget {
  const Onboarding1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top section with Icon (can be replaced with Image if needed)
          Positioned.fill(
            child: Container(
              color: Colors.white,
              child: Center(
                child: Icon(
                  Icons.person_outline,
                  size: 150,
                  color: const Color(0xFF0D2652).withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          
          // Overlapping bottom container
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                  Text(
                    localizations?.welcomeTitle ?? 'Welcome to Ishara',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D2652),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations?.welcomeDescription ??
                        'Instantly translate Arabic Sign Language into clear speech so you can connect effortlessly with anyone around you.',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 24, height: 6, decoration: BoxDecoration(color: const Color(0xFF0D2652), borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 4),
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    label: localizations?.translate('next') ?? 'Next',
                    onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding2),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

