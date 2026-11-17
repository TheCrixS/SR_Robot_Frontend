import 'dart:async';

import 'package:dio/dio.dart';

import '../config/env_config.dart';
import '../constants/api_endpoints.dart';
import 'token_storage.dart';

/// Inyecta `Authorization: Bearer <token>` y renueva el JWT ante un 401
/// usando el refresh token (que rota en cada uso).
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(this._storage, this._dio, {this.onSessionExpired});

  final TokenStorage _storage;
  final Dio _dio;
  final void Function()? onSessionExpired;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) {
    final token = _storage.token;
    if (token != null && options.headers['Authorization'] == null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final req = err.requestOptions;
    final isAuthCall = req.path.startsWith('/auth/');
    final alreadyRetried = req.extra['retried'] == true;

    if (err.response?.statusCode != 401 ||
        isAuthCall ||
        alreadyRetried ||
        _storage.refreshToken == null) {
      return handler.next(err);
    }

    try {
      final refreshDio = Dio(BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: EnvConfig.connectTimeout,
        receiveTimeout: EnvConfig.receiveTimeout,
      ));
      final res = await refreshDio.post(ApiEndpoints.refresh,
          data: {'refreshToken': _storage.refreshToken});
      final data = Map<String, dynamic>.from(res.data['data'] as Map);
      await _storage.save(
          data['token'] as String, data['refreshToken'] as String);

      req.headers['Authorization'] = 'Bearer ${data['token']}';
      req.extra['retried'] = true;
      final retry = await _dio.fetch<dynamic>(req);
      return handler.resolve(retry);
    } catch (_) {
      await _storage.clear();
      onSessionExpired?.call();
      return handler.next(err);
    }
  }
}
