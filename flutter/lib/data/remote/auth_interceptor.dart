import 'package:dio/dio.dart';

/// Dio interceptor that attaches a Bearer token to every request and retries
/// once with a fresh token on 401 — mirrors AuthInterceptor.kt.
///
/// Uses callbacks instead of a direct AuthRepository reference to avoid a
/// circular dependency (Dio needs AuthInterceptor; AuthRepository needs Dio).
/// The [dio] instance is set after construction via [attachDio] because the
/// interceptor must be added to Dio before Dio is usable, but needs a
/// reference to Dio to issue the retry request.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Future<String?> Function() getToken,
    required Future<void> Function() invalidateToken,
  })  : _getToken = getToken,
        _invalidateToken = invalidateToken;

  final Future<String?> Function() _getToken;
  final Future<void> Function() _invalidateToken;
  late Dio _dio;

  /// Called by the Dio factory after the Dio instance is fully constructed.
  void attachDio(Dio dio) => _dio = dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only retry once — guard with a flag stored in requestOptions.extra.
    final alreadyRetried = err.requestOptions.extra['_authRetried'] == true;
    if (err.response?.statusCode == 401 && !alreadyRetried) {
      await _invalidateToken();
      final newToken = await _getToken();

      if (newToken != null) {
        final retryOptions = err.requestOptions
          ..headers['Authorization'] = 'Bearer $newToken'
          ..extra['_authRetried'] = true;

        try {
          final response = await _dio.fetch(retryOptions);
          handler.resolve(response);
          return;
        } on DioException catch (retryErr) {
          handler.next(retryErr);
          return;
        }
      }
    }

    handler.next(err);
  }
}
