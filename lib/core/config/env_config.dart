/// Configuración de entorno. Se puede sobrescribir al compilar:
/// flutter run --dart-define=API_HOST=https://mi-backend.com
class EnvConfig {
  EnvConfig._();

  static const String apiHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'https://sr-robot-backend.onrender.com',
  );

  /// Modo demo: el backend se simula en memoria (sin servidor).
  /// Se activa con --dart-define=MOCK=true o desde el login.
  static bool mockMode = const bool.fromEnvironment('MOCK');

  static String get apiBaseUrl => '$apiHost/api/v1';

  static String get wsHost => apiHost
      .replaceFirst('https://', 'wss://')
      .replaceFirst('http://', 'ws://');

  /// Convierte rutas relativas (`/uploads/x.jpg`) en URLs absolutas.
  static String? mediaUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '$apiHost$path';
  }

  /// Render (plan gratuito) puede tardar ~30 s en despertar.
  static const Duration connectTimeout = Duration(seconds: 45);
  static const Duration receiveTimeout = Duration(seconds: 45);
}
