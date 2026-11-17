import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/env_config.dart';

/// Socket JSON `{ type, data }` con reconexión exponencial.
/// Se usa para `/chat/{id}` y `/events`.
class WebSocketService {
  WebSocketService({required this.path, required this.tokenProvider});

  final String path;
  final String? Function() tokenProvider;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _retryTimer;
  int _attempts = 0;
  bool _closed = false;

  Stream<Map<String, dynamic>> get events => _controller.stream;

  void connect() {
    _closed = false;
    // En modo demo no hay servidor de sockets; la app usa REST.
    if (EnvConfig.mockMode) return;
    final token = tokenProvider();
    if (token == null) return;
    final uri = Uri.parse(
        '${EnvConfig.wsHost}$path?token=${Uri.encodeQueryComponent(token)}');
    try {
      _channel = WebSocketChannel.connect(uri);
      _sub = _channel!.stream.listen(
        (raw) {
          _attempts = 0;
          try {
            final decoded = jsonDecode(raw as String);
            if (decoded is Map) {
              _controller.add(Map<String, dynamic>.from(decoded));
            }
          } catch (_) {/* mensaje no JSON: se ignora */}
        },
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void send(Map<String, dynamic> payload) {
    _channel?.sink.add(jsonEncode(payload));
  }

  void _scheduleReconnect() {
    if (_closed) return;
    _sub?.cancel();
    _attempts++;
    final exp = _attempts > 5 ? 5 : _attempts;
    final seconds = (1 << exp) > 30 ? 30 : (1 << exp);
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: seconds), connect);
  }

  Future<void> dispose() async {
    _closed = true;
    _retryTimer?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    await _controller.close();
  }
}
