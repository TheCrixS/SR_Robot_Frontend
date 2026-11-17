import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/env_config.dart';
import '../../../core/config/regional_profile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/chat_repository.dart';
import '../../../shared/models/chat_models.dart';
import '../../../shared/models/json_utils.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/sr_card.dart';
import '../../auth/domain/session_controller.dart';

/// Sala de chat: historial por REST + tiempo real por WebSocket
/// (mensajes, "Escribiendo…" y confirmaciones de lectura).
class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({super.key, required this.conversationId, this.conversation});
  final String conversationId;
  final ConversationModel? conversation;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _messages = <ChatMessage>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  WebSocketService? _ws;
  StreamSubscription<Map<String, dynamic>>? _sub;
  bool _loading = true;
  Object? _error;
  bool _otherTyping = false;
  Timer? _typingOff;
  Timer? _typingDebounce;
  bool _iAmTyping = false;
  bool _sending = false;

  ConversationModel? get _conv =>
      widget.conversation ??
      ref
          .read(conversationsProvider)
          .valueOrNull
          ?.where((c) => c.id == widget.conversationId)
          .firstOrNull;

  String get _myId => ref.read(currentUserProvider)?.id ?? '';

  @override
  void initState() {
    super.initState();
    _load();
    _connect();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list =
          await ref.read(chatRepositoryProvider).messages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(list);
        _loading = false;
      });
      _jumpToEnd();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  void _connect() {
    final tokens = ref.read(tokenStorageProvider);
    _ws = WebSocketService(
      path: '/chat/${widget.conversationId}',
      tokenProvider: () => tokens.token,
    );
    _sub = _ws!.events.listen(_onEvent);
    _ws!.connect();
  }

  void _onEvent(Map<String, dynamic> e) {
    final data = asMap(e['data']);
    switch (e['type']) {
      case 'connected':
        _ws?.send({'type': 'read'});
      case 'message':
        final msg = ChatMessage.fromJson(data.isEmpty ? e : data);
        if (_messages.any((m) => m.id == msg.id)) return;
        setState(() {
          _messages.add(msg);
          _otherTyping = false;
        });
        if (msg.senderId != _myId) _ws?.send({'type': 'read'});
        _jumpToEnd();
      case 'typing':
        if (asId(data['userId']) == _myId) return;
        setState(() => _otherTyping = asBool(data['isTyping']));
        _typingOff?.cancel();
        if (_otherTyping) {
          _typingOff = Timer(const Duration(seconds: 6), () {
            if (mounted) setState(() => _otherTyping = false);
          });
        }
      case 'read':
        final reader = asId(data['userId']);
        if (reader == _myId) return;
        setState(() {
          for (var i = 0; i < _messages.length; i++) {
            final m = _messages[i];
            if (m.senderId == _myId && !m.readBy.contains(reader)) {
              _messages[i] = ChatMessage(
                id: m.id,
                conversationId: m.conversationId,
                senderId: m.senderId,
                text: m.text,
                attachments: m.attachments,
                readBy: [...m.readBy, reader],
                createdAt: m.createdAt,
              );
            }
          }
        });
    }
  }

  void _onInput(String v) {
    if (!_iAmTyping && v.isNotEmpty) {
      _iAmTyping = true;
      _ws?.send({'type': 'typing', 'isTyping': true});
    }
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      if (_iAmTyping) {
        _iAmTyping = false;
        _ws?.send({'type': 'typing', 'isTyping': false});
      }
    });
    setState(() {});
  }

  Future<void> _sendText() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    final tempId = 'tmp-${DateTime.now().microsecondsSinceEpoch}';
    final temp = ChatMessage(
      id: tempId,
      conversationId: widget.conversationId,
      senderId: _myId,
      text: text,
      attachments: const [],
      readBy: const [],
      createdAt: DateTime.now(),
      pending: true,
    );
    setState(() {
      _messages.add(temp);
      _input.clear();
    });
    _jumpToEnd();
    _iAmTyping = false;
    _ws?.send({'type': 'typing', 'isTyping': false});
    try {
      final sent =
          await ref.read(chatRepositoryProvider).sendText(widget.conversationId, text);
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.id == tempId);
        if (!_messages.any((m) => m.id == sent.id)) _messages.add(sent);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _messages.removeWhere((m) => m.id == tempId));
      _input.text = text;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(context, e))));
    }
  }

  Future<void> _sendPhoto() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 1600);
    if (picked == null) return;
    setState(() => _sending = true);
    try {
      final sent = await ref
          .read(chatRepositoryProvider)
          .sendAttachments(widget.conversationId, [picked.path]);
      if (!mounted) return;
      setState(() {
        if (!_messages.any((m) => m.id == sent.id)) _messages.add(sent);
      });
      _jumpToEnd();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(context, e))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _typingOff?.cancel();
    _typingDebounce?.cancel();
    _sub?.cancel();
    _ws?.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final conv = _conv;
    final locale = ref.watch(regionProfileProvider).locale;
    final otherId = conv?.counterpartUserId;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            InitialsAvatar(
                initials: conv?.initials ?? '?', size: 38, seed: otherId),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(conv?.counterpartName ?? '',
                      style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                  if (_otherTyping)
                    Text(l.chatTyping,
                        style: AppText.small
                            .copyWith(color: SrRobotColors.primaryTeal)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? ErrorView(error: _error!, onRetry: _load)
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final m = _messages[i];
                          final prev = i > 0 ? _messages[i - 1] : null;
                          final newDay = prev == null ||
                              prev.createdAt.day != m.createdAt.day ||
                              prev.createdAt.month != m.createdAt.month;
                          return Column(
                            children: [
                              if (newDay)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Text(
                                      DateFormatter.shortDate(m.createdAt, locale),
                                      style: AppText.small),
                                ),
                              _Bubble(
                                message: m,
                                mine: m.senderId == _myId,
                                read: otherId != null && m.readBy.contains(otherId),
                                locale: locale,
                              ),
                            ],
                          );
                        },
                      ),
          ),
          _Composer(
            controller: _input,
            sending: _sending,
            onChanged: _onInput,
            onSend: _sendText,
            onPhoto: _sendPhoto,
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.read,
    required this.locale,
  });

  final ChatMessage message;
  final bool mine;
  final bool read;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final fg = mine ? Colors.white : SrRobotColors.textInk;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(
          color: mine ? SrRobotColors.primaryTeal : SrRobotColors.surfaceWhite,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
          boxShadow: SrRobotColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final a in message.attachments)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: EnvConfig.mediaUrl(a) ?? a,
                    width: 200,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        Icon(Icons.image_not_supported_outlined, color: fg),
                  ),
                ),
              ),
            if (message.text != null && message.text!.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(message.text!, style: AppText.body.copyWith(color: fg)),
              ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(DateFormatter.time(message.createdAt, locale),
                    style: AppText.tag.copyWith(
                        color: mine
                            ? Colors.white.withValues(alpha: 0.8)
                            : SrRobotColors.textGray,
                        fontWeight: FontWeight.w400)),
                if (mine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.pending
                        ? Icons.schedule_rounded
                        : (read ? Icons.done_all_rounded : Icons.done_rounded),
                    size: 14,
                    color: read
                        ? SrRobotColors.yellowAccent
                        : Colors.white.withValues(alpha: 0.85),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onChanged,
    required this.onSend,
    required this.onPhoto,
  });

  final TextEditingController controller;
  final bool sending;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final VoidCallback onPhoto;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final hasText = controller.text.trim().isNotEmpty;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + bottom),
      decoration: const BoxDecoration(
        color: SrRobotColors.surfaceWhite,
        border: Border(top: BorderSide(color: SrRobotColors.lineBorder)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: sending ? null : onPhoto,
            icon: sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.photo_camera_outlined,
                    color: SrRobotColors.textGray),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              minLines: 1,
              maxLines: 4,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              style: AppText.body,
              decoration: InputDecoration(
                counterText: '',
                hintText: context.l10n.chatInputHint,
                fillColor: SrRobotColors.background,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: hasText ? SrRobotColors.primaryTeal : SrRobotColors.lineBorder,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: hasText ? onSend : null,
              child: const Padding(
                padding: EdgeInsets.all(11),
                child: Icon(Icons.send_rounded, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
