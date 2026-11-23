import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/data/business_repository.dart';
import '../../../shared/data/supplier_repository.dart';
import '../../../shared/models/business_models.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/sr_card.dart';
import '../../../shared/data/config_repository.dart';

class PartsCatalogScreen extends ConsumerStatefulWidget {
  const PartsCatalogScreen({super.key});

  @override
  ConsumerState<PartsCatalogScreen> createState() => _PartsCatalogScreenState();
}

class _PartsCatalogScreenState extends ConsumerState<PartsCatalogScreen> {
  String? _category;
  String? _q;
  Timer? _debounce;
  List<String> _knownCategories = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ProductQuery key = (category: _category, q: _q);
    final async = ref.watch(productsProvider(key));
    final cart = ref.watch(cartProvider);
    final count = cart.values.fold<int>(0, (a, e) => a + e.$2);
    final plan = ref.watch(myBusinessProvider).valueOrNull?.plan;

    // Categorías derivadas del catálogo completo (primera carga sin filtro).
    final all = ref.watch(productsProvider((category: null, q: null))).valueOrNull;
    if (all != null) {
      _knownCategories = {for (final p in all) p.category}.toList()..sort();
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.partsTitle, style: AppText.h1)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: TextField(
              style: AppText.body,
              decoration: InputDecoration(
                hintText: l.partsSearch,
                prefixIcon:
                    const Icon(Icons.search_rounded, color: SrRobotColors.textGray),
              ),
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400),
                    () => setState(() => _q = v.trim().isEmpty ? null : v.trim()));
              },
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                SrFilterChip(
                  label: l.partsAll,
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                for (final c in _knownCategories) ...[
                  const SizedBox(width: 8),
                  SrFilterChip(
                    label: categoryLabel(l, c),
                    selected: _category == c,
                    onTap: () => setState(() => _category = c),
                  ),
                ],
              ],
            ),
          ),
          if (plan == 'BASIC')
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SrRobotColors.yellowAccent.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(l.partsProTip, style: AppText.small.copyWith(color: SrRobotColors.textInk))),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: async.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                  error: e, onRetry: () => ref.invalidate(productsProvider(key))),
              data: (list) => list.isEmpty
                  ? EmptyStateView(title: l.partsEmpty)
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.66,
                      ),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _ProductCard(
                        product: list[i],
                        qty: cart[list[i].id]?.$2 ?? 0,
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: count == 0
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SrButton(
                label: l.partsCart(count),
                icon: Icons.shopping_cart_outlined,
                variant: SrButtonVariant.dark,
                onPressed: () => context.push(Routes.cart),
              ),
            ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product, required this.qty});
  final ProductModel product;
  final int qty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = product;
    final cart = ref.read(cartProvider.notifier);
    final outOfStock = p.stock <= 0;

    return SrCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 76,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SrRobotColors.softTeal,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.memory_rounded,
                size: 34, color: SrRobotColors.primaryTeal),
          ),
          const SizedBox(height: 8),
          Text(p.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.meta.copyWith(
                  color: SrRobotColors.textInk, fontWeight: FontWeight.w600)),
          Text(categoryLabel(context.l10n, p.category), style: AppText.tag.copyWith(color: SrRobotColors.textGray)),
          const Spacer(),
          if (p.hasDiscount) ...[
            Row(
              children: [
                Flexible(
                  child: Text(ref.money(p.listPrice),
                      overflow: TextOverflow.ellipsis,
                      style: AppText.small.copyWith(
                          decoration: TextDecoration.lineThrough)),
                ),
                const SizedBox(width: 4),
                SrTag(l.partsDiscount((p.discount * 100).toStringAsFixed(0)),
                    color: SrRobotColors.lime.withValues(alpha: 0.3),
                    textColor: SrRobotColors.textInk),
              ],
            ),
          ],
          Text(ref.money(p.price),
              style: AppText.bodyMedium.copyWith(
                  color: SrRobotColors.darkTeal, fontWeight: FontWeight.w700)),
          Text(outOfStock ? l.partsOutOfStock : l.partsStock(p.stock),
              style: AppText.tag.copyWith(
                  color: outOfStock ? SrRobotColors.alertRed : SrRobotColors.textGray)),
          const SizedBox(height: 8),
          if (qty == 0)
            SizedBox(
              height: 36,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: outOfStock ? null : () => cart.add(p),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l.partsAdd),
                style: OutlinedButton.styleFrom(
                  foregroundColor: SrRobotColors.primaryTeal,
                  side: const BorderSide(color: SrRobotColors.primaryTeal),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          else
            QtyStepper(
              qty: qty,
              onMinus: () => cart.remove(p),
              onPlus: qty >= p.stock ? null : () => cart.add(p),
            ),
        ],
      ),
    );
  }
}

class QtyStepper extends StatelessWidget {
  const QtyStepper(
      {super.key, required this.qty, required this.onMinus, required this.onPlus});
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData i, VoidCallback? f) => Material(
          color: SrRobotColors.softTeal,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: f,
            child: SizedBox(
              width: 34,
              height: 34,
              child: Icon(i,
                  size: 18,
                  color: f == null ? SrRobotColors.textGray : SrRobotColors.darkTeal),
            ),
          ),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        btn(Icons.remove_rounded, onMinus),
        Text('$qty', style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
        btn(Icons.add_rounded, onPlus),
      ],
    );
  }
}
