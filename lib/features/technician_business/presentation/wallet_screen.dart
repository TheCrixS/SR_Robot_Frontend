import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/regional_profile.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/data/business_repository.dart';
import '../../../shared/models/business_models.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/sr_card.dart';
import '../../../core/utils/money_input.dart';
import '../../../core/config/currency_spec.dart';

String _ledgerLabel(AppLocalizations l, String t) => switch (t) {
      'HOLD' => l.ledgerHOLD,
      'RELEASE' => l.ledgerRELEASE,
      'REFUND' => l.ledgerREFUND,
      'COMMISSION' => l.ledgerCOMMISSION,
      'WITHDRAWAL' => l.ledgerWITHDRAWAL,
      _ => t,
    };

/// Billetera: retenido (custodia), disponible, retirado y movimientos.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final wallet = ref.watch(walletProvider);
    final ledger = ref.watch(ledgerProvider);
    final locale = ref.watch(regionProfileProvider).locale;

    return Scaffold(
      appBar: AppBar(title: Text(l.walletTitle)),
      body: wallet.when(
        loading: () => const LoadingView(),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(walletProvider)),
        data: (w) => RefreshIndicator(
          color: SrRobotColors.primaryTeal,
          onRefresh: () async {
            ref.invalidate(walletProvider);
            ref.invalidate(ledgerProvider);
            await ref.read(walletProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: SrRobotColors.brandGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: SrRobotColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.walletAvailable,
                        style: AppText.meta.copyWith(color: Colors.white)),
                    Text(ref.money(w.available),
                        style: AppText.h1.copyWith(color: Colors.white, fontSize: 32)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStat(
                              label: l.walletHeld, value: ref.money(w.held)),
                        ),
                        Expanded(
                          child: _MiniStat(
                              label: l.walletWithdrawn,
                              value: ref.money(w.withdrawn)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SrButton(
                      label: l.walletWithdraw,
                      icon: Icons.south_west_rounded,
                      variant: SrButtonVariant.dark,
                      onPressed: w.available <= 0
                          ? null
                          : () async {
                              final ok = await showModalBottomSheet<bool>(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => _WithdrawSheet(wallet: w),
                              );
                              if (ok == true) {
                                ref.invalidate(walletProvider);
                                ref.invalidate(ledgerProvider);
                              }
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(l.walletMovements, style: AppText.h2),
              const SizedBox(height: 10),
              ledger.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(errorText(context, e), style: AppText.meta),
                data: (list) => list.isEmpty
                    ? SrCard(child: Text(l.walletNoMovements, style: AppText.meta))
                    : SrCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        child: Column(
                          children: [
                            for (var i = 0; i < list.length; i++) ...[
                              _LedgerRow(entry: list[i], locale: locale),
                              if (i < list.length - 1) const Divider(),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppText.small
                  .copyWith(color: Colors.white.withValues(alpha: 0.9))),
          Text(value, style: AppText.bodyMedium.copyWith(color: Colors.white)),
        ],
      );
}

class _LedgerRow extends ConsumerWidget {
  const _LedgerRow({required this.entry, required this.locale});
  final LedgerEntry entry;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final out = entry.type == 'WITHDRAWAL' ||
        entry.type == 'COMMISSION' ||
        entry.type == 'REFUND';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(out ? Icons.north_east_rounded : Icons.south_west_rounded,
              size: 18,
              color: out ? SrRobotColors.alertRed : SrRobotColors.primaryTeal),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_ledgerLabel(l, entry.type), style: AppText.bodyMedium),
                Text(
                  [
                    if (entry.orderId != null) '#${entry.orderId}',
                    if (entry.createdAt != null)
                      DateFormatter.shortDate(entry.createdAt!, locale),
                  ].join(' · '),
                  style: AppText.small,
                ),
              ],
            ),
          ),
          Text('${out ? '-' : '+'}${ref.money(entry.amount.abs())}',
              style: AppText.bodyMedium.copyWith(
                  color: out ? SrRobotColors.alertRed : SrRobotColors.darkTeal,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _WithdrawSheet extends ConsumerStatefulWidget {
  const _WithdrawSheet({required this.wallet});
  final WalletModel wallet;

  @override
  ConsumerState<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<_WithdrawSheet> {
  late final _amount = TextEditingController(
      text: ref.read(regionProfileProvider).currency.toInput(widget.wallet.available));
  final _account = TextEditingController();
  String _type = 'BANK';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _account.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l = context.l10n;
    final amount = ref.read(regionProfileProvider).currency.toMinor(_amount.text) ?? 0;
    if (amount <= 0 ||
        amount > widget.wallet.available ||
        _account.text.trim().length < 6) {
      setState(() => _error = l.walletInvalid);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(businessRepositoryProvider)
          .withdraw(amount, _type, _account.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.walletSent)));
      Navigator.pop(context, true);
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
    // Destinos de retiro: billeteras del país (sin tarjeta ni efectivo) + banco.
    final region = ref.watch(regionProfileProvider);
    final symbol = region.currencySymbol;
    final types = {
      for (final m in region.availablePaymentMethods)
        if (!_notForWithdrawal.contains(m)) m: paymentLabel(l, m),
      'BANK': l.walletBank,
    };
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.walletWithdraw, style: AppText.h2),
              const SizedBox(height: 14),
              TextField(
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: moneyInputFormatters(
                    ref.watch(regionProfileProvider).currency),
                style: AppText.h3,
                decoration: InputDecoration(
                    labelText: l.walletAmount, prefixText: '$symbol '),
              ),
              const SizedBox(height: 12),
              Text(l.walletDestination, style: AppText.meta),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final e in types.entries)
                    SrFilterChip(
                      label: e.value,
                      selected: _type == e.key,
                      onTap: () => setState(() => _type = e.key),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _account,
                keyboardType: TextInputType.number,
                style: AppText.body,
                decoration: InputDecoration(labelText: l.walletAccount),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: AppText.meta.copyWith(color: SrRobotColors.alertRed)),
              ],
              const SizedBox(height: 16),
              SrButton(label: l.walletWithdraw, loading: _busy, onPressed: _send),
            ],
          ),
        ),
      ),
    );
  }
}

/// Métodos que solo sirven para cobrar, no para recibir un retiro.
const _notForWithdrawal = {
  'CARD', 'CASH', 'KLARNA', 'APPLE_PAY', 'STRIPE', 'OXXO', 'CODI',
  'PAGOEFECTIVO', 'BOLETO',
};
