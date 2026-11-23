import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/regional_profile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/business_repository.dart';
import '../../../shared/models/technician_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/sr_card.dart';
import '../../../core/utils/money_input.dart';
import '../../../core/config/currency_spec.dart';

/// Catálogo de servicios y precios base del técnico.
class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, [TechService? s]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ServiceSheet(service: s),
    );
    if (saved == true) {
      ref.invalidate(myServicesProvider);
      ref.invalidate(myBusinessProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(myServicesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.bizServices)),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: SrRobotColors.primaryTeal,
        foregroundColor: Colors.white,
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.bizServiceNew),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(myServicesProvider)),
        data: (list) => list.isEmpty
            ? EmptyStateView(title: l.techNoServices)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final s = list[i];
                  return Opacity(
                    opacity: s.active ? 1 : 0.55,
                    child: SrCard(
                      onTap: () => _edit(context, ref, s),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name,
                                    style: AppText.bodyMedium
                                        .copyWith(fontWeight: FontWeight.w600)),
                                Text(
                                  [
                                    if (s.estimatedTime.isNotEmpty) s.estimatedTime,
                                    l.techWarrantyDays(s.warrantyDays),
                                    if (!s.active) l.bizServiceInactive,
                                  ].join(' · '),
                                  style: AppText.small,
                                ),
                              ],
                            ),
                          ),
                          Text(ref.money(s.priceFrom),
                              style: AppText.bodyMedium.copyWith(
                                  color: SrRobotColors.darkTeal,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _ServiceSheet extends ConsumerStatefulWidget {
  const _ServiceSheet({this.service});
  final TechService? service;

  @override
  ConsumerState<_ServiceSheet> createState() => _ServiceSheetState();
}

class _ServiceSheetState extends ConsumerState<_ServiceSheet> {
  late final _name = TextEditingController(text: widget.service?.name ?? '');
  late final _price = TextEditingController(
      text: widget.service == null
          ? ''
          : ref.read(regionProfileProvider).currency.toInput(widget.service!.priceFrom));
  late final _time =
      TextEditingController(text: widget.service?.estimatedTime ?? '');
  late final _warranty =
      TextEditingController(text: '${widget.service?.warrantyDays ?? 90}');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _price, _time, _warranty]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save({bool? active}) async {
    final l = context.l10n;
    final price = ref.read(regionProfileProvider).currency.toMinor(_price.text) ?? 0;
    if (_name.text.trim().isEmpty || price <= 0) {
      setState(() => _error = l.execInvalid);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(businessRepositoryProvider).saveService(
            id: widget.service?.id,
            name: _name.text.trim(),
            priceFrom: price,
            estimatedTime: _time.text.trim(),
            warrantyDays: int.tryParse(_warranty.text) ?? 90,
            active: active,
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

  Future<void> _deactivate() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(businessRepositoryProvider)
          .deactivateService(widget.service!.id);
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
    final symbol = ref.watch(regionProfileProvider).currencySymbol;
    final s = widget.service;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s == null ? l.bizServiceNew : l.bizServiceEdit, style: AppText.h2),
              const SizedBox(height: 14),
              TextField(
                  controller: _name,
                  style: AppText.body,
                  decoration: InputDecoration(labelText: l.bizServiceName)),
              const SizedBox(height: 10),
              TextField(
                controller: _price,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: moneyInputFormatters(
                    ref.watch(regionProfileProvider).currency),
                style: AppText.body,
                decoration: InputDecoration(
                    labelText: l.bizServicePrice, prefixText: '$symbol '),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _time,
                      style: AppText.body,
                      decoration: InputDecoration(
                          labelText: l.bizServiceTime, hintText: l.qsTimeHint),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _warranty,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: AppText.body,
                      decoration: InputDecoration(labelText: l.bizServiceWarranty),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: AppText.meta.copyWith(color: SrRobotColors.alertRed)),
              ],
              const SizedBox(height: 16),
              SrButton(label: l.commonSave, loading: _busy, onPressed: () => _save()),
              if (s != null) ...[
                const SizedBox(height: 10),
                SrButton(
                  label: s.active ? l.bizServiceDeactivate : l.bizServiceActivate,
                  variant: SrButtonVariant.ghost,
                  onPressed: _busy
                      ? null
                      : (s.active ? _deactivate : () => _save(active: true)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
