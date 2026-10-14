class ApiConstants {
  /// Default Live Railway API endpoint, overrideable via --dart-define=API_BASE_URL=...
  static const String defaultLiveUrl =
      'https://hms-project-production-8bd9.up.railway.app/api/v1';

  static String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultLiveUrl,
  );

  static const String swaggerUrl =
      'https://hms-project-production-8bd9.up.railway.app/api/docs';
  static const String databaseEngine =
      'Supabase Cloud PostgreSQL (AWS Sydney)';
}
