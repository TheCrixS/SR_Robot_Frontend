import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env_config.dart';
import 'auth_interceptor.dart';
import 'mock/mock_backend.dart';
import 'token_storage.dart';

/// Error legible para la UI. `message` viene del backend cuando existe.
class ApiException implements Exception {
  final int? statusCode;
  final String? message;
  final bool isNetwork;

  const ApiException({this.statusCode, this.message, this.isNetwork = false});

  factory ApiException.from(Object e) {
    if (e is ApiException) return e;
    if (e is DioException) {
      final data = e.response?.data;
      final msg = data is Map ? data['message']?.toString() : null;
      final network = e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout;
      return ApiException(
        statusCode: e.response?.statusCode,
        message: msg,
        isNetwork: network,
      );
    }
    return const ApiException();
  }

  @override
  String toString() => message ?? 'ApiException($statusCode)';
}

/// Envoltura delgada sobre Dio que devuelve el cuerpo completo
/// (`{ success, data, meta, ... }`) como mapa.
class ApiClient {
  ApiClient(this.dio);
  final Dio dio;

  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? query}) =>
      _wrap(() => dio.get(path, queryParameters: _clean(query)));

  Future<Map<String, dynamic>> post(String path, {Object? data}) =>
      _wrap(() => dio.post(path, data: data));

  Future<Map<String, dynamic>> put(String path, {Object? data}) =>
      _wrap(() => dio.put(path, data: data));

  Future<Map<String, dynamic>> patch(String path, {Object? data}) =>
      _wrap(() => dio.patch(path, data: data));

  Future<Map<String, dynamic>> delete(String path, {Object? data}) =>
      _wrap(() => dio.delete(path, data: data));

  Map<String, dynamic>? _clean(Map<String, dynamic>? q) {
    if (q == null) return null;
    final out = <String, dynamic>{};
    q.forEach((k, v) {
      if (v == null) return;
      if (v is String && v.isEmpty) return;
      out[k] = v is bool ? v.toString() : v;
    });
    return out;
  }

  Future<Map<String, dynamic>> _wrap(
      Future<Response<dynamic>> Function() call) async {
    try {
      final res = await call();
      final body = res.data;
      if (body is Map) return Map<String, dynamic>.from(body);
      return {'data': body};
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}

/// Se dispara cuando el refresh falla; la capa de sesión escucha esto.
final sessionExpiredProvider = StateProvider<int>((ref) => 0);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: EnvConfig.apiBaseUrl,
    connectTimeout: EnvConfig.connectTimeout,
    receiveTimeout: EnvConfig.receiveTimeout,
    headers: {'Accept': 'application/json'},
  ));
  dio.interceptors.add(AuthInterceptor(
    ref.watch(tokenStorageProvider),
    dio,
    onSessionExpired: () =>
        ref.read(sessionExpiredProvider.notifier).state++,
  ));
  // Después del de auth para que el backend simulado vea el token.
  dio.interceptors.add(MockInterceptor(() => EnvConfig.mockMode));
  return dio;
});

final apiClientProvider =
    Provider<ApiClient>((ref) => ApiClient(ref.watch(dioProvider)));
