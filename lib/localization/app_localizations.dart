import 'package:flutter/material.dart';

/// App localization class for Arabic and English support
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // App
      'appName': 'Ishara',
      'appDescription': 'Making Every Conversation Possible',
      
      // Onboarding
      'welcomeTitle': 'Welcome to Ishara',
      'welcomeDescription': 'Instantly translate Arabic Sign Language into clear speech.',
      'speechRecognitionTitle': 'Speak Without Barriers',
      'speechRecognitionDescription': 'AI-powered recognition for accurate conversations.',
      'smartFastTitle': 'Smart, Fast and Inclusive',
      'smartFastDescription': 'Communicate confidently anywhere using ArSL.',
      
      // Auth
      'signUp': 'Sign Up',
      'login': 'Login',
      'email': 'Email',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'firstName': 'First Name',
      'lastName': 'Last Name',
      'forgotPassword': 'Forgot password?',
      'continue': 'Continue',
      'verify': 'Verify',
      'save': 'Save',
      'newPassword': 'New Password',
      'confirmNewPassword': 'Re-type New Password',
      'currentPassword': 'Current Password',
      'resetPasswordPrompt': 'Enter your email address and we will send you a verification code.',
      'pleaseEnterEmail': 'Please enter your email',
      'invalidEmail': 'Please enter a valid email',
      'sendCode': 'Send Verification Code',
      'createAccount': 'Create your account',
      'firstNameHint': 'Enter your first name',
      'lastNameHint': 'Enter your last name',
      'passwordRequired': 'Please enter your password',
      'changePassword': 'Change Password',
      'currentPasswordHint': 'Enter current password',
      'newPasswordHint': 'Enter new password',
      'confirmNewPasswordHint': 'Re-type new password',
      'profileUpdated': 'Profile updated successfully',
      'updateFailed': 'Update failed. Check your current password.',
      
      // Dashboard
      'quickActions': 'welcome!',
      'joinMeeting': 'Join Meeting',
      'startMeeting': 'Start Meeting',
      'scheduleMeeting': 'Schedule Meeting',
      'settings': 'Settings',
      'myProfile': 'My Profile',
      
      // Meeting
      'meetingId': 'Meeting ID',
      'screenName': 'Screen Name',
      'meetingName': 'Meeting Name',
      'chooseRole': 'Choose a Role',
      'useAudio': 'Use Audio',
      'useSignLanguage': 'Use Sign Language',
      'meetingDate': 'Meeting Date',
      'startTime': 'Start Time',
      'endTime': 'End Time',
      'participants': 'Participants',
      'meetingIdHint': 'Meeting ID',
      'screenNameHint': 'Screen Name',
      'pleaseSelectRole': 'Please select a role',
      'failedToJoin': 'Failed to join meeting',
      'selectRole': 'Choose a Role',
      'meetingNameHint': 'Meeting Name',
      'pleaseEnterMeetingId': 'Please enter meeting ID',
      'pleaseEnterScreenName': 'Please enter your screen name',
      'pleaseEnterMeetingName': 'Please enter meeting name',
      'selectDate': 'Select date',
      'selectStartTime': 'Select start time',
      'selectEndTime': 'Select end time',
      'participantsHint': 'Email addresses separated by commas',
      'meetingScheduled': 'Meeting scheduled successfully',
      'meetingNameRequired': 'Please enter meeting name',
      'liveInteraction': 'Live Interaction',
      'waitingForConnection': 'Waiting for Connection...',
      'roomIdLabel': 'Room ID: ',
      'partnerLabel': 'Partner',
      'youLabel': 'You',
      'silentMode': 'Silent Mode...',
      'wordsLabel': 'Words',
      'lettersLabel': 'Letters',
      'tryLettersMode': 'Struggling? Try Letters Mode',
      'permissionsRequired': 'Permissions Required',
      'permissionsRequiredMsg': 'Camera and Microphone permissions are required for this meeting. Please enable them in settings to continue.',
      'openSettings': 'Open Settings',
      'voiceLabel': 'Voice:',
      'cancel': 'Cancel',
      
      // Settings
      'notifications': 'Notifications',
      'language': 'Language',
      'mode': 'Mode',
      'light': 'Light',
      'dark': 'Dark',
      'saveChanges': 'Save changes',
      'arabic': 'Arabic',
      'english': 'English',
      
      // Profile
      'userName': 'User Name',
      
      // Meeting Controls
      'mute': 'Mute',
      'camera': 'Camera',
      'endCall': 'End Call',
      'liveSubtitles': 'Live Subtitles',
      'translatedSpeech': 'Translated Speech',
      'myMeetings': 'My Meetings',
      'enterEmailPassword': 'Enter your email and password',
      'loginFailed': 'Login failed. Please try again.',
      'emailAddressLabel': 'Enter your email address',
      'passwordLabel': 'Enter your password',
      'forgetPassword': 'Forget password?',
    },
    'ar': {
      // App
      'appName': 'إشارة',
      'appDescription': 'جعل كل محادثة ممكنة',
      
      // Onboarding
      'welcomeTitle': 'مرحباً بك في إشارة',
      'welcomeDescription': 'ترجمة فورية للغة الإشارة العربية إلى كلام واضح.',
      'speechRecognitionTitle': 'تحدث بدون حواجز',
      'speechRecognitionDescription': 'اعتراف مدعوم بالذكاء الاصطناعي للمحادثات الدقيقة.',
      'smartFastTitle': 'ذكي وسريع وشامل',
      'smartFastDescription': 'تواصل بثقة في أي مكان باستخدام لغة الإشارة العربية.',
      
      // Auth
      'signUp': 'إنشاء حساب',
      'login': 'تسجيل الدخول',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'confirmPassword': 'تأكيد كلمة المرور',
      'firstName': 'الاسم الأول',
      'lastName': 'اسم العائلة',
      'forgotPassword': 'نسيت كلمة المرور؟',
      'continue': 'متابعة',
      'verify': 'تحقق',
      'save': 'حفظ',
      'newPassword': 'كلمة المرور الجديدة',
      'confirmNewPassword': 'أعد كتابة كلمة المرور الجديدة',
      'currentPassword': 'كلمة المرور الحالية',
      'resetPasswordPrompt': 'أدخل عنوان بريدك الإلكتروني وسنرسل لك رمز التحقق.',
      'pleaseEnterEmail': 'يرجى إدخال بريدك الإلكتروني',
      'invalidEmail': 'يرجى إدخال بريد إلكتروني صالح',
      'sendCode': 'إرسال رمز التحقق',
      'createAccount': 'أنشئ حسابك',
      'firstNameHint': 'أدخل اسمك الأول',
      'lastNameHint': 'أدخل اسم عائلتك',
      'passwordRequired': 'يرجى إدخال كلمة المرور الخاصة بك',
      'changePassword': 'تغيير كلمة المرور',
      'currentPasswordHint': 'أدخل كلمة المرور الحالية',
      'newPasswordHint': 'أدخل كلمة المرور الجديدة',
      'confirmNewPasswordHint': 'أعد كتابة كلمة المرور الجديدة',
      'profileUpdated': 'تم تحديث الملف الشخصي بنجاح',
      'updateFailed': 'فشل التحديث. تحقق من كلمة مرورك الحالية.',
      
      // Dashboard
      'quickActions': 'مرحباً!',
      'joinMeeting': 'انضم إلى الاجتماع',
      'startMeeting': 'ابدأ اجتماعاً',
      'scheduleMeeting': 'جدولة اجتماع',
      'settings': 'الإعدادات',
      'myProfile': 'ملفي الشخصي',
      
      // Meeting
      'meetingId': 'معرف الاجتماع',
      'screenName': 'اسم الشاشة',
      'meetingName': 'اسم الاجتماع',
      'chooseRole': 'اختر دوراً',
      'useAudio': 'استخدم الصوت',
      'useSignLanguage': 'استخدم لغة الإشارة',
      'meetingDate': 'تاريخ الاجتماع',
      'startTime': 'وقت البدء',
      'endTime': 'وقت الانتهاء',
      'participants': 'المشاركون',
      'meetingIdHint': 'معرف الاجتماع',
      'screenNameHint': 'اسم الشاشة',
      'pleaseSelectRole': 'يرجى اختيار دور',
      'failedToJoin': 'فشل الانضمام إلى الاجتماع',
      'selectRole': 'اختر دوراً',
      'meetingNameHint': 'اسم الاجتماع',
      'pleaseEnterMeetingId': 'يرجى إدخال معرف الاجتماع',
      'pleaseEnterScreenName': 'يرجى إدخال اسم الشاشة الخاص بك',
      'pleaseEnterMeetingName': 'يرجى إدخال اسم الاجتماع',
      'selectDate': 'اختر التاريخ',
      'selectStartTime': 'اختر وقت البدء',
      'selectEndTime': 'اختر وقت الانتهاء',
      'participantsHint': 'عناوين البريد الإلكتروني مفصولة بفواصل',
      'meetingScheduled': 'تم جدولة الاجتماع بنجاح',
      'meetingNameRequired': 'يرجى إدخال اسم الاجتماع',
      'liveInteraction': 'تفاعل مباشر',
      'waitingForConnection': 'بانتظار الاتصال...',
      'roomIdLabel': 'معرف الغرفة: ',
      'partnerLabel': 'الشريك',
      'youLabel': 'أنت',
      'silentMode': 'وضع الصمت...',
      'wordsLabel': 'كلمات',
      'lettersLabel': 'حروف',
      'tryLettersMode': 'هل تواجه صعوبة؟ جرب وضع الحروف',
      'useAudio': 'استخدم الصوت',
      'useSignLanguage': 'استخدم لغة الإشارة',
      'permissionsRequired': 'الأذونات مطلوبة',
      'permissionsRequiredMsg': 'أذونات الكاميرا والميكروفون مطلوبة لهذا الاجتماع. يرجى تفعيلها في الإعدادات للمتابعة.',
      'openSettings': 'افتح الإعدادات',
      'voiceLabel': 'الصوت:',
      'cancel': 'إلغاء',
      
      // Settings
      'notifications': 'الإشعارات',
      'language': 'اللغة',
      'mode': 'الوضع',
      'light': 'فاتح',
      'dark': 'داكن',
      'saveChanges': 'حفظ التغييرات',
      'arabic': 'العربية',
      'english': 'الإنجليزية',
      
      // Profile
      'userName': 'اسم المستخدم',
      
      // Meeting Controls
      'mute': 'كتم الصوت',
      'camera': 'الكاميرا',
      'endCall': 'إنهاء المكالمة',
      'liveSubtitles': 'ترجمات مباشرة',
      'translatedSpeech': 'الكلام المترجم',
      'myMeetings': 'اجتماعاتي',
      'enterEmailPassword': 'أدخل بريدك الإلكتروني وكلمة المرور',
      'loginFailed': 'فشل تسجيل الدخول. يرجى المحاولة مرة أخرى.',
      'emailAddressLabel': 'أدخل عنوان بريدك الإلكتروني',
      'passwordLabel': 'أدخل كلمة المرور الخاصة بك',
      'forgetPassword': 'نسيت كلمة المرور؟',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Getters for convenience
  String get appName => translate('appName');
  String get appDescription => translate('appDescription');
  String get welcomeTitle => translate('welcomeTitle');
  String get welcomeDescription => translate('welcomeDescription');
  String get signUp => translate('signUp');
  String get login => translate('login');
  String get email => translate('email');
  String get password => translate('password');
  String get continueText => translate('continue');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

