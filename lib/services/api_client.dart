import 'package:dio/dio.dart';
import '../config/api_config.dart';

/// Single shared Dio instance; attaches the user header to every request.
class ApiClient {
  ApiClient._();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
    ),
  )..interceptors.addAll([
      InterceptorsWrapper(onRequest: (o, h) {
        o.headers['x-user-id'] = ApiConfig.currentUserId.toString();
        h.next(o);
      }),
      LogInterceptor(requestHeader: true, responseBody: true, error: true),
    ]);

  /// Turns any Dio error into a message that is safe to show in a SnackBar.
  static String messageFrom(Object e) {
    print('>>> API ERROR: $e');
    if (e is DioException) {
      print('>>> TYPE: ${e.type}  URL: ${e.requestOptions.uri}  INNER: ${e.error}');
      final data = e.response?.data;
      if (data is Map && data['error'] != null) return data['error'].toString();
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return 'Cannot reach the server. Is the backend running?';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}