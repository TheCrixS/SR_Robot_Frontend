import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/business_models.dart';
import '../models/json_utils.dart';

/// Reglas de envío B2B (el servidor recalcula; esto es solo la estimación).
class SupplierRules {
  SupplierRules._();
  static const freeShippingFrom = 200000;
  static const shippingCost = 12000;
}

class SupplierTotals {
  final int subtotal;
  final int shipping;
  final int total;
  const SupplierTotals(this.subtotal, this.shipping, this.total);
}

class SupplierRepository {
  SupplierRepository(this._api);
  final ApiClient _api;

  Future<List<ProductModel>> products({String? category, String? q}) async {
    final body = await _api.get(ApiEndpoints.supplierProducts,
        query: {'category': category, 'q': q, 'limit': 100});
    return asMapList(body['data']).map(ProductModel.fromJson).toList();
  }

  Future<SupplierTotals> order(Map<String, int> items, String address) async {
    final body = await _api.post(ApiEndpoints.supplierOrders, data: {
      'items': [
        for (final e in items.entries)
          {'productId': int.tryParse(e.key) ?? e.key, 'quantity': e.value},
      ],
      'shippingAddress': address,
    });
    final t = asMap(body['totals'] ?? asMap(body['data'])['totals']);
    return SupplierTotals(
        asInt(t['subtotal']), asInt(t['shipping']), asInt(t['total']));
  }
}

final supplierRepositoryProvider = Provider<SupplierRepository>(
    (ref) => SupplierRepository(ref.watch(apiClientProvider)));

typedef ProductQuery = ({String? category, String? q});

final productsProvider = FutureProvider.autoDispose
    .family<List<ProductModel>, ProductQuery>((ref, k) => ref
        .watch(supplierRepositoryProvider)
        .products(category: k.category, q: k.q));

/// Carrito: productId → (producto, cantidad).
class CartNotifier extends StateNotifier<Map<String, (ProductModel, int)>> {
  CartNotifier() : super(const {});

  void add(ProductModel p) {
    final current = state[p.id]?.$2 ?? 0;
    if (current >= p.stock && p.stock > 0) return;
    state = {...state, p.id: (p, current + 1)};
  }

  void remove(ProductModel p) {
    final current = state[p.id]?.$2 ?? 0;
    if (current <= 1) {
      state = {...state}..remove(p.id);
    } else {
      state = {...state, p.id: (p, current - 1)};
    }
  }

  void clear() => state = const {};

  int get count => state.values.fold(0, (a, e) => a + e.$2);

  int get subtotal => state.values.fold(0, (a, e) => a + e.$1.price * e.$2);

  int get shipping =>
      subtotal >= SupplierRules.freeShippingFrom || subtotal == 0
          ? 0
          : SupplierRules.shippingCost;
}

final cartProvider =
    StateNotifierProvider<CartNotifier, Map<String, (ProductModel, int)>>(
        (ref) => CartNotifier());
