import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env_config.dart';
import '../../../core/config/regional_profile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/notifications_repository.dart';
import '../../../shared/data/orders_repository.dart';
import '../../../shared/models/json_utils.dart';
import '../../../shared/models/order_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/order_timeline.dart';
import '../../../shared/widgets/payment_selector.dart';
import '../../../shared/widgets/robot_avatar.dart';
import '../../../shared/widgets/sr_card.dart';
import '../../auth/domain/session_controller.dart';
import '../../support/presentation/support_screens.dart';
import 'review_sheet.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    // Actualización en vivo: notificación con este orderId → recargar.
    ref.listen<Map<String, dynamic>?>(lastEventProvider, (_, e) {
      final meta = asMap(e?['metadata']);
      if (asId(meta['orderId']) == orderId) {
        ref.invalidate(orderDetailProvider(orderId));
      }
    });
    final async = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l.orderTitle(orderId)),
        actions: [
          if (async.valueOrNull != null && canDispute(async.value!.state))
            PopupMenuButton<String>(
              onSelected: (_) async {
                final ok = await showOpenDisputeSheet(context, orderId);
                if (ok == true && context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(l.disputeSent)));
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'dispute',
                  child: Row(
                    children: [
                      const Icon(Icons.report_gmailerrorred_outlined,
                          color: SrRobotColors.alertRed),
                      const SizedBox(width: 10),
                      Text(l.disputeReport),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
            error: e, onRetry: () => ref.invalidate(orderDetailProvider(orderId))),
        data: (o) => RefreshIndicator(
          color: SrRobotColors.primaryTeal,
          onRefresh: () async {
            ref.invalidate(orderDetailProvider(orderId));
            await ref.read(orderDetailProvider(orderId).future);
          },
          child: _OrderBody(order: o),
        ),
      ),
      bottomNavigationBar:
          async.hasValue ? _OrderActions(order: async.value!) : null,
    );
  }
}

class _OrderBody extends ConsumerWidget {
  const _OrderBody({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final o = order;
    final locale = ref.watch(regionProfileProvider).locale;
    final isClient = ref.watch(sessionProvider).isClientMode;
    final evidence = [for (final t in o.timeline) ...t.media];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        SrCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(o.serviceName,
                        style: AppText.h3),
                  ),
                  OrderStatusBadge(o.state),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  InitialsAvatar(
                    initials: _initials(isClient ? o.technicianName : o.clientName),
                    size: 36,
                    seed: isClient ? o.technicianId : o.clientName,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(isClient ? o.technicianName : o.clientName,
                        style: AppText.bodyMedium),
                  ),
                  SrTag(o.isHomeService ? l.orderHome : l.orderShop,
                      icon: o.isHomeService
                          ? Icons.home_outlined
                          : Icons.storefront_outlined),
                ],
              ),
              if (o.address != null && o.address!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(o.address!, style: AppText.meta),
              ],
            ],
          ),
        ),
        if (o.pendingAdjustment != null && isClient) ...[
          const SizedBox(height: 12),
          _AdjustmentBanner(order: o),
        ],
        const SizedBox(height: 20),
        Text(l.orderProgress, style: AppText.h2),
        const SizedBox(height: 12),
        SrCard(child: OrderTimeline(order: o, locale: locale)),
        if (evidence.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(l.orderEvidence, style: AppText.h2),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: evidence.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final url = EnvConfig.mediaUrl(evidence[i].url);
                if (url == null || evidence[i].type != 'IMAGE') {
                  return _MediaPlaceholder(isVideo: evidence[i].type == 'VIDEO');
                }
                return GestureDetector(
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => Dialog(
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: CachedNetworkImage(imageUrl: url),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          const _MediaPlaceholder(isVideo: false),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text(l.orderPayment, style: AppText.h2),
        const SizedBox(height: 10),
        SrCard(
          child: Column(
            children: [
              SummaryRow(l.scheduleServiceLine, ref.money(o.baseAmount)),
              if (o.homeFee > 0)
                SummaryRow(l.scheduleHomeLine, ref.money(o.homeFee)),
              if (o.adjustmentsTotal > 0)
                SummaryRow(l.orderAdjustments, ref.money(o.adjustmentsTotal)),
              if (o.platformFee > 0)
                SummaryRow(l.orderPlatformFee, ref.money(o.platformFee)),
              const Divider(height: 16),
              SummaryRow(l.commonTotal, ref.money(o.amount), bold: true),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(paymentIcon(o.paymentMethod),
                      size: 18, color: SrRobotColors.textGray),
                  const SizedBox(width: 6),
                  Text(paymentLabel(l, o.paymentMethod), style: AppText.meta),
                  const Spacer(),
                  SrTag(
                    o.escrowStatus == 'RELEASED'
                        ? l.orderEscrowReleased
                        : l.orderEscrowHeld,
                    icon: Icons.verified_user_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(l.orderWarranty, style: AppText.h2),
        const SizedBox(height: 10),
        SrCard(
          child: Row(
            children: [
              Icon(Icons.shield_outlined,
                  color: o.warrantyActive
                      ? SrRobotColors.primaryTeal
                      : SrRobotColors.textGray),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  o.warrantyActive && o.warrantyExpiresAt != null
                      ? l.orderWarrantyActive(
                          DateFormatter.shortDate(o.warrantyExpiresAt!, locale))
                      : l.orderWarrantyPending(o.warrantyDays),
                  style: AppText.body,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return (parts.first[0] + (parts.length > 1 ? parts[1][0] : '')).toUpperCase();
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({required this.isVideo});
  final bool isVideo;

  @override
  Widget build(BuildContext context) => Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: SrRobotColors.softTeal,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(isVideo ? Icons.videocam_outlined : Icons.image_outlined,
            color: SrRobotColors.primaryTeal),
      );
}

class _AdjustmentBanner extends ConsumerWidget {
  const _AdjustmentBanner({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final adj = order.pendingAdjustment!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SrRobotColors.yellowAccent.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: SrRobotColors.textInk),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.orderAdjustmentTitle,
                    style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                Text(l.orderAdjustmentBody(ref.money(adj.amount)),
                    style: AppText.meta.copyWith(color: SrRobotColors.textInk)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => _AdjustmentSheet(order: order),
            ),
            child: Text(l.orderAdjustmentReview,
                style: AppText.meta.copyWith(
                    color: SrRobotColors.textInk, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// Hoja de sobrecostos: aprobar o rechazar sin salir de la app.
class _AdjustmentSheet extends ConsumerStatefulWidget {
  const _AdjustmentSheet({required this.order});
  final OrderModel order;

  @override
  ConsumerState<_AdjustmentSheet> createState() => _AdjustmentSheetState();
}

class _AdjustmentSheetState extends ConsumerState<_AdjustmentSheet> {
  bool _busy = false;

  Future<void> _decide(bool approve) async {
    final l = context.l10n;
    final repo = ref.read(ordersRepositoryProvider);
    final adj = widget.order.pendingAdjustment!;
    setState(() => _busy = true);
    try {
      if (approve) {
        await repo.approveAdjustment(widget.order.id, adj.id);
      } else {
        await repo.rejectAdjustment(widget.order.id, adj.id);
      }
      ref.invalidate(orderDetailProvider(widget.order.id));
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              approve ? l.orderAdjustmentApproved : l.orderAdjustmentRejected)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(context, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final adj = widget.order.pendingAdjustment!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.orderAdjustmentTitle, style: AppText.h2),
            const SizedBox(height: 10),
            Text(adj.reason, style: AppText.body),
            const SizedBox(height: 14),
            SrCard(
              child: Column(
                children: [
                  SummaryRow(l.commonTotal, ref.money(widget.order.amount)),
                  SummaryRow('+', ref.money(adj.amount)),
                  const Divider(height: 16),
                  SummaryRow(l.commonTotal,
                      ref.money(widget.order.amount + adj.amount),
                      bold: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SrButton(
                    label: l.orderAdjustmentReject,
                    variant: SrButtonVariant.ghost,
                    onPressed: _busy ? null : () => _decide(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SrButton(
                    label: l.orderAdjustmentApprove,
                    loading: _busy,
                    onPressed: () => _decide(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderActions extends ConsumerStatefulWidget {
  const _OrderActions({required this.order});
  final OrderModel order;

  @override
  ConsumerState<_OrderActions> createState() => _OrderActionsState();
}

class _OrderActionsState extends ConsumerState<_OrderActions> {
  bool _busy = false;

  Future<void> _confirmReceipt() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RobotAvatar(size: 96),
            const SizedBox(height: 12),
            Text(l.orderConfirmTitle,
                textAlign: TextAlign.center, style: AppText.h3),
            const SizedBox(height: 6),
            Text(l.orderConfirmBody,
                textAlign: TextAlign.center, style: AppText.bodyGray),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(l.commonCancel)),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(l.commonConfirm,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(ordersRepositoryProvider).confirmReceipt(widget.order.id);
      ref.invalidate(orderDetailProvider(widget.order.id));
      ref.invalidate(activeOrderProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.orderConfirmed)));
      final sent = await showReviewSheet(context, widget.order.id);
      if (sent == true) _thanks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(context, e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _thanks() {
    ref.invalidate(orderDetailProvider(widget.order.id));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.reviewThanks)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final o = widget.order;
    final user = ref.watch(currentUserProvider);
    final isClient = user?.activeRole != UserRole.technician;

    final Widget? primary;
    if (isClient && o.state == OrderState.listo) {
      primary = SrButton(
          label: l.orderConfirmReceipt,
          loading: _busy,
          onPressed: _confirmReceipt);
    } else if (isClient && o.state == OrderState.entregado && !o.reviewed) {
      primary = SrButton(
        label: l.orderRate,
        variant: SrButtonVariant.yellow,
        onPressed: () async {
          final sent = await showReviewSheet(context, o.id);
          if (sent == true) _thanks();
        },
      );
    } else {
      primary = null;
    }

    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      decoration: const BoxDecoration(
        color: SrRobotColors.surfaceWhite,
        border: Border(top: BorderSide(color: SrRobotColors.lineBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SrButton(
              label: primary == null ? l.orderChat : '',
              icon: Icons.chat_bubble_outline_rounded,
              variant: SrButtonVariant.ghost,
              onPressed: () => isClient
                  ? context.push(Routes.chatWithTechnician(o.technicianId))
                  : context.push(Routes.conversations),
            ),
          ),
          if (primary != null) ...[
            const SizedBox(width: 10),
            Expanded(flex: 4, child: primary),
          ],
        ],
      ),
    );
  }
}
