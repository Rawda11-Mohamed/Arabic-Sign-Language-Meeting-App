import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String firstName;
  final String lastName;
  final String email;
  final String? password; // Only stored locally for mock demo
  final String? profileImagePath;

  User({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.password,
    this.profileImagePath,
  });

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'profileImagePath': profileImagePath,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        firstName: json['firstName'],
        lastName: json['lastName'],
        email: json['email'],
        password: json['password'],
        profileImagePath: json['profileImagePath'],
      );
}

/// Professional authentication service with local persistence
class AuthService {
  static const String _userKey = 'user_data';
  static const String _loginStatusKey = 'is_logged_in';
  static const String _profileImageKey = 'profile_image_path';

  /// Mock login with persistence
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    final prefs = await SharedPreferences.getInstance();
    
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      final user = User.fromJson(jsonDecode(userData));
      if (user.email == email && user.password == password) {
        await prefs.setBool(_loginStatusKey, true);
        return true;
      }
    }
    
    // Default demo user if none registered
    if (email == "test@ishara.com" && password == "Ishara@123") {
      final user = User(firstName: "Test", lastName: "User", email: email, password: password);
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      await prefs.setBool(_loginStatusKey, true);
      return true;
    }

    return false;
  }

  /// Signup with persistence
  Future<bool> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final prefs = await SharedPreferences.getInstance();
    
    final user = User(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );
    
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setBool(_loginStatusKey, true);
    return true;
  }

  /// Update user profile
  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData == null) return false;

    final existingUser = User.fromJson(jsonDecode(userData));
    final updatedUser = User(
      firstName: firstName,
      lastName: lastName,
      email: existingUser.email,
      password: existingUser.password,
      profileImagePath: existingUser.profileImagePath,
    );

    await prefs.setString(_userKey, jsonEncode(updatedUser.toJson()));
    return true;
  }

  /// Save profile image path locally
  Future<void> saveProfileImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImageKey, path);
  }

  /// Get saved profile image path
  Future<String?> getProfileImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileImageKey);
  }

  /// Real password change logic
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData == null) return false;

    final user = User.fromJson(jsonDecode(userData));
    if (user.password != currentPassword) return false;

    final updatedUser = User(
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      password: newPassword,
    );

    await prefs.setString(_userKey, jsonEncode(updatedUser.toJson()));
    return true;
  }

  /// Get current user
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData == null) return null;
    final user = User.fromJson(jsonDecode(userData));
    final fullName = '${user.firstName} ${user.lastName}'.trim().toLowerCase();
    if (fullName == 'hgc cc' || user.firstName.trim().toLowerCase() == 'hgc cc') {
      return User(
        firstName: 'Mohamed',
        lastName: '',
        email: user.email,
        password: user.password,
        profileImagePath: user.profileImagePath,
      );
    }
    return user;
  }

  /// Mock password reset request
  Future<bool> requestPasswordReset(String email) async {
    await Future.delayed(const Duration(seconds: 1));
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData == null) return false;
    
    final user = User.fromJson(jsonDecode(userData));
    return user.email == email;
  }

  /// Mock OTP verification
  Future<bool> verifyOTP(String otp) async {
    await Future.delayed(const Duration(seconds: 1));
    // Accept any 4-digit numeric OTP for easier demo testing
    return otp.length == 4 && int.tryParse(otp) != null;
  }

  /// Reset password (after OTP)
  Future<bool> resetPassword(String newPassword) async {
    await Future.delayed(const Duration(seconds: 1));
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData == null) return false;

    final user = User.fromJson(jsonDecode(userData));
    final updatedUser = User(
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      password: newPassword,
    );

    await prefs.setString(_userKey, jsonEncode(updatedUser.toJson()));
    return true;
  }

  /// Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loginStatusKey, false);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loginStatusKey) ?? false;
  }
}

