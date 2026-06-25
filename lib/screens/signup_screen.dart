import 'package:flutter/material.dart';
import 'package:meeting/utils/app_routes.dart';
import 'package:meeting/widgets/app_logo.dart';
import 'package:meeting/widgets/app_button.dart';
import 'package:meeting/widgets/app_text_field.dart';
import 'package:meeting/services/auth_service.dart';
import 'package:meeting/localization/app_localizations.dart';
import 'package:meeting/utils/validation_utils.dart';

/// Sign up screen
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await _authService.signUp(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign up failed. Please try again.')),
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
                  localizations?.translate('signUp') ?? 'Sign Up',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  localizations?.translate('createAccount') ?? 'Create your account',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: localizations?.translate('firstName') ?? 'First name',
                  controller: _firstNameController,
                  hint: localizations?.translate('firstNameHint') ?? 'Enter your first name',
                  validator: (value) => ValidationUtils.validateName(value, localizations?.translate('firstName') ?? 'First name'),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: localizations?.translate('lastName') ?? 'Last name',
                  controller: _lastNameController,
                  hint: localizations?.translate('lastNameHint') ?? 'Enter your last name',
                  validator: (value) => ValidationUtils.validateName(value, localizations?.translate('lastName') ?? 'Last name'),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: localizations?.translate('email') ?? 'Email address',
                  controller: _emailController,
                  hint: 'example@gmail.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: ValidationUtils.validateEmail,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: localizations?.translate('password') ?? 'Password',
                  controller: _passwordController,
                  hint: '********',
                  obscureText: _obscurePassword,
                  suffixIcon: _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  onSuffixTap: () => setState(() => _obscurePassword = !_obscurePassword),
                  validator: ValidationUtils.validatePassword,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: localizations?.translate('confirmPassword') ?? 'Confirm Password',
                  controller: _confirmPasswordController,
                  hint: '********',
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  onSuffixTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  validator: (value) => ValidationUtils.validateConfirmPassword(value, _passwordController.text),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: AppButton(
            label: localizations?.translate('continue') ?? 'Continue',
            onPressed: _handleSignUp,
            isLoading: _isLoading,
          ),
        ),
      ),
    );
  }
}

