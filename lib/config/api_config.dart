/// Backend connection settings.
/// Chrome: flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  /// TEMP: id of the logged-in user (public."User".id).
  static int currentUserId = 1;
}