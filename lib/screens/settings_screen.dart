import 'package:flutter/material.dart';
import 'package:meeting/widgets/app_button.dart';
import 'package:meeting/widgets/app_toggle.dart';
import 'package:meeting/widgets/app_dropdown.dart';
import 'package:meeting/widgets/app_radio_group.dart';
import 'package:meeting/utils/theme_provider.dart';
import 'package:meeting/utils/locale_provider.dart';
import 'package:meeting/localization/app_localizations.dart';
import 'package:provider/provider.dart';

/// Settings screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  late String? _selectedLanguage;
  late ThemeMode? _selectedMode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    _selectedMode = themeProvider.themeMode;
    _selectedLanguage = localeProvider.locale.languageCode;
  }

  void _handleSave() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    if (_selectedMode != null) {
      themeProvider.setThemeMode(_selectedMode!);
    }

    if (_selectedLanguage != null) {
      localeProvider.setLocale(Locale(_selectedLanguage!));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    
    // Initialize if not set
    _selectedMode ??= themeProvider.themeMode;
    _selectedLanguage ??= localeProvider.locale.languageCode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          localizations?.translate('settings') ?? 'Settings',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Theme.of(context).colorScheme.primary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Notifications Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizations?.translate('notifications') ?? 'Notifications',
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.w600, 
                      color: Theme.of(context).textTheme.bodyLarge?.color
                    ),
                  ),
                  Switch(
                    value: _notificationsEnabled,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (value) => setState(() => _notificationsEnabled = value),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Language Dropdown
              Text(
                localizations?.translate('language') ?? 'Language',
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w600, 
                  color: Theme.of(context).textTheme.bodyLarge?.color
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    isExpanded: true,
                    dropdownColor: Theme.of(context).cardColor,
                    icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary),
                    items: [
                      DropdownMenuItem(value: 'en', child: Text(localizations?.translate('english') ?? 'English')),
                      DropdownMenuItem(value: 'ar', child: Text(localizations?.translate('arabic') ?? 'Arabic')),
                    ],
                    onChanged: (value) => setState(() => _selectedLanguage = value),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Mode Selection
              Text(
                localizations?.translate('mode') ?? 'Mode',
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w600, 
                  color: Theme.of(context).textTheme.bodyLarge?.color
                ),
              ),
              const SizedBox(height: 8),
              _buildRadioOption(localizations?.translate('light') ?? 'Light Mode', ThemeMode.light),
              _buildRadioOption(localizations?.translate('dark') ?? 'Dark Mode', ThemeMode.dark),
              const SizedBox(height: 48),
              AppButton(
                label: localizations?.translate('saveChanges') ?? 'Save any changes',
                onPressed: _handleSave,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption(String label, ThemeMode mode) {
    final isSelected = _selectedMode == mode;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return InkWell(
      onTap: () => setState(() => _selectedMode = mode),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                color: isSelected ? primaryColor : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

