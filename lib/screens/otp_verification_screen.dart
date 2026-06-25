import 'package:flutter/material.dart';
import 'package:meeting/utils/app_routes.dart';
import 'package:meeting/widgets/app_button.dart';
import 'package:meeting/widgets/app_otp_field.dart';
import 'package:meeting/services/auth_service.dart';
import 'package:meeting/localization/app_localizations.dart';

/// OTP verification screen
class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({super.key});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _authService = AuthService();
  String _otp = '';
  bool _isLoading = false;

  Future<void> _handleVerify() async {
    if (_otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete OTP code')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await _authService.verifyOTP(_otp);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.createNewPassword);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: const Color(0xFF0D2652)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Verify OTP',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D2652),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter the 4-digit code sent to your email',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              AppOtpField(
                length: 4,
                onChanged: (value) {
                  setState(() => _otp = value);
                },
                onCompleted: (value) {
                  _otp = value;
                  _handleVerify();
                },
              ),
              const SizedBox(height: 48),
              AppButton(
                label: 'Verify Code',
                onPressed: _handleVerify,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

