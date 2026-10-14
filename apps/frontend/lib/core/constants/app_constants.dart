class AppConstants {
  static const String appName = 'Medicare Hospital & I.C.U';
  static const String appVersion = '1.0.0';
  static const String hospitalCode = 'MEDICARE-01';

  // Railway Backend API Endpoint
  // In release builds, point to your live Railway service.
  // In development, override with --dart-define=API_URL=http://localhost:3000/api/v1
  static const String defaultRailwayApiUrl =
      'https://hms-project-production-8bd9.up.railway.app/api/v1';
  static const String defaultLocalApiUrl = 'http://localhost:3000/api/v1';

  static String get apiBaseUrl {
    const customUrl = String.fromEnvironment('API_URL');
    if (customUrl.isNotEmpty) {
      return customUrl;
    }
    return defaultRailwayApiUrl;
  }
}
