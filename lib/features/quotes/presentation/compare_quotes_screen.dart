import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/regional_profile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/orders_repository.dart';
import '../../../shared/data/quotes_repository.dart';
import '../../../shared/models/quote_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/payment_selector.dart';
import '../../../shared/widgets/robot_avatar.dart';
import '../../../shared/widgets/sr_card.dart';
import '../../../shared/data/config_repository.dart';

class CompareQuotesScreen extends ConsumerStatefulWidget {
  const CompareQuotesScreen({super.key, required this.requestId});
  final String requestId;

  @override
  ConsumerState<CompareQuotesScreen> createState() =>
      _CompareQuotesScreenState();
}

class _CompareQuotesScreenState extends ConsumerState<CompareQuotesScreen> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    // Mientras la solicitud está abierta, refrescamos cada 15 s.
    _poll = Timer.periodic(const Duration(seconds: 15), (_) {
      final r = ref.read(quotesProvider(widget.requestId)).valueOrNull;
      if (r == null || r.waiting) {
        ref.invalidate(quotesProvider(widget.requestId));
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _accept(QuoteModel q) async {
    final l = context.l10n;
    final method = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PaymentSheet(quote: q),
    );
    if (method == null || !mounted) return;
    try {
      final orderId = await ref
          .read(quotesRepositoryProvider)
          .accept(widget.requestId, q.id, method);
      if (!mounted) return;
      ref.invalidate(myOpenQuoteRequestsProvider);
      ref.invalidate(activeOrderProvider);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.compareAccepted)));
      context.pushReplacement(Routes.order(orderId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(context, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final async = ref.watch(quotesProvider(widget.requestId));
    final request =
        ref.watch(quoteRequestProvider(widget.requestId)).valueOrNull;
    final locale = ref.watch(regionProfileProvider).locale;

    return Scaffold(
      appBar: AppBar(title: Text(l.compareTitle)),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
            error: e,
            onRetry: () => ref.invalidate(quotesProvider(widget.requestId))),
        data: (r) {
          final header = request == null
              ? null
              : SrCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${categoryLabel(context.l10n, request.deviceType)} · ${request.brandModel}',
                                style: AppText.bodyMedium
                                    .copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(request.issueDescription,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.meta),
                          ],
                        ),
                      ),
                      if (r.expiresAt != null && r.waiting)
                        SrTag(l.compareExpires(
                            '${DateFormatter.dayMonth(r.expiresAt!, locale)} '
                            '${DateFormatter.time(r.expiresAt!, locale)}')),
                    ],
                  ),
                );

          if (r.quotes.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (header != null) header,
                const SizedBox(height: 40),
                if (r.waiting) ...[
                  const Center(child: RobotAvatar(size: 140)),
                  const SizedBox(height: 16),
                  Text(l.compareWaitingTitle,
                      textAlign: TextAlign.center, style: AppText.h3),
                  const SizedBox(height: 6),
                  Text(l.compareWaitingBody,
                      textAlign: TextAlign.center, style: AppText.bodyGray),
                  const SizedBox(height: 20),
                  const Center(
                    child: SizedBox(
                      width: 120,
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        color: SrRobotColors.primaryTeal,
                        backgroundColor: SrRobotColors.softTeal,
                      ),
                    ),
                  ),
                ] else
                  EmptyStateView(title: l.compareClosed),
              ],
            );
          }

          return RefreshIndicator(
            color: SrRobotColors.primaryTeal,
            onRefresh: () async {
              ref.invalidate(quotesProvider(widget.requestId));
              await ref.read(quotesProvider(widget.requestId).future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                if (header != null) ...[header, const SizedBox(height: 16)],
                if (r.quotes.length > 1) ...[
                  _ComparisonTable(quotes: r.quotes),
                  const SizedBox(height: 16),
                ],
                for (final q in r.quotes) ...[
                  _QuoteCard(
                    quote: q,
                    canAccept: r.waiting && q.status == 'PENDING',
                    onAccept: () => _accept(q),
                    onOpenTech: () =>
                        context.push(Routes.technician(q.technicianId)),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ComparisonTable extends ConsumerWidget {
  const _ComparisonTable({required this.quotes});
  final List<QuoteModel> quotes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    TableRow row(String label, List<String> values, {bool header = false}) =>
        TableRow(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(label,
                style: header
                    ? AppText.small.copyWith(fontWeight: FontWeight.w700)
                    : AppText.small),
          ),
          for (final v in values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(v,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: header
                      ? AppText.small.copyWith(
                          color: SrRobotColors.textInk,
                          fontWeight: FontWeight.w700)
                      : AppText.meta.copyWith(color: SrRobotColors.textInk)),
            ),
        ]);

    final shown = quotes.take(3).toList();
    return SrCard(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Table(
        columnWidths: const {0: FlexColumnWidth(1.1)},
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: const TableBorder(
            horizontalInside: BorderSide(color: SrRobotColors.lineBorder)),
        children: [
          row('', [for (final q in shown) q.technicianName], header: true),
          row(l.comparePrice, [for (final q in shown) ref.money(q.price, currency: q.currency)]),
          row(l.compareTime, [for (final q in shown) q.estimatedTime]),
          row(l.compareWarranty,
              [for (final q in shown) l.compareWarrantyMonths(q.warrantyDays)]),
          row(l.compareRating,
              [for (final q in shown) '★ ${q.technicianRating.toStringAsFixed(1)}']),
        ],
      ),
    );
  }
}

class _QuoteCard extends ConsumerWidget {
  const _QuoteCard({
    required this.quote,
    required this.canAccept,
    required this.onAccept,
    required this.onOpenTech,
  });

  final QuoteModel quote;
  final bool canAccept;
  final VoidCallback onAccept;
  final VoidCallback onOpenTech;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final q = quote;
    final initials = q.technicianName.isEmpty
        ? '?'
        : q.technicianName.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0]).join().toUpperCase();

    return SrCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (q.tags.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (q.isBestPrice)
                  SrTag(l.tagBestPrice,
                      color: SrRobotColors.lime.withValues(alpha: 0.25),
                      textColor: SrRobotColors.textInk,
                      icon: Icons.sell_outlined),
                if (q.isFastest)
                  SrTag(l.tagFastest,
                      color: SrRobotColors.infoBlue.withValues(alpha: 0.15),
                      textColor: SrRobotColors.infoBlue,
                      icon: Icons.bolt_rounded),
                if (q.isBestRated)
                  SrTag(l.tagBestRated,
                      color: SrRobotColors.starOrange.withValues(alpha: 0.15),
                      textColor: SrRobotColors.starOrange,
                      icon: Icons.star_rounded),
              ],
            ),
            const SizedBox(height: 12),
          ],
          InkWell(
            onTap: onOpenTech,
            child: Row(
              children: [
                InitialsAvatar(initials: initials, size: 44, seed: q.technicianId),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q.technicianName,
                          style: AppText.bodyMedium
                              .copyWith(fontWeight: FontWeight.w700)),
                      RatingLabel(q.technicianRating),
                    ],
                  ),
                ),
                Text(ref.money(q.price, currency: q.currency),
                    style: AppText.h3.copyWith(color: SrRobotColors.darkTeal)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Metric(Icons.schedule_rounded, q.estimatedTime),
              const SizedBox(width: 16),
              _Metric(Icons.shield_outlined, l.compareWarrantyMonths(q.warrantyDays)),
            ],
          ),
          if (q.message != null && q.message!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('“${q.message!}”', style: AppText.meta),
          ],
          if (canAccept) ...[
            const SizedBox(height: 14),
            SrButton(label: l.compareAccept, onPressed: onAccept),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: SrRobotColors.textGray),
          const SizedBox(width: 4),
          Text(text, style: AppText.meta),
        ],
      );
}

class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet({required this.quote});
  final QuoteModel quote;

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  String? _method;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final methods = ref.watch(paymentMethodsProvider).valueOrNull ??
        ref.watch(regionProfileProvider).availablePaymentMethods;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.compareChoosePayment, style: AppText.h2),
            const SizedBox(height: 14),
            PaymentSelector(
              methods: methods,
              selected: _method,
              onChanged: (m) => setState(() => _method = m),
            ),
            const SizedBox(height: 14),
            SummaryRow(l.commonTotal, ref.money(widget.quote.price, currency: widget.quote.currency), bold: true),
            const SizedBox(height: 10),
            const EscrowNote(),
            const SizedBox(height: 16),
            SrButton(
              label: l.compareAccept,
              onPressed:
                  _method == null ? null : () => Navigator.pop(context, _method),
            ),
          ],
        ),
      ),
    );
  }
}
