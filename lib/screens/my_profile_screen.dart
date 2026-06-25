import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meeting/widgets/app_button.dart';
import 'package:meeting/widgets/app_text_field.dart';
import 'package:meeting/services/auth_service.dart';
import 'package:meeting/localization/app_localizations.dart';
import 'package:meeting/utils/validation_utils.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _authService = AuthService();
  User? _currentUser;
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  File? _imageFile;
  String? _savedImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSavedImage();
  }

  Future<void> _loadSavedImage() async {
    final path = await _authService.getProfileImagePath();
    if (path != null && mounted) {
      setState(() {
        _savedImagePath = path;
        _imageFile = File(path);
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // Persist immediately — no need to press Save for the photo
      await _authService.saveProfileImagePath(image.path);
      if (mounted) {
        setState(() {
          _imageFile = File(image.path);
          _savedImagePath = image.path;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final user = await _authService.getCurrentUser();
    if (user != null) {
      String fName = user.firstName;
      String lName = user.lastName;
      final fullName = '$fName $lName'.trim().toLowerCase();
      if (fullName == 'hgc cc' || fName.trim().toLowerCase() == 'hgc cc') {
        fName = 'Mohamed';
        lName = '';
      }
      _firstNameController.text = fName;
      _lastNameController.text = lName;
      setState(() => _currentUser = user);
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    // 1. Update Name
    final nameSuccess = await _authService.updateProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );

    // 2. Update Password (if new password entered)
    bool passwordSuccess = true;
    if (_newPasswordController.text.isNotEmpty) {
      passwordSuccess = await _authService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (nameSuccess && passwordSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _loadUserData(); // Refresh local state
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update failed. Check your current password.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          localizations?.translate('myProfile') ?? 'My Profile',
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
        child: _isLoading && _currentUser == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                       const SizedBox(height: 16),
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Theme.of(context).dividerColor.withOpacity(0.1),
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!) as ImageProvider
                                : null,
                            child: _imageFile == null
                                ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor, 
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.camera_alt, 
                                  size: 20, 
                                  color: Theme.of(context).colorScheme.primary
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_firstNameController.text} ${_lastNameController.text}'.trim(),
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold, 
                          color: Theme.of(context).textTheme.titleLarge?.color
                        ),
                      ),
                      const SizedBox(height: 32),
                      AppTextField(
                        label: localizations?.translate('currentPassword') ?? 'Current password',
                        controller: _currentPasswordController,
                        hint: localizations?.translate('currentPasswordHint') ?? 'Enter current password',
                        obscureText: _obscureCurrentPassword,
                        suffixIcon: _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                        onSuffixTap: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: localizations?.translate('newPassword') ?? 'New password',
                        controller: _newPasswordController,
                        hint: localizations?.translate('newPasswordHint') ?? 'Enter new password',
                        obscureText: _obscureNewPassword,
                        suffixIcon: _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                        onSuffixTap: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: localizations?.translate('confirmNewPassword') ?? 'Re-type new password',
                        controller: _confirmPasswordController,
                        hint: localizations?.translate('confirmNewPasswordHint') ?? 'Re-type new password',
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        onSuffixTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
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
            label: localizations?.translate('saveChanges') ?? 'Save any changes',
            onPressed: _handleSave,
            isLoading: _isLoading,
          ),
        ),
      ),
    );
  }
}

