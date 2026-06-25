import 'package:flutter/material.dart';
import 'package:meeting/utils/app_routes.dart';
import 'package:meeting/widgets/app_logo.dart';
import 'package:meeting/widgets/app_card.dart';
import 'package:meeting/localization/app_localizations.dart';

/// Dashboard screen - Main screen after login
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 32),

              const SizedBox(height: 8),
              // Logo
              const AppLogo(logoHeight: 120, fontSize: 20),

              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 800 ? 3 : 2;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.0,
                    children: [
                      _buildDashboardCard(
                        context,
                        label: localizations?.translate('joinMeeting') ?? 'Join\nMeeting',
                        icon: Icons.add_circle_outline,
                        onTap: () => Navigator.of(context).pushNamed(AppRoutes.joinMeeting),
                      ),
                      _buildDashboardCard(
                        context,
                        label: localizations?.translate('startMeeting') ?? 'Start\nMeeting',
                        icon: Icons.videocam_outlined,
                        onTap: () => Navigator.of(context).pushNamed(AppRoutes.startMeeting),
                      ),
                      _buildDashboardCard(
                        context,
                        label: localizations?.translate('scheduleMeeting') ?? 'Schedule\na Meeting',
                        icon: Icons.calendar_today_outlined,
                        onTap: () => Navigator.of(context).pushNamed(AppRoutes.scheduleMeeting),
                      ),
                      _buildDashboardCard(
                        context,
                        label: localizations?.translate('settings') ?? 'Settings',
                        icon: Icons.settings_outlined,
                        onTap: () => Navigator.of(context).pushNamed(AppRoutes.settings),
                      ),
                      _buildDashboardCard(
                        context,
                        label: localizations?.translate('myProfile') ?? 'My Profile',
                        icon: Icons.person_outline,
                        onTap: () => Navigator.of(context).pushNamed(AppRoutes.myProfile),
                      ),
                      _buildDashboardCard(
                        context,
                        label: localizations?.translate('myMeetings') ?? 'My\nMeetings',
                        icon: Icons.list_alt_outlined,
                        onTap: () => Navigator.of(context).pushNamed(AppRoutes.scheduledMeetings),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

