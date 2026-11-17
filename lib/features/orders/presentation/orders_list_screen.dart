import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/regional_profile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/config_repository.dart';
import '../../../shared/data/orders_repository.dart';
import '../../../shared/data/quotes_repository.dart';
import '../../../shared/models/order_model.dart';
import '../../../shared/models/quote_model.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/order_timeline.dart';
import '../../../shared/widgets/sr_card.dart';

class OrdersListScreen extends StatelessWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.ordersTitle, style: AppText.h1),
          bottom: TabBar(tabs: [Tab(text: l.ordersActive), Tab(text: l.ordersHistory)]),
        ),
        body: const TabBarView(
          children: [_OrdersTab(active: true), _OrdersTab(active: false)],
        ),
      ),
    );
  }
}

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final status = active ? 'active' : 'history';
    final orders = ref.watch(ordersListProvider(status));
    final requests = active
        ? ref.watch(myOpenQuoteRequestsProvider).valueOrNull ?? const []
        : const <QuoteRequestModel>[];

    Future<void> refresh() async {
      ref.invalidate(ordersListProvider(status));
      if (active) ref.invalidate(myOpenQuoteRequestsProvider);
      await ref.read(ordersListProvider(status).future);
    }

    return orders.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(error: e, onRetry: refresh),
      data: (list) {
        if (list.isEmpty && requests.isEmpty) {
          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              children: [
                const SizedBox(height: 40),
                EmptyStateView(
                  title: active ? l.ordersEmptyActive : l.ordersEmptyHistory,
                  body: l.ordersEmptyBody,
                  actionLabel: l.ordersFindTech,
                  onAction: () => context.go(Routes.clientSearch),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: SrRobotColors.primaryTeal,
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              if (requests.isNotEmpty) ...[
                Text(l.ordersOpenRequests, style: AppText.h3),
                const SizedBox(height: 10),
                for (final r in requests) ...[
                  _RequestCard(request: r),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 10),
              ],
              for (final o in list) ...[
                OrderCard(order: o),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});
  final QuoteRequestModel request;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SrCard(
      onTap: () => context.push(Routes.compareQuotes(request.id)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SrRobotColors.yellowAccent.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(emojiFor(request.deviceType),
                style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.brandModel,
                    style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                Text(request.issueDescription,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.small),
              ],
            ),
          ),
          SrTag(l.ordersQuotesCount(request.quotesCount),
              color: SrRobotColors.yellowAccent.withValues(alpha: 0.35),
              textColor: SrRobotColors.textInk),
        ],
      ),
    );
  }
}

/// Tarjeta de orden: equipo/servicio, fecha, total, técnico y estado.
class OrderCard extends ConsumerWidget {
  const OrderCard({super.key, required this.order, this.showClient = false});
  final OrderModel order;
  final bool showClient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(regionProfileProvider).locale;
    final o = order;
    return SrCard(
      onTap: () => context.push(Routes.order(o.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(o.serviceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
              ),
              OrderStatusBadge(o.state),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 16, color: SrRobotColors.textGray),
              const SizedBox(width: 4),
              Expanded(
                child: Text(showClient ? o.clientName : o.technicianName,
                    style: AppText.meta),
              ),
              if (o.createdAt != null)
                Text(DateFormatter.shortDate(o.createdAt!, locale),
                    style: AppText.small),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(o.isHomeService ? Icons.home_outlined : Icons.storefront_outlined,
                  size: 16, color: SrRobotColors.textGray),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                    o.isHomeService ? context.l10n.orderHome : context.l10n.orderShop,
                    style: AppText.small),
              ),
              Text(ref.money(o.amount),
                  style: AppText.bodyMedium.copyWith(
                      color: SrRobotColors.darkTeal, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}
