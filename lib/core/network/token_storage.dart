import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistencia segura del JWT y el refresh token.
/// Mantiene una copia en memoria para no leer el almacén en cada petición.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage(),
        _inMemory = false;

  /// Variante sin almacenamiento nativo (pruebas).
  TokenStorage.inMemory()
      : _storage = const FlutterSecureStorage(),
        _inMemory = true;

  final FlutterSecureStorage _storage;
  final bool _inMemory;
  static const _kToken = 'sr_token';
  static const _kRefresh = 'sr_refresh';

  String? _token;
  String? _refresh;
  bool _loaded = false;

  String? get token => _token;
  String? get refreshToken => _refresh;

  Future<void> load() async {
    if (_loaded) return;
    if (_inMemory) {
      _loaded = true;
      return;
    }
    _token = await _storage.read(key: _kToken);
    _refresh = await _storage.read(key: _kRefresh);
    _loaded = true;
  }

  Future<void> save(String token, String refreshToken) async {
    _token = token;
    _refresh = refreshToken;
    if (_inMemory) return;
    await _storage.write(key: _kToken, value: token);
    await _storage.write(key: _kRefresh, value: refreshToken);
  }

  Future<void> clear() async {
    _token = null;
    _refresh = null;
    if (_inMemory) return;
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kRefresh);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
