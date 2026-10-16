
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.239.247.186:3000',
  );

  /// TEMP: id of the logged-in user (public."User".id).
  static int currentUserId = 1;
}