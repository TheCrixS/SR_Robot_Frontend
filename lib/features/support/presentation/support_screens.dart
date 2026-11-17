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
import '../../../l10n/app_localizations.dart';
import '../../../shared/data/client_repository.dart';
import '../../../shared/data/orders_repository.dart';
import '../../../shared/models/order_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/media_picker.dart';
import '../../../shared/widgets/sr_card.dart';

/// Motivos predefinidos (texto visible) para abrir una disputa.
List<String> disputeReasons(AppLocalizations l) => [
      l.disputeReasonQuality,
      l.disputeReasonDamage,
      l.disputeReasonNoShow,
      l.disputeReasonPrice,
      l.disputeReasonOther,
    ];

/// Estados de orden en los que se puede abrir disputa.
bool canDispute(OrderState s) =>
    s.step >= 0 && s.step <= OrderState.listo.step;

// ---------------------------------------------------------------------------
// Lista de disputas
// ---------------------------------------------------------------------------

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(disputesProvider);
    final locale = ref.watch(regionProfileProvider).locale;
    return Scaffold(
      appBar: AppBar(title: Text(l.supportTitle)),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(disputesProvider)),
        data: (list) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SrRobotColors.softTeal,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.support_agent_outlined,
                      color: SrRobotColors.primaryTeal),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(l.supportHelp,
                          style: AppText.meta.copyWith(color: SrRobotColors.textInk))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (list.isEmpty)
              EmptyStateView(title: l.supportEmpty)
            else
              for (final d in list) ...[
                SrCard(
                  onTap: () => context.push(Routes.dispute(d.id)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.disputeOrder(d.orderId), style: AppText.small),
                            Text(d.reason,
                                style: AppText.bodyMedium
                                    .copyWith(fontWeight: FontWeight.w700)),
                            if (d.createdAt != null)
                              Text(DateFormatter.shortDate(d.createdAt!, locale),
                                  style: AppText.small),
                          ],
                        ),
                      ),
                      _StatusTag(open: d.isOpen),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.open});
  final bool open;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SrTag(
      open ? l.disputeOpen : l.disputeResolved,
      color: (open ? SrRobotColors.alertRed : SrRobotColors.lime)
          .withValues(alpha: 0.18),
      textColor: open ? SrRobotColors.alertRed : SrRobotColors.textInk,
    );
  }
}

// ---------------------------------------------------------------------------
// Detalle y seguimiento
// ---------------------------------------------------------------------------

class DisputeDetailScreen extends ConsumerStatefulWidget {
  const DisputeDetailScreen({super.key, required this.disputeId});
  final String disputeId;

  @override
  ConsumerState<DisputeDetailScreen> createState() =>
      _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends ConsumerState<DisputeDetailScreen> {
  final _note = TextEditingController();
  List<String> _media = [];
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _comment() async {
    if (_note.text.trim().isEmpty && _media.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(clientRepositoryProvider)
          .commentDispute(widget.disputeId, _note.text.trim(), media: _media);
      _note.clear();
      setState(() => _media = []);
      ref.invalidate(disputeProvider(widget.disputeId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorText(context, e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final async = ref.watch(disputeProvider(widget.disputeId));
    final locale = ref.watch(regionProfileProvider).locale;

    return Scaffold(
      appBar: AppBar(title: Text(l.disputeTitle)),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
            error: e,
            onRetry: () => ref.invalidate(disputeProvider(widget.disputeId))),
        data: (d) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            SrCard(
              onTap: () => context.push(Routes.order(d.orderId)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(l.disputeOrder(d.orderId), style: AppText.meta)),
                      _StatusTag(open: d.isOpen),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(d.reason, style: AppText.h3),
                  const SizedBox(height: 6),
                  Text(d.description, style: AppText.body),
                  if (d.media.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _MediaRow(media: d.media),
                  ],
                ],
              ),
            ),
            if (d.resolution != null) ...[
              const SizedBox(height: 12),
              SrCard(
                color: SrRobotColors.softTeal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.disputeResolution, style: AppText.h3),
                    const SizedBox(height: 4),
                    Text(d.resolution!, style: AppText.body),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(l.disputeUpdates, style: AppText.h2),
            const SizedBox(height: 10),
            for (final u in d.updates) ...[
              SrCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        if (u.author != null) u.author!,
                        if (u.createdAt != null)
                          '${DateFormatter.dayMonth(u.createdAt!, locale)} '
                              '${DateFormatter.time(u.createdAt!, locale)}',
                      ].join(' · '),
                      style: AppText.small,
                    ),
                    if (u.note != null && u.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(u.note!, style: AppText.body),
                    ],
                    if (u.media.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _MediaRow(media: u.media),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (d.isOpen) ...[
              const SizedBox(height: 12),
              Text(l.disputeAddComment, style: AppText.h3),
              const SizedBox(height: 10),
              TextField(
                controller: _note,
                minLines: 2,
                maxLines: 4,
                style: AppText.body,
                decoration: InputDecoration(hintText: l.disputeCommentHint),
              ),
              const SizedBox(height: 10),
              MediaPickerField(
                  paths: _media, onChanged: (v) => setState(() => _media = v)),
              const SizedBox(height: 12),
              SrButton(label: l.commonSend, loading: _busy, onPressed: _comment),
            ],
          ],
        ),
      ),
    );
  }
}

class _MediaRow extends StatelessWidget {
  const _MediaRow({required this.media});
  final List<MediaItem> media;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: media.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: EnvConfig.mediaUrl(media[i].url) ?? '',
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(
              width: 72,
              height: 72,
              color: SrRobotColors.softTeal,
              child: const Icon(Icons.insert_drive_file_outlined,
                  color: SrRobotColors.primaryTeal),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hoja para abrir una disputa desde la orden
// ---------------------------------------------------------------------------

Future<bool?> showOpenDisputeSheet(BuildContext context, String orderId) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OpenDisputeSheet(orderId: orderId),
    );

class _OpenDisputeSheet extends ConsumerStatefulWidget {
  const _OpenDisputeSheet({required this.orderId});
  final String orderId;

  @override
  ConsumerState<_OpenDisputeSheet> createState() => _OpenDisputeSheetState();
}

class _OpenDisputeSheetState extends ConsumerState<_OpenDisputeSheet> {
  String? _reason;
  final _desc = TextEditingController();
  List<String> _media = [];
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l10n;
    if (_reason == null || _desc.text.trim().isEmpty) {
      setState(() => _error = l.execInvalid);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(clientRepositoryProvider).openDispute(widget.orderId,
          reason: _reason!, description: _desc.text.trim(), media: _media);
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(disputesProvider);
      if (mounted) Navigator.pop(context, true);
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.disputeTitle, style: AppText.h2),
              const SizedBox(height: 12),
              Text(l.disputeReason, style: AppText.meta),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in disputeReasons(l))
                    SrFilterChip(
                      label: r,
                      selected: _reason == r,
                      onTap: () => setState(() => _reason = r),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _desc,
                minLines: 3,
                maxLines: 5,
                style: AppText.body,
                decoration: InputDecoration(hintText: l.disputeDescription),
              ),
              const SizedBox(height: 10),
              MediaPickerField(
                  paths: _media, onChanged: (v) => setState(() => _media = v)),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: AppText.meta.copyWith(color: SrRobotColors.alertRed)),
              ],
              const SizedBox(height: 16),
              SrButton(
                  label: l.disputeSubmit,
                  variant: SrButtonVariant.dark,
                  loading: _busy,
                  onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
