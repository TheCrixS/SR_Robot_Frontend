import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/client_repository.dart';
import '../../../shared/models/client_models.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/sr_card.dart';
import '../../../shared/widgets/technician_cards.dart';

void _snack(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

// ---------------------------------------------------------------------------
// Direcciones guardadas
// ---------------------------------------------------------------------------

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, [AddressModel? a]) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddressSheet(address: a),
    );
    if (ok == true) ref.invalidate(addressesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(addressesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.addressesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: SrRobotColors.primaryTeal,
        foregroundColor: Colors.white,
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: Text(l.addressesAdd),
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(addressesProvider)),
        data: (list) => list.isEmpty
            ? EmptyStateView(title: l.addressesTitle, body: l.addressesEmpty)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final a = list[i];
                  return SrCard(
                    onTap: () => _edit(context, ref, a),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: SrRobotColors.primaryTeal),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Flexible(
                                  child: Text(a.label ?? a.address,
                                      style: AppText.bodyMedium
                                          .copyWith(fontWeight: FontWeight.w700)),
                                ),
                                if (a.isDefault) ...[
                                  const SizedBox(width: 6),
                                  SrTag(l.addressesDefault),
                                ],
                              ]),
                              Text(
                                  [a.address, if (a.city != null) a.city!].join(', '),
                                  style: AppText.small),
                            ],
                          ),
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

class _AddressSheet extends ConsumerStatefulWidget {
  const _AddressSheet({this.address});
  final AddressModel? address;

  @override
  ConsumerState<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends ConsumerState<_AddressSheet> {
  late final _label = TextEditingController(text: widget.address?.label ?? '');
  late final _address = TextEditingController(text: widget.address?.address ?? '');
  late final _city = TextEditingController(text: widget.address?.city ?? '');
  late final _notes = TextEditingController(text: widget.address?.notes ?? '');
  late bool _default = widget.address?.isDefault ?? false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_label, _address, _city, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    if (_address.text.trim().isEmpty) {
      setState(() => _error = l.quoteAddressRequired);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(clientRepositoryProvider).saveAddress(
            id: widget.address?.id,
            address: _address.text.trim(),
            label: _label.text.trim(),
            city: _city.text.trim(),
            notes: _notes.text.trim(),
            isDefault: _default,
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
    setState(() => _busy = true);
    try {
      await ref.read(clientRepositoryProvider).deleteAddress(widget.address!.id);
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
              Text(widget.address == null ? l.addressesAdd : l.commonEdit,
                  style: AppText.h2),
              const SizedBox(height: 12),
              TextField(
                  controller: _label,
                  style: AppText.body,
                  decoration: InputDecoration(labelText: l.addressesLabel)),
              const SizedBox(height: 10),
              TextField(
                  controller: _address,
                  style: AppText.body,
                  decoration: InputDecoration(labelText: l.addressesAddress)),
              const SizedBox(height: 10),
              TextField(
                  controller: _city,
                  style: AppText.body,
                  decoration: InputDecoration(labelText: l.addressesCity)),
              const SizedBox(height: 10),
              TextField(
                  controller: _notes,
                  style: AppText.body,
                  decoration: InputDecoration(labelText: l.addressesNotes)),
              CheckboxListTile(
                value: _default,
                onChanged: (v) => setState(() => _default = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: SrRobotColors.primaryTeal,
                title: Text(l.addressesMakeDefault, style: AppText.body),
              ),
              if (_error != null)
                Text(_error!,
                    style: AppText.meta.copyWith(color: SrRobotColors.alertRed)),
              const SizedBox(height: 12),
              SrButton(label: l.commonSave, loading: _busy, onPressed: _save),
              if (widget.address != null) ...[
                const SizedBox(height: 10),
                SrButton(
                  label: l.commonDelete,
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

// ---------------------------------------------------------------------------
// Métodos de pago guardados (solo tokens: nunca números completos)
// ---------------------------------------------------------------------------

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(savedPaymentMethodsProvider);
    final repo = ref.read(clientRepositoryProvider);

    Future<void> run(Future<void> Function() f) async {
      try {
        await f();
        ref.invalidate(savedPaymentMethodsProvider);
      } catch (e) {
        if (context.mounted) _snack(context, errorText(context, e));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.paymentsTitle)),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
            error: e, onRetry: () => ref.invalidate(savedPaymentMethodsProvider)),
        data: (list) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            if (list.isEmpty)
              EmptyStateView(title: l.paymentsTitle, body: l.paymentsEmpty)
            else
              for (final m in list) ...[
                SrCard(
                  child: Row(
                    children: [
                      Icon(paymentIcon(m.type), color: SrRobotColors.primaryTeal),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                m.brand ?? paymentLabel(l, m.type),
                                style: AppText.bodyMedium
                                    .copyWith(fontWeight: FontWeight.w700)),
                            if (m.last4 != null)
                              Text(l.paymentsEnding(m.last4!), style: AppText.small),
                          ],
                        ),
                      ),
                      if (m.isDefault)
                        SrTag(l.addressesDefault)
                      else
                        TextButton(
                          onPressed: () => run(() => repo.setDefaultPaymentMethod(m.id)),
                          child: Text(l.addressesMakeDefault,
                              style: AppText.small.copyWith(
                                  color: SrRobotColors.primaryTeal)),
                        ),
                      IconButton(
                        tooltip: l.commonDelete,
                        onPressed: () => run(() => repo.deletePaymentMethod(m.id)),
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: SrRobotColors.textGray),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 16, color: SrRobotColors.textGray),
                const SizedBox(width: 6),
                Expanded(child: Text(l.paymentsNote, style: AppText.small)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Favoritos
// ---------------------------------------------------------------------------

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(favoritesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.favoritesTitle)),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(favoritesProvider)),
        data: (list) => list.isEmpty
            ? EmptyStateView(title: l.favoritesTitle, body: l.favoritesEmpty)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => TechnicianListTile(
                  tech: list[i],
                  onTap: () async {
                    await context.push(Routes.technician(list[i].id));
                    ref.invalidate(favoritesProvider);
                  },
                ),
              ),
      ),
    );
  }
}
