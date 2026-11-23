import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/regional_profile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/notifications_repository.dart';
import '../../../shared/data/orders_repository.dart';
import '../../../shared/data/technician_work_repository.dart';
import '../../../shared/models/json_utils.dart';
import '../../../shared/models/order_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/media_picker.dart';
import '../../../shared/widgets/order_timeline.dart';
import '../../../shared/widgets/payment_selector.dart';
import '../../../shared/widgets/sr_card.dart';
import 'order_actions.dart';
import '../../../core/utils/money_input.dart';
import '../../../core/config/currency_spec.dart';

/// Vista del técnico de una orden: avanzar estados, subir evidencias
/// y pedir costos adicionales.
class OrderExecutionScreen extends ConsumerWidget {
  const OrderExecutionScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    ref.listen<Map<String, dynamic>?>(lastEventProvider, (_, e) {
      if (asId(asMap(e?['metadata'])['orderId']) == orderId) {
        ref.invalidate(orderDetailProvider(orderId));
      }
    });
    final async = ref.watch(orderDetailProvider(orderId));
    return Scaffold(
      appBar: AppBar(
        title: Text(l.execTitle(orderId)),
        actions: [
          IconButton(
            tooltip: l.techOpenMessages,
            onPressed: () => context.push(Routes.conversations),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
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
          child: _Body(order: o),
        ),
      ),
      bottomNavigationBar:
          async.hasValue ? _NextStepBar(order: async.value!) : null,
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final o = order;
    final locale = ref.watch(regionProfileProvider).locale;
    final working = o.state == OrderState.diagnostico ||
        o.state == OrderState.enReparacion;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        SrCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(o.serviceName, style: AppText.h3)),
                  OrderStatusBadge(o.state),
                ],
              ),
              const SizedBox(height: 8),
              Text('${l.execClient}: ${o.clientName}', style: AppText.body),
              if (o.address != null && o.address!.isNotEmpty)
                Text(o.address!, style: AppText.meta),
              const SizedBox(height: 8),
              SummaryRow(l.commonTotal, ref.money(o.amount, currency: o.currency), bold: true),
            ],
          ),
        ),
        if (o.pendingAdjustment != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SrRobotColors.yellowAccent.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
                l.execAdjPending(ref.money(o.pendingAdjustment!.amount,
                    currency: o.currency)),
                style: AppText.meta.copyWith(color: SrRobotColors.textInk)),
          ),
        ],
        const SizedBox(height: 20),
        Text(l.orderProgress, style: AppText.h2),
        const SizedBox(height: 12),
        SrCard(child: OrderTimeline(order: o, locale: locale)),
        if (working) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SrButton(
                  label: l.execEvidence,
                  icon: Icons.add_a_photo_outlined,
                  variant: SrButtonVariant.ghost,
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => _EvidenceSheet(orderId: o.id),
                  ),
                ),
              ),
              if (o.pendingAdjustment == null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: SrButton(
                    label: l.execAdjustment,
                    icon: Icons.price_change_outlined,
                    variant: SrButtonVariant.ghost,
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => _AdjustmentRequestSheet(orderId: o.id),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _NextStepBar extends ConsumerStatefulWidget {
  const _NextStepBar({required this.order});
  final OrderModel order;

  @override
  ConsumerState<_NextStepBar> createState() => _NextStepBarState();
}

class _NextStepBarState extends ConsumerState<_NextStepBar> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = widget.order.state;
    final bottom = MediaQuery.paddingOf(context).bottom;

    Widget content;
    if (s.step >= 0 && s.step < OrderState.listo.step) {
      final next = OrderState.sequence[s.step + 1];
      content = SrButton(
        label: l.execNext(next.label(l)),
        loading: _busy,
        onPressed: () async {
          setState(() => _busy = true);
          try {
            await advanceOrderTo(ref, widget.order.id, next);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l.execAdvanced)));
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(errorText(context, e))));
          } finally {
            if (mounted) setState(() => _busy = false);
          }
        },
      );
    } else if (s == OrderState.listo) {
      content = Text(l.execWaitingClient,
          textAlign: TextAlign.center, style: AppText.meta);
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      decoration: const BoxDecoration(
        color: SrRobotColors.surfaceWhite,
        border: Border(top: BorderSide(color: SrRobotColors.lineBorder)),
      ),
      child: content,
    );
  }
}

class _EvidenceSheet extends ConsumerStatefulWidget {
  const _EvidenceSheet({required this.orderId});
  final String orderId;

  @override
  ConsumerState<_EvidenceSheet> createState() => _EvidenceSheetState();
}

class _EvidenceSheetState extends ConsumerState<_EvidenceSheet> {
  List<String> _media = [];
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l = context.l10n;
    if (_media.isEmpty && _note.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(technicianWorkRepositoryProvider)
          .addEvidence(widget.orderId, _media, _note.text.trim());
      ref.invalidate(orderDetailProvider(widget.orderId));
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.execEvidenceSent)));
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.execEvidence, style: AppText.h2),
              const SizedBox(height: 12),
              MediaPickerField(
                  paths: _media, onChanged: (v) => setState(() => _media = v)),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                minLines: 2,
                maxLines: 3,
                style: AppText.body,
                decoration: InputDecoration(hintText: l.execEvidenceNote),
              ),
              const SizedBox(height: 16),
              SrButton(label: l.execEvidenceSend, loading: _busy, onPressed: _send),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdjustmentRequestSheet extends ConsumerStatefulWidget {
  const _AdjustmentRequestSheet({required this.orderId});
  final String orderId;

  @override
  ConsumerState<_AdjustmentRequestSheet> createState() =>
      _AdjustmentRequestSheetState();
}

class _AdjustmentRequestSheetState
    extends ConsumerState<_AdjustmentRequestSheet> {
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l = context.l10n;
    final amount = ref.read(regionProfileProvider).currency.toMinor(_amount.text) ?? 0;
    if (amount <= 0 || _reason.text.trim().isEmpty) {
      setState(() => _error = l.execInvalid);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(technicianWorkRepositoryProvider)
          .requestAdjustment(widget.orderId, amount, _reason.text.trim());
      ref.invalidate(orderDetailProvider(widget.orderId));
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.execAdjSent)));
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = errorText(context, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final region = ref.watch(regionProfileProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.execAdjustment, style: AppText.h2),
              const SizedBox(height: 12),
              TextField(
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: moneyInputFormatters(
                    ref.watch(regionProfileProvider).currency),
                style: AppText.body,
                decoration: InputDecoration(
                  hintText: l.execAdjAmount,
                  prefixText: '${region.currencySymbol} ',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _reason,
                style: AppText.body,
                decoration: InputDecoration(hintText: l.execAdjReason),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: AppText.meta.copyWith(color: SrRobotColors.alertRed)),
              ],
              const SizedBox(height: 16),
              SrButton(label: l.execAdjSend, loading: _busy, onPressed: _send),
            ],
          ),
        ),
      ),
    );
  }
}
