// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  static const String appName = 'EduAnalytics';
  static const String appVersion = '1.0.0';

  // API — oxirida / bo'lishi SHART (Dio uchun)
  // ⚠️ HTTPS serverda xatolik bo'lsa, malumot to'plash kerak (SSL sertifikat)
  static const String baseUrl =
      'https://eduanalytics.pythonanywhere.com/api/v1/';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'app_theme';
  static const String langKey = 'app_language';

  // Prediction Levels
  static const String highPerformance = 'High Performance';
  static const String mediumPerformance = 'Medium Performance';
  static const String lowPerformance = 'Low Performance';

  // Pagination
  static const int defaultPageSize = 20;

  // Score ranges
  static const double highScoreMin = 70.0;
  static const double mediumScoreMin = 40.0;
}
