import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';
import '../../../shared/models/json_utils.dart';
import '../../../shared/models/user_model.dart';

/// Resultado de `POST /auth/otp`.
class OtpRequestResult {
  final int expiresInSeconds;
  final String? demoCode;
  const OtpRequestResult(this.expiresInSeconds, this.demoCode);
}

/// Identificador de acceso: celular o correo.
class LoginIdentifier {
  final String? phone;
  final String? email;
  const LoginIdentifier.phone(String this.phone) : email = null;
  const LoginIdentifier.email(String this.email) : phone = null;

  String get display => phone ?? email ?? '';
  Map<String, dynamic> toJson() =>
      phone != null ? {'phone': phone} : {'email': email};
}

class AuthRepository {
  AuthRepository(this._api, this._tokens);
  final ApiClient _api;
  final TokenStorage _tokens;

  Future<UserModel> _persist(Map<String, dynamic> body) async {
    final data = asMap(body['data']);
    await _tokens.save(
        data['token'] as String, data['refreshToken'] as String);
    return UserModel.fromJson(asMap(data['user']));
  }

  Future<OtpRequestResult> requestOtp(LoginIdentifier id) async {
    final body = await _api.post(ApiEndpoints.otp,
        data: {...id.toJson(), 'purpose': 'LOGIN'});
    final data = asMap(body['data']);
    return OtpRequestResult(
      asInt(body['expiresInSeconds'] ?? data['expiresInSeconds'], 300),
      asStr(body['otpCode'] ?? data['otpCode']),
    );
  }

  Future<UserModel> verifyOtp(LoginIdentifier id, String code) async =>
      _persist(await _api.post(ApiEndpoints.verifyOtp,
          data: {...id.toJson(), 'code': code}));

  Future<UserModel> loginWithPassword(
          LoginIdentifier id, String password, UserRole role) async =>
      _persist(await _api.post(ApiEndpoints.login, data: {
        ...id.toJson(),
        'password': password,
        'role': roleToApi(role),
      }));

  Future<UserModel> register({
    required String name,
    required LoginIdentifier id,
    required String password,
    required UserRole role,
    required String country,
    required String locale,
  }) async =>
      _persist(await _api.post(ApiEndpoints.register, data: {
        'name': name,
        ...id.toJson(),
        'password': password,
        'role': roleToApi(role),
        'acceptTerms': true,
        'country': country,
        'locale': locale,
      }));

  Future<UserModel?> me() async {
    await _tokens.load();
    if (_tokens.token == null) return null;
    final body = await _api.get(ApiEndpoints.me);
    return UserModel.fromJson(asMap(body['data']));
  }

  /// `PUT /auth/me`: devuelve el usuario actualizado (país, idioma…).
  Future<UserModel?> updateMe(Map<String, dynamic> fields) async {
    final body = await _api.put(ApiEndpoints.me, data: fields);
    final data = asMap(body['data']);
    return data.isEmpty ? null : UserModel.fromJson(data);
  }

  Future<UserModel> switchMode(UserRole role,
          {Map<String, dynamic>? businessData}) async =>
      _persist(await _api.post(ApiEndpoints.switchMode,
          data: {'role': roleToApi(role), ...?businessData}));

  Future<void> logout() async {
    final refresh = _tokens.refreshToken;
    try {
      if (refresh != null) {
        await _api.post(ApiEndpoints.logout, data: {'refreshToken': refresh});
      }
    } finally {
      await _tokens.clear();
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) =>
    AuthRepository(ref.watch(apiClientProvider), ref.watch(tokenStorageProvider)));
