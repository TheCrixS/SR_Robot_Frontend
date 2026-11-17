import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/json_utils.dart';
import '../models/order_model.dart';
import '../models/paged.dart';

class OrdersRepository {
  OrdersRepository(this._api);
  final ApiClient _api;

  /// `status`: `active` o `history`.
  Future<Paged<OrderModel>> list(String status, {int page = 1}) async {
    final body = await _api.get(ApiEndpoints.orders,
        query: {'status': status, 'page': page, 'limit': 20});
    return Paged.fromResponse(body, OrderModel.fromJson);
  }

  Future<OrderModel> detail(String id) async {
    final body = await _api.get(ApiEndpoints.order(id));
    return OrderModel.fromJson(asMap(body['data']));
  }

  Future<void> confirmReceipt(String id) =>
      _api.post(ApiEndpoints.confirmReceipt(id), data: {});

  Future<void> approveAdjustment(String id, String adjustmentId) =>
      _api.post(ApiEndpoints.approveAdjustment(id, adjustmentId));

  Future<void> rejectAdjustment(String id, String adjustmentId) =>
      _api.post(ApiEndpoints.rejectAdjustment(id, adjustmentId));

  Future<void> review(String id,
          {required int rating, List<String> tags = const [], String? comment}) =>
      _api.post(ApiEndpoints.reviews(id), data: {
        'rating': rating,
        'tags': tags,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      });

  Future<void> cancel(String id, {String? reason}) =>
      _api.post('${ApiEndpoints.order(id)}/cancel',
          data: {if (reason != null) 'reason': reason});
}

final ordersRepositoryProvider = Provider<OrdersRepository>(
    (ref) => OrdersRepository(ref.watch(apiClientProvider)));

/// Orden activa más reciente para la tarjeta "Reparación en curso".
final activeOrderProvider = FutureProvider.autoDispose<OrderModel?>((ref) async {
  final page = await ref.watch(ordersRepositoryProvider).list('active');
  return page.items.isEmpty ? null : page.items.first;
});

final ordersListProvider = FutureProvider.autoDispose
    .family<List<OrderModel>, String>((ref, status) async =>
        (await ref.watch(ordersRepositoryProvider).list(status)).items);

final orderDetailProvider = FutureProvider.autoDispose
    .family<OrderModel, String>(
        (ref, id) => ref.watch(ordersRepositoryProvider).detail(id));
