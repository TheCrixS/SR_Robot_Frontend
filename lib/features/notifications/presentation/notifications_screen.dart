import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/regional_profile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/notifications_repository.dart';
import '../../../shared/models/chat_models.dart';
import '../../../shared/models/json_utils.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/sr_card.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(notificationsProvider);

    Future<void> refresh() async {
      ref.invalidate(notificationsProvider);
      await ref.read(notificationsProvider.future);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.notificationsTitle),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationsRepositoryProvider).readAll();
              ref.read(unreadNotificationsProvider.notifier).state = 0;
              ref.invalidate(notificationsProvider);
            },
            child: Text(l.notificationsReadAll,
                style: AppText.meta.copyWith(
                    color: SrRobotColors.primaryTeal,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: refresh),
        data: (list) => list.isEmpty
            ? EmptyStateView(title: l.notificationsEmpty)
            : RefreshIndicator(
                color: SrRobotColors.primaryTeal,
                onRefresh: refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _NotificationTile(n: list[i]),
                ),
              ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.n});
  final NotificationModel n;

  IconData get _icon => switch (n.type) {
        'QUOTE' => Icons.request_quote_outlined,
        'APPOINTMENT' => Icons.event_available_outlined,
        'ORDER' => Icons.build_circle_outlined,
        'ADJUSTMENT' => Icons.price_change_outlined,
        'MESSAGE' => Icons.chat_bubble_outline_rounded,
        'REVIEW' => Icons.star_outline_rounded,
        'SUBSCRIPTION' => Icons.workspace_premium_outlined,
        'SUPPLIER_ORDER' => Icons.local_shipping_outlined,
        'DISPUTE' => Icons.gavel_outlined,
        'VERIFICATION' => Icons.verified_outlined,
        _ => Icons.notifications_none_rounded,
      };

  /// Navega según los ids que trae `metadata`.
  void _open(BuildContext context) {
    final m = n.metadata;
    final orderId = asStr(m['orderId']);
    final requestId = asStr(m['requestId']);
    final conversationId = asStr(m['conversationId']);
    final disputeId = asStr(m['disputeId']);
    if (disputeId != null) {
      context.push(Routes.dispute(disputeId));
    } else if (orderId != null) {
      context.push(Routes.order(orderId));
    } else if (conversationId != null) {
      context.push(Routes.chatRoom(conversationId));
    } else if (requestId != null) {
      context.push(Routes.compareQuotes(requestId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(regionProfileProvider).locale;
    return SrCard(
      padding: const EdgeInsets.all(14),
      color: n.read ? SrRobotColors.surfaceWhite : SrRobotColors.softTeal,
      onTap: () {
        if (!n.read) {
          ref.read(notificationsRepositoryProvider).markRead(n.id).ignore();
          final c = ref.read(unreadNotificationsProvider);
          if (c > 0) ref.read(unreadNotificationsProvider.notifier).state = c - 1;
        }
        _open(context);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: SrRobotColors.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: SrRobotColors.primaryTeal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.title,
                    style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(n.body, style: AppText.meta),
              ],
            ),
          ),
          if (n.createdAt != null)
            Text(DateFormatter.relative(n.createdAt!, locale), style: AppText.small),
        ],
      ),
    );
  }
}
