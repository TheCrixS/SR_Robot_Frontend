import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/chat_models.dart';
import '../models/json_utils.dart';

class ChatRepository {
  ChatRepository(this._api);
  final ApiClient _api;

  Future<(List<ConversationModel>, int)> conversations() async {
    final body = await _api.get(ApiEndpoints.conversations);
    final list =
        asMapList(body['data']).map(ConversationModel.fromJson).toList();
    return (list, asInt(body['totalUnread']));
  }

  /// Crea o reutiliza el hilo con un técnico (cliente) o cliente (técnico).
  Future<ConversationModel> start({String? technicianId, String? clientId}) async {
    final body = await _api.post(ApiEndpoints.conversations, data: {
      if (technicianId != null)
        'technicianId': int.tryParse(technicianId) ?? technicianId,
      if (clientId != null) 'clientId': int.tryParse(clientId) ?? clientId,
    });
    return ConversationModel.fromJson(asMap(body['data']));
  }

  Future<List<ChatMessage>> messages(String conversationId) async {
    final body = await _api.get(ApiEndpoints.messages(conversationId),
        query: {'limit': 100});
    final list = asMapList(body['data']).map(ChatMessage.fromJson).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<ChatMessage> sendText(String conversationId, String text) async {
    final body = await _api.post(ApiEndpoints.messages(conversationId),
        data: {'text': text});
    return ChatMessage.fromJson(asMap(body['data']));
  }

  Future<ChatMessage> sendAttachments(
      String conversationId, List<String> paths, {String? text}) async {
    final form = FormData.fromMap({
      if (text != null && text.isNotEmpty) 'text': text,
      'attachments': [
        for (final p in paths)
          await MultipartFile.fromFile(p,
              filename: p.split(RegExp(r'[\\/]')).last),
      ],
    }, ListFormat.multiCompatible);
    final body =
        await _api.post(ApiEndpoints.messages(conversationId), data: form);
    return ChatMessage.fromJson(asMap(body['data']));
  }
}

final chatRepositoryProvider =
    Provider<ChatRepository>((ref) => ChatRepository(ref.watch(apiClientProvider)));

final conversationsProvider =
    FutureProvider.autoDispose<List<ConversationModel>>((ref) async {
  final (list, total) = await ref.watch(chatRepositoryProvider).conversations();
  ref.read(unreadMessagesProvider.notifier).state = total;
  return list;
});

/// Total de mensajes no leídos (insignia de la pestaña Mensajes).
final unreadMessagesProvider = StateProvider<int>((ref) => 0);
