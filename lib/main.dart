import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:meeting/utils/app_routes.dart';
import 'package:meeting/utils/theme_provider.dart';
import 'package:meeting/utils/locale_provider.dart';
import 'package:meeting/theme/app_theme.dart';
import 'package:meeting/localization/app_localizations.dart';
import 'package:meeting/screens/splash_screen.dart';
import 'package:meeting/screens/onboarding_screen.dart';
import 'package:meeting/screens/login_screen.dart';
import 'package:meeting/screens/signup_screen.dart';
import 'package:meeting/screens/reset_password_screen.dart';
import 'package:meeting/screens/otp_verification_screen.dart';
import 'package:meeting/screens/create_new_password_screen.dart';
import 'package:meeting/screens/dashboard_screen.dart';
import 'package:meeting/screens/join_meeting_screen.dart';
import 'package:meeting/screens/start_meeting_screen.dart';
import 'package:meeting/screens/schedule_meeting_screen.dart';
import 'package:meeting/screens/meeting_using_audio_screen.dart';
import 'package:meeting/screens/meeting_using_sign_language_screen.dart';
import 'package:meeting/screens/settings_screen.dart';
import 'package:meeting/screens/my_profile_screen.dart';
import 'package:meeting/screens/sign_language_test_screen.dart';
import 'package:meeting/screens/call_lobby_screen.dart';
import 'package:meeting/screens/call_screen.dart';
import 'package:meeting/screens/scheduled_meetings_list_screen.dart';

import 'package:meeting/services/webrtc_call_service.dart';
import 'package:meeting/utils/app_config.dart';

import 'package:meeting/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const IsharaApp());
}

/// Main app widget with providers and navigation
class IsharaApp extends StatelessWidget {
  const IsharaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, child) {
          return MaterialApp(
            title: 'Ishara',
            debugShowCheckedModeBanner: false,
            
            // Theme configuration
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            
            // Localization configuration
            locale: localeProvider.locale,
            supportedLocales: const [
              Locale('en', ''),
              Locale('ar', ''),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            
            // RTL support for Arabic
            builder: (context, child) {
              return Directionality(
                textDirection: localeProvider.isArabic 
                    ? TextDirection.rtl 
                    : TextDirection.ltr,
                child: MediaQuery(
                  // Support for accessibility - large text
                  data: MediaQuery.of(context).copyWith(
                    textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(
                      1.0,
                      2.0,
                    ).toDouble(),
                  ),
                  child: child!,
                ),
              );
            },
            
            // Navigation routes
            initialRoute: AppRoutes.splash,
            onGenerateRoute: (settings) {
              // Use a single shared WebRTC call service instance for the whole
              // route generation so the same renderers/connection are used when
              // navigating between the lobby and call screens.
              final webRtcCallService = _sharedWebRtcCallService ??= WebRtcCallService(
                signalingUrl: AppConfig.signalingUrl,
              );

              switch (settings.name) {
                case AppRoutes.splash:
                  return MaterialPageRoute(builder: (_) => const SplashScreen());
                case AppRoutes.onboarding:
                  return MaterialPageRoute(builder: (_) => const OnboardingScreen());
                case AppRoutes.login:
                  return MaterialPageRoute(builder: (_) => const LoginScreen());
                case AppRoutes.signUp:
                  return MaterialPageRoute(builder: (_) => const SignUpScreen());
                case AppRoutes.resetPassword:
                  return MaterialPageRoute(builder: (_) => const ResetPasswordScreen());
                case AppRoutes.otpVerification:
                  return MaterialPageRoute(builder: (_) => const OTPVerificationScreen());
                case AppRoutes.createNewPassword:
                  return MaterialPageRoute(builder: (_) => const CreateNewPasswordScreen());
                case AppRoutes.dashboard:
                  return MaterialPageRoute(builder: (_) => const DashboardScreen());
                case AppRoutes.joinMeeting:
                  return MaterialPageRoute(builder: (_) => const JoinMeetingScreen());
                case AppRoutes.startMeeting:
                  return MaterialPageRoute(builder: (_) => const StartMeetingScreen());
                case AppRoutes.scheduleMeeting:
                  return MaterialPageRoute(builder: (_) => const ScheduleMeetingScreen());
                case AppRoutes.meetingUsingAudio:
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (_) => const MeetingUsingAudioScreen(),
                  );
                case AppRoutes.meetingUsingSignLanguage:
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (_) => const MeetingUsingSignLanguageScreen(),
                  );
                case AppRoutes.settings:
                  return MaterialPageRoute(builder: (_) => const SettingsScreen());
                case AppRoutes.myProfile:
                  return MaterialPageRoute(builder: (_) => const MyProfileScreen());
                case AppRoutes.signLanguageTest:
                  return MaterialPageRoute(builder: (_) => const SignLanguageTestScreen());
                case AppRoutes.videoCallLobby:
                  return MaterialPageRoute(
                    builder: (_) => CallLobbyScreen(callService: webRtcCallService),
                  );
                case AppRoutes.videoCall:
                  final args = settings.arguments as Map<String, dynamic>? ?? {};
                  final roomId = args['roomId'] as String? ?? 'room';
                  return MaterialPageRoute(
                    builder: (_) => CallScreen(
                      callService: webRtcCallService,
                      roomId: roomId,
                    ),
                  );
                case AppRoutes.scheduledMeetings:
                  return MaterialPageRoute(builder: (_) => const ScheduledMeetingsListScreen());
                default:
                  return MaterialPageRoute(builder: (_) => const SplashScreen());
              }
            },
          );
        },
      ),
    );
  }
}

// Lazily-created singleton for WebRtcCallService used by the navigator.
WebRtcCallService? _sharedWebRtcCallService;
