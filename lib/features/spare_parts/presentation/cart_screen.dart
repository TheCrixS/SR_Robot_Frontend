import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/business_repository.dart';
import '../../../shared/data/supplier_repository.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/payment_selector.dart';
import '../../../shared/widgets/sr_card.dart';
import 'parts_catalog_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _address = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final b = ref.read(myBusinessProvider).valueOrNull;
    if (b?.address != null) {
      _address.text = [b!.address!, if (b.city != null) b.city!].join(', ');
    }
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _checkout() async {
    final l = context.l10n;
    if (_address.text.trim().isEmpty) {
      setState(() => _error = l.cartAddressRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final cart = ref.read(cartProvider);
      final totals = await ref.read(supplierRepositoryProvider).order(
            {for (final e in cart.entries) e.key: e.value.$2},
            _address.text.trim(),
          );
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(productsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.cartOrdered(ref.money(totals.total)))));
      context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = errorText(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    final subtotal = notifier.subtotal;
    final shipping = notifier.shipping;
    final missing = SupplierRules.freeShippingFrom - subtotal;

    return Scaffold(
      appBar: AppBar(title: Text(l.cartTitle)),
      body: cart.isEmpty
          ? EmptyStateView(title: l.cartEmpty)
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                for (final e in cart.values) ...[
                  SrCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.$1.name,
                                  style: AppText.bodyMedium
                                      .copyWith(fontWeight: FontWeight.w600)),
                              Text(ref.money(e.$1.price), style: AppText.meta),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: QtyStepper(
                            qty: e.$2,
                            onMinus: () => notifier.remove(e.$1),
                            onPlus: e.$2 >= e.$1.stock ? null : () => notifier.add(e.$1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: missing <= 0
                        ? SrRobotColors.lime.withValues(alpha: 0.25)
                        : SrRobotColors.softTeal,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        missing <= 0
                            ? l.cartFreeShipping
                            : l.cartFreeShippingLeft(ref.money(missing)),
                        style: AppText.meta.copyWith(color: SrRobotColors.textInk),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (subtotal / SupplierRules.freeShippingFrom)
                              .clamp(0.0, 1.0),
                          minHeight: 6,
                          color: SrRobotColors.primaryTeal,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SrCard(
                  child: Column(
                    children: [
                      SummaryRow(l.cartSubtotal, ref.money(subtotal)),
                      SummaryRow(l.cartShipping,
                          ref.money(shipping, freeLabel: l.commonFree)),
                      const Divider(height: 16),
                      SummaryRow(l.commonTotal, ref.money(subtotal + shipping),
                          bold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _address,
                  style: AppText.body,
                  decoration: InputDecoration(
                    labelText: l.cartAddress,
                    prefixIcon: const Icon(Icons.local_shipping_outlined,
                        color: SrRobotColors.textGray),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!,
                      style: AppText.meta.copyWith(color: SrRobotColors.alertRed)),
                ],
                const SizedBox(height: 18),
                SrButton(label: l.cartCheckout, loading: _busy, onPressed: _checkout),
              ],
            ),
    );
  }
}
