import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/regional_profile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/business_repository.dart';
import '../../../shared/data/quotes_repository.dart';
import '../../../shared/models/business_models.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/payment_selector.dart';
import '../../../shared/widgets/sr_card.dart';

/// Planes Básico / Pro / Premium con renovación y cambio de plan.
class SubscriptionPlansScreen extends ConsumerWidget {
  const SubscriptionPlansScreen({super.key});

  Future<void> _choose(BuildContext context, WidgetRef ref, PlanModel plan) async {
    final l = context.l10n;
    final repo = ref.read(businessRepositoryProvider);
    try {
      if (plan.price == 0) {
        await repo.cancelSubscription();
      } else {
        final method = await showModalBottomSheet<String>(
          context: context,
          builder: (_) => _PlanPaymentSheet(plan: plan),
        );
        if (method == null) return;
        await repo.changePlan(plan.code, method);
      }
      ref.invalidate(mySubscriptionProvider);
      ref.invalidate(myBusinessProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.subChanged)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(context, e))));
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(l.subCancelConfirm, style: AppText.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.commonClose)),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(l.subCancel,
                  style: const TextStyle(color: SrRobotColors.alertRed))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(businessRepositoryProvider).cancelSubscription();
      ref.invalidate(mySubscriptionProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(context, e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final plans = ref.watch(plansProvider);
    final mine = ref.watch(mySubscriptionProvider).valueOrNull;
    final locale = ref.watch(regionProfileProvider).locale;

    return Scaffold(
      appBar: AppBar(title: Text(l.subTitle)),
      body: plans.when(
        loading: () => const LoadingView(),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(plansProvider)),
        data: (list) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            if (mine != null && mine.nextBillingDate != null && mine.plan != 'BASIC')
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  mine.cancelAtPeriodEnd
                      ? l.subEnds(DateFormatter.shortDate(mine.nextBillingDate!, locale))
                      : l.subRenews(DateFormatter.shortDate(mine.nextBillingDate!, locale)),
                  style: AppText.meta,
                ),
              ),
            for (final p in list) ...[
              _PlanCard(
                plan: p,
                current: mine?.plan == p.code,
                onChoose: () => _choose(context, ref, p),
              ),
              const SizedBox(height: 12),
            ],
            if (mine != null && mine.plan != 'BASIC' && !mine.cancelAtPeriodEnd)
              TextButton(
                onPressed: () => _cancel(context, ref),
                child: Text(l.subCancel,
                    style: AppText.meta.copyWith(color: SrRobotColors.alertRed)),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard(
      {required this.plan, required this.current, required this.onChoose});
  final PlanModel plan;
  final bool current;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final highlight = plan.code == 'PRO';
    final dark = plan.code == 'PREMIUM';
    final fg = dark ? Colors.white : SrRobotColors.textInk;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: highlight ? SrRobotColors.brandGradient : null,
        color: highlight
            ? null
            : dark
                ? SrRobotColors.textInk
                : SrRobotColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: current
            ? Border.all(color: SrRobotColors.yellowAccent, width: 2.5)
            : null,
        boxShadow: SrRobotColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(plan.name,
                    style: AppText.h2.copyWith(
                        color: highlight || dark ? Colors.white : fg)),
              ),
              if (current)
                SrTag(l.subCurrent,
                    color: SrRobotColors.yellowAccent,
                    textColor: SrRobotColors.textInk),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            plan.price == 0
                ? l.commonFree
                : l.subPerMonth(ref.money(plan.price)),
            style: AppText.h1.copyWith(color: highlight || dark ? Colors.white : fg),
          ),
          const SizedBox(height: 10),
          for (final f in [
            plan.maxQuotes == null || plan.maxQuotes! <= 0
                ? l.subUnlimited
                : l.subMaxQuotes(plan.maxQuotes!),
            if (plan.discountSpareParts > 0)
              l.subPartsDiscount((plan.discountSpareParts * 100).toStringAsFixed(0)),
            ...plan.features,
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_rounded,
                      size: 18,
                      color: highlight || dark ? Colors.white : SrRobotColors.primaryTeal),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(f,
                        style: AppText.meta.copyWith(
                            color: highlight || dark ? Colors.white : fg)),
                  ),
                ],
              ),
            ),
          if (!current) ...[
            const SizedBox(height: 14),
            SrButton(
              label: l.subChoose,
              variant: highlight
                  ? SrButtonVariant.dark
                  : dark
                      ? SrButtonVariant.yellow
                      : SrButtonVariant.primary,
              onPressed: onChoose,
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanPaymentSheet extends ConsumerStatefulWidget {
  const _PlanPaymentSheet({required this.plan});
  final PlanModel plan;

  @override
  ConsumerState<_PlanPaymentSheet> createState() => _PlanPaymentSheetState();
}

class _PlanPaymentSheetState extends ConsumerState<_PlanPaymentSheet> {
  String? _method;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Las suscripciones no se pagan en efectivo.
    final methods = (ref.watch(paymentMethodsProvider).valueOrNull ??
            ref.watch(regionProfileProvider).availablePaymentMethods)
        .where((m) => m != 'CASH')
        .toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.subPayTitle, style: AppText.h2),
            const SizedBox(height: 14),
            PaymentSelector(
                methods: methods,
                selected: _method,
                onChanged: (m) => setState(() => _method = m)),
            const SizedBox(height: 14),
            SrCard(
              child: SummaryRow(widget.plan.name,
                  l.subPerMonth(ref.money(widget.plan.price)),
                  bold: true),
            ),
            const SizedBox(height: 16),
            SrButton(
              label: l.commonConfirm,
              onPressed: _method == null ? null : () => Navigator.pop(context, _method),
            ),
          ],
        ),
      ),
    );
  }
}
