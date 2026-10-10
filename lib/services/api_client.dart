import 'package:dio/dio.dart';
import '../config/api_config.dart';

/// Single shared Dio instance; attaches the user header to every request.
class ApiClient {
  ApiClient._();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60), // parsing can take a moment
    ),
  )..interceptors.add(
      InterceptorsWrapper(onRequest: (o, h) {
        o.headers['x-user-id'] = ApiConfig.currentUserId.toString();
        h.next(o);
      }),
    );

  /// Turns any Dio error into a message that is safe to show in a SnackBar.
  static String messageFrom(Object e) {
    if (e is DioException) {
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