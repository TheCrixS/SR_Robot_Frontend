import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/orders_repository.dart';
import '../../../shared/data/technician_work_repository.dart';
import '../../../shared/models/order_model.dart';

/// Avanza una orden (paso a paso, como exige el backend) hasta [target].
/// Solo cubre los pasos del técnico: SOLICITADO → DIAGNOSTICO →
/// EN_REPARACION → LISTO.
Future<OrderState> advanceOrderTo(
    WidgetRef ref, String orderId, OrderState target) async {
  final orders = ref.read(ordersRepositoryProvider);
  final work = ref.read(technicianWorkRepositoryProvider);
  var current = (await orders.detail(orderId)).state;

  while (current.step >= 0 &&
      current.step < target.step &&
      current.step < OrderState.listo.step) {
    final next = OrderState.sequence[current.step + 1];
    await work.transition(orderId, next);
    current = next;
  }
  ref.invalidate(orderDetailProvider(orderId));
  ref.invalidate(ordersListProvider('active'));
  return current;
}
