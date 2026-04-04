import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'auth_interceptor.dart';
import 'gmail_api_service.dart';

const _baseUrl = 'https://gmail.googleapis.com/';

/// Creates a fully-configured [GmailApiService] backed by a [Dio] instance.
/// Mirrors RetrofitProvider.kt.
///
/// [getToken] / [invalidateToken] are supplied by the Riverpod provider layer
/// (Phase 4) to wire in AuthRepository without a circular dependency.
GmailApiService createGmailApiService({
  required Future<String?> Function() getToken,
  required Future<void> Function() invalidateToken,
}) {
  final authInterceptor = AuthInterceptor(
    getToken: getToken,
    invalidateToken: invalidateToken,
  );

  final dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
    ),
  );

  // Auth interceptor needs the Dio instance to issue the 401 retry request.
  authInterceptor.attachDio(dio);
  dio.interceptors.add(authInterceptor);

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (o) => debugPrint(o.toString()),
      ),
    );
  }

  return GmailApiService(dio);
}
