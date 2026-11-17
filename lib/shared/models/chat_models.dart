import 'json_utils.dart';

class ConversationModel {
  final String id;
  final String clientId;
  final String technicianId;
  final String counterpartUserId;
  final String counterpartName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unread;

  const ConversationModel({
    required this.id,
    required this.clientId,
    required this.technicianId,
    required this.counterpartUserId,
    required this.counterpartName,
    required this.unread,
    this.lastMessage,
    this.lastMessageAt,
  });

  String get initials {
    final parts = counterpartName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return (parts.first[0] + (parts.length > 1 ? parts[1][0] : ''))
        .toUpperCase();
  }

  factory ConversationModel.fromJson(Map<String, dynamic> j) {
    final cp = asMap(j['counterpart']);
    final last = j['lastMessage'];
    return ConversationModel(
      id: asId(j['id']),
      clientId: asId(j['clientId']),
      technicianId: asId(j['technicianId']),
      counterpartUserId: asId(cp['userId']),
      counterpartName: asStr(cp['name']) ?? '',
      lastMessage: last is Map ? asStr(last['text']) : asStr(last),
      lastMessageAt: asDate(j['lastMessageAt']),
      unread: asInt(j['unread']),
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String? text;
  final List<String> attachments;
  final List<String> readBy;
  final DateTime createdAt;
  final bool pending;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.attachments,
    required this.readBy,
    required this.createdAt,
    this.text,
    this.pending = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) {
    final atts = <String>[
      for (final a in (j['attachments'] as List? ?? const []))
        if (a is Map && a['url'] != null)
          a['url'].toString()
        else if (a is String)
          a,
      if (j['attachmentUrl'] != null) j['attachmentUrl'].toString(),
    ];
    return ChatMessage(
      id: asId(j['id']),
      conversationId: asId(j['conversationId']),
      senderId: asId(j['senderId']),
      text: asStr(j['text']),
      attachments: atts.toSet().toList(),
      readBy: asStrList(j['readBy']),
      createdAt: asDate(j['createdAt']) ?? DateTime.now(),
    );
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> metadata;
  final bool read;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.metadata,
    required this.read,
    this.createdAt,
  });

  NotificationModel copyWith({bool? read}) => NotificationModel(
        id: id,
        title: title,
        body: body,
        type: type,
        metadata: metadata,
        read: read ?? this.read,
        createdAt: createdAt,
      );

  factory NotificationModel.fromJson(Map<String, dynamic> j) =>
      NotificationModel(
        id: asId(j['id']),
        title: asStr(j['title']) ?? '',
        body: asStr(j['body']) ?? '',
        type: asStr(j['type']) ?? 'GENERAL',
        metadata: asMap(j['metadata']),
        read: asBool(j['read']),
        createdAt: asDate(j['createdAt']),
      );
}
