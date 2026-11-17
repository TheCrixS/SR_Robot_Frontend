import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/regional_profile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/client_repository.dart';
import '../../../shared/data/config_repository.dart';
import '../../../shared/models/client_models.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/sr_card.dart';

/// Registro de equipos del cliente con su estado de garantía.
class MyDevicesScreen extends ConsumerWidget {
  const MyDevicesScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, [EquipmentModel? e]) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DeviceSheet(device: e),
    );
    if (ok == true) ref.invalidate(equipmentsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(equipmentsProvider);
    final locale = ref.watch(regionProfileProvider).locale;

    return Scaffold(
      appBar: AppBar(title: Text(l.devicesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: SrRobotColors.primaryTeal,
        foregroundColor: Colors.white,
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.devicesAdd),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(equipmentsProvider)),
        data: (list) => list.isEmpty
            ? EmptyStateView(title: l.devicesTitle, body: l.devicesEmpty)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final d = list[i];
                  final (wText, wColor) = switch (d.warrantyStatus) {
                    'ACTIVE' => (
                        l.devicesWarrantyActive(d.warrantyExpiresAt == null
                            ? ''
                            : DateFormatter.shortDate(d.warrantyExpiresAt!, locale)),
                        SrRobotColors.lime
                      ),
                    'EXPIRED' => (l.devicesWarrantyExpired, SrRobotColors.alertRed),
                    _ => (l.devicesNoWarranty, SrRobotColors.textGray),
                  };
                  return SrCard(
                    onTap: () => _edit(context, ref, d),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: SrRobotColors.softTeal,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(emojiFor(d.type),
                              style: const TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.title,
                                  style: AppText.bodyMedium
                                      .copyWith(fontWeight: FontWeight.w700)),
                              Text('${d.type} · ${d.brand} ${d.model}',
                                  style: AppText.small),
                              const SizedBox(height: 6),
                              SrTag(wText,
                                  icon: Icons.shield_outlined,
                                  color: wColor.withValues(alpha: 0.18),
                                  textColor: wColor == SrRobotColors.lime
                                      ? SrRobotColors.textInk
                                      : wColor),
                              if (d.lastServiceName != null) ...[
                                const SizedBox(height: 4),
                                Text(l.devicesLastService(d.lastServiceName!),
                                    style: AppText.small),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: l.quoteTitle,
                          onPressed: () => context.push(
                              Routes.requestQuote(category: d.type)),
                          icon: const Icon(Icons.request_quote_outlined,
                              color: SrRobotColors.primaryTeal),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _DeviceSheet extends ConsumerStatefulWidget {
  const _DeviceSheet({this.device});
  final EquipmentModel? device;

  @override
  ConsumerState<_DeviceSheet> createState() => _DeviceSheetState();
}

class _DeviceSheetState extends ConsumerState<_DeviceSheet> {
  late String? _type = widget.device?.type;
  late final _brand = TextEditingController(text: widget.device?.brand ?? '');
  late final _model = TextEditingController(text: widget.device?.model ?? '');
  late final _nick = TextEditingController(text: widget.device?.nickname ?? '');
  late DateTime? _purchase = widget.device?.purchaseDate;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _nick.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    if (_type == null || _brand.text.trim().isEmpty || _model.text.trim().isEmpty) {
      setState(() => _error = l.execInvalid);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(clientRepositoryProvider).saveEquipment(
            id: widget.device?.id,
            type: _type!,
            brand: _brand.text.trim(),
            model: _model.text.trim(),
            nickname: _nick.text.trim(),
            purchaseDate: _purchase,
          );
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

  Future<void> _delete() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(l.devicesDeleteConfirm, style: AppText.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.commonCancel)),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(l.commonDelete,
                  style: const TextStyle(color: SrRobotColors.alertRed))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(clientRepositoryProvider).deleteEquipment(widget.device!.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cats = ref.watch(categoriesProvider).valueOrNull ?? const <String>[];
    final locale = ref.watch(regionProfileProvider).locale;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.device == null ? l.devicesAdd : l.devicesEdit,
                  style: AppText.h2),
              const SizedBox(height: 12),
              Text(l.devicesType, style: AppText.meta),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in {...cats, if (_type != null) _type!})
                    SrFilterChip(
                      label: '${emojiFor(c)} $c',
                      selected: _type == c,
                      onTap: () => setState(() => _type = c),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                        controller: _brand,
                        style: AppText.body,
                        decoration: InputDecoration(labelText: l.devicesBrand)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                        controller: _model,
                        style: AppText.body,
                        decoration: InputDecoration(labelText: l.devicesModel)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                  controller: _nick,
                  style: AppText.body,
                  decoration: InputDecoration(labelText: l.devicesNickname)),
              const SizedBox(height: 10),
              SrCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                onTap: () async {
                  final now = DateTime.now();
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _purchase ?? now,
                    firstDate: DateTime(now.year - 15),
                    lastDate: now,
                  );
                  if (d != null) setState(() => _purchase = d);
                },
                child: Row(
                  children: [
                    const Icon(Icons.event_outlined, color: SrRobotColors.textGray),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _purchase == null
                            ? l.devicesPurchase
                            : DateFormatter.shortDate(_purchase!, locale),
                        style: _purchase == null ? AppText.bodyGray : AppText.body,
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: AppText.meta.copyWith(color: SrRobotColors.alertRed)),
              ],
              const SizedBox(height: 16),
              SrButton(label: l.commonSave, loading: _busy, onPressed: _save),
              if (widget.device != null) ...[
                const SizedBox(height: 10),
                SrButton(
                  label: l.devicesDelete,
                  variant: SrButtonVariant.ghost,
                  onPressed: _busy ? null : _delete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
