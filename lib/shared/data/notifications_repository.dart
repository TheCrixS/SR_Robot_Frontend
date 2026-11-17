import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/token_storage.dart';
import '../../core/network/websocket_service.dart';
import '../../features/auth/domain/session_controller.dart';
import '../models/chat_models.dart';
import '../models/json_utils.dart';
import 'chat_repository.dart';

class NotificationsRepository {
  NotificationsRepository(this._api);
  final ApiClient _api;

  Future<(List<NotificationModel>, int)> list() async {
    final body =
        await _api.get(ApiEndpoints.notifications, query: {'limit': 50});
    return (
      asMapList(body['data']).map(NotificationModel.fromJson).toList(),
      asInt(body['unreadCount']),
    );
  }

  Future<void> markRead(String id) =>
      _api.patch('${ApiEndpoints.notifications}/$id/read');

  Future<void> readAll() => _api.post(ApiEndpoints.notificationsReadAll);
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
    (ref) => NotificationsRepository(ref.watch(apiClientProvider)));

final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final (list, unread) =
      await ref.watch(notificationsRepositoryProvider).list();
  ref.read(unreadNotificationsProvider.notifier).state = unread;
  return list;
});

/// Insignia de la campana.
final unreadNotificationsProvider = StateProvider<int>((ref) => 0);

/// Último evento de dominio recibido por `/events` (para refrescar pantallas).
final lastEventProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

/// Socket global `/events`: vive mientras hay sesión y se reabre al
/// cambiar de token (por ejemplo, al alternar de modo).
final eventsSocketProvider = Provider<WebSocketService?>((ref) {
  final session = ref.watch(sessionProvider);
  if (session.status != SessionStatus.authenticated) return null;
  final tokens = ref.watch(tokenStorageProvider);

  final ws = WebSocketService(path: '/events', tokenProvider: () => tokens.token);
  final StreamSubscription<Map<String, dynamic>> sub = ws.events.listen((e) {
    final type = e['type'];
    final data = asMap(e['data']);
    switch (type) {
      case 'notification':
        ref.read(unreadNotificationsProvider.notifier).state++;
        ref.read(lastEventProvider.notifier).state = data;
      case 'unread':
        ref.read(unreadMessagesProvider.notifier).state =
            asInt(data['total'], ref.read(unreadMessagesProvider));
    }
  });
  ws.connect();

  ref.onDispose(() {
    sub.cancel();
    ws.dispose();
  });
  return ws;
});
