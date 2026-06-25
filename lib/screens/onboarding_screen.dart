import 'package:flutter/material.dart';
import 'package:meeting/utils/app_routes.dart';
import 'package:meeting/widgets/app_button.dart';
import 'package:meeting/localization/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    final pages = [
      _OnboardingData(
        image: 'assets/images/On boarding 2.png',
        title: localizations?.translate('welcomeTitle') ?? 'Welcome to Ishara',
        description: localizations?.translate('welcomeDescription') ?? 
            'Instantly translate Arabic Sign Language into clear speech so you can connect effortlessly with anyone around you',
      ),
      _OnboardingData(
        image: 'assets/images/On boarding1.png',
        title: localizations?.translate('speechRecognitionTitle') ?? 'Speak Without Barriers',
        description: localizations?.translate('speechRecognitionDescription') ?? 
            'Our AI-powered recognition makes your hand signs heard — in real-time, accurate, and natural conversations.',
      ),
      _OnboardingData(
        image: 'assets/images/On boarding3.png',
        title: localizations?.translate('smartFastTitle') ?? 'Smart,Fast and Inclusive',
        description: localizations?.translate('smartFastDescription') ?? 
            'Video call, chat and communicate confidently anywhere using automatic ArSL translation and voice output.',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background PageView with edge-to-edge images
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: pages.length,
              itemBuilder: (context, index) {
                return Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(top: 60), // Space for status bar
                  child: Image.asset(
                    pages[index].image,
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topCenter,
                  ),
                );
              },
            ),
          ),
          
          // Overlapping bottom container perfectly flush at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pages[_currentPage].title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    pages[_currentPage].description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Custom dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pages.length, (index) {
                      final isSelected = _currentPage == index;
                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          // Making the hit area much larger for better UX
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                          color: Colors.transparent,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 8,
                            width: isSelected ? 24 : 8,
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.primary 
                                  : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  // Sign Up Button
                  AppButton(
                    label: localizations?.translate('signUp') ?? 'Sign Up',
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.signUp),
                  ),
                  const SizedBox(height: 8),
                  // Login Link
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
                    child: Text(
                      localizations?.translate('login') ?? 'Login',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
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

class _OnboardingData {
  final String image;
  final String title;
  final String description;

  _OnboardingData({
    required this.image,
    required this.title,
    required this.description,
  });
}
