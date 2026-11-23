import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/business_repository.dart';
import '../../../shared/data/config_repository.dart';
import '../../../shared/data/technician_work_repository.dart';
import '../../../shared/models/quote_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/sr_card.dart';
import 'quote_submission_sheet.dart';

const _tabs = ['NEW', 'QUOTED', 'ACCEPTED'];

class TechnicianRequestsScreen extends ConsumerWidget {
  const TechnicianRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final counts =
        ref.watch(receivedRequestsProvider('NEW')).valueOrNull?.counts ?? const {};

    Tab tab(String label, String key) {
      final n = counts[key] ?? 0;
      return Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (n > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: key == 'NEW'
                      ? SrRobotColors.alertRed
                      : SrRobotColors.lineBorder,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$n',
                    style: AppText.tag.copyWith(
                        color: key == 'NEW' ? Colors.white : SrRobotColors.textInk)),
              ),
            ],
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.reqTitle, style: AppText.h1),
          bottom: TabBar(tabs: [
            tab(l.reqNew, 'NEW'),
            tab(l.reqQuoted, 'QUOTED'),
            tab(l.reqAccepted, 'ACCEPTED'),
          ]),
        ),
        body: TabBarView(
          children: [for (final t in _tabs) _RequestsList(status: t)],
        ),
      ),
    );
  }
}

class _RequestsList extends ConsumerWidget {
  const _RequestsList({required this.status});
  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(receivedRequestsProvider(status));

    Future<void> refresh() async {
      ref.invalidate(receivedRequestsProvider(status));
      await ref.read(receivedRequestsProvider(status).future);
    }

    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(error: e, onRetry: refresh),
      data: (r) => RefreshIndicator(
        color: SrRobotColors.primaryTeal,
        onRefresh: refresh,
        child: r.items.isEmpty
            ? ListView(children: [
                const SizedBox(height: 40),
                EmptyStateView(title: l.reqEmpty, body: l.reqEmptyBody),
              ])
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                itemCount: r.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) =>
                    RequestCard(request: r.items[i], actionable: status == 'NEW'),
              ),
      ),
    );
  }
}

/// Ficha de solicitud: equipo, distancia, urgencia, descripción y fotos.
class RequestCard extends ConsumerStatefulWidget {
  const RequestCard({super.key, required this.request, this.actionable = true});
  final QuoteRequestModel request;
  final bool actionable;

  @override
  ConsumerState<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<RequestCard> {
  bool _busy = false;

  void _refreshAll() {
    for (final t in _tabs) {
      ref.invalidate(receivedRequestsProvider(t));
    }
  }

  Future<void> _reject() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(l.reqRejectConfirm, style: AppText.body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(l.commonCancel)),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(l.reqReject,
                  style: const TextStyle(color: SrRobotColors.alertRed))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(technicianWorkRepositoryProvider).reject(widget.request.id);
      _refreshAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.reqRejected)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(context, e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _quote() async {
    final l = context.l10n;
    final me = ref.read(myBusinessProvider).valueOrNull;
    if (me != null && !me.canQuote) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.reqNeedVerification)));
      return;
    }
    final sent = await showQuoteSubmissionSheet(context, widget.request);
    if (sent == true) {
      _refreshAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.qsSent)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = widget.request;
    final (urgencyText, urgencyColor) = switch (r.urgency) {
      Urgency.high => (l.reqUrgencyHigh, SrRobotColors.alertRed),
      Urgency.low => (l.reqUrgencyLow, SrRobotColors.lime),
      Urgency.normal => (l.urgencyNormal, SrRobotColors.infoBlue),
    };
    final photos = r.media.where((m) => m.type == 'IMAGE').toList();

    return SrCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SrRobotColors.softTeal,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(emojiFor(r.deviceType),
                    style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.brandModel,
                        style: AppText.bodyMedium
                            .copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      [
                        categoryLabel(context.l10n, r.deviceType),
                        if (r.clientName != null) r.clientName!,
                        if (r.distanceKm != null)
                          l.commonKm(r.distanceKm!.toStringAsFixed(1)),
                      ].join(' · '),
                      style: AppText.small,
                    ),
                  ],
                ),
              ),
              SrTag(urgencyText,
                  color: urgencyColor.withValues(alpha: 0.15),
                  textColor: urgencyColor == SrRobotColors.lime
                      ? SrRobotColors.textInk
                      : urgencyColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(r.issueDescription, style: AppText.body),
          if (r.isHomeService) ...[
            const SizedBox(height: 8),
            SrTag(
              r.address == null ? l.reqHome : '${l.reqHome} · ${r.address}',
              icon: Icons.home_outlined,
            ),
          ],
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: EnvConfig.mediaUrl(photos[i].url) ?? '',
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                        width: 70, height: 70, color: SrRobotColors.softTeal),
                  ),
                ),
              ),
            ),
          ],
          if (r.myQuotePrice != null) ...[
            const SizedBox(height: 10),
            Text(l.reqYourQuote(ref.money(r.myQuotePrice!)),
                style: AppText.meta.copyWith(
                    color: SrRobotColors.darkTeal, fontWeight: FontWeight.w700)),
          ],
          if (widget.actionable) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SrButton(
                    label: l.reqReject,
                    variant: SrButtonVariant.ghost,
                    onPressed: _busy ? null : _reject,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SrButton(
                    label: l.reqSendQuote,
                    loading: _busy,
                    onPressed: _quote,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
