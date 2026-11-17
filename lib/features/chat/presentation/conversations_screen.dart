import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/regional_profile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/chat_repository.dart';
import '../../../shared/models/chat_models.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/sr_card.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key, this.standalone = false});

  /// true cuando se abre fuera de las pestañas (modo técnico).
  final bool standalone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(conversationsProvider);

    Future<void> refresh() async {
      ref.invalidate(conversationsProvider);
      await ref.read(conversationsProvider.future);
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: standalone,
        title: Text(l.chatTitle, style: standalone ? AppText.h2 : AppText.h1),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: refresh),
        data: (list) => list.isEmpty
            ? EmptyStateView(title: l.chatEmptyTitle, body: l.chatEmptyBody)
            : RefreshIndicator(
                color: SrRobotColors.primaryTeal,
                onRefresh: refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _ConversationTile(conv: list[i]),
                ),
              ),
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({required this.conv});
  final ConversationModel conv;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(regionProfileProvider).locale;
    final unread = conv.unread > 0;
    return SrCard(
      padding: const EdgeInsets.all(14),
      onTap: () async {
        await context.push(Routes.chatRoom(conv.id), extra: conv);
        ref.invalidate(conversationsProvider);
      },
      child: Row(
        children: [
          InitialsAvatar(initials: conv.initials, size: 50, seed: conv.counterpartUserId),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(conv.counterpartName,
                    style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  conv.lastMessage ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: unread
                      ? AppText.meta.copyWith(
                          color: SrRobotColors.textInk, fontWeight: FontWeight.w600)
                      : AppText.meta,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (conv.lastMessageAt != null)
                Text(DateFormatter.relative(conv.lastMessageAt!, locale),
                    style: AppText.small.copyWith(
                        color: unread
                            ? SrRobotColors.primaryTeal
                            : SrRobotColors.textGray)),
              const SizedBox(height: 6),
              if (unread)
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: SrRobotColors.primaryTeal,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${conv.unread}',
                      textAlign: TextAlign.center,
                      style: AppText.tag.copyWith(color: Colors.white)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Abre (o crea) el hilo con un técnico y redirige a la sala.
class StartChatScreen extends ConsumerStatefulWidget {
  const StartChatScreen({super.key, required this.technicianId});
  final String technicianId;

  @override
  ConsumerState<StartChatScreen> createState() => _StartChatScreenState();
}

class _StartChatScreenState extends ConsumerState<StartChatScreen> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      final conv = await ref
          .read(chatRepositoryProvider)
          .start(technicianId: widget.technicianId);
      if (!mounted) return;
      context.pushReplacement(Routes.chatRoom(conv.id), extra: conv);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: _error == null
          ? const LoadingView()
          : ErrorView(error: _error!, onRetry: _start),
    );
  }
}
