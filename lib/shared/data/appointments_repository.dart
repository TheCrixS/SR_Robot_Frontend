import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/date_formatter.dart';
import '../models/json_utils.dart';

class AppointmentSummary {
  final String orderId;
  final String serviceName;
  final int servicePrice;
  final int homeFee;
  final int total;
  final String date;
  final String time;
  final String paymentMethod;
  final bool isHome;
  final String? currency;

  const AppointmentSummary({
    required this.orderId,
    required this.serviceName,
    required this.servicePrice,
    required this.homeFee,
    required this.total,
    required this.date,
    required this.time,
    required this.paymentMethod,
    required this.isHome,
    this.currency,
  });
}

class AppointmentsRepository {
  AppointmentsRepository(this._api);
  final ApiClient _api;

  Future<List<String>> availability(String technicianId, DateTime day) async {
    final body = await _api.get(ApiEndpoints.availability(technicianId),
        query: {'date': DateFormatter.apiDate(day)});
    final data = asMap(body['data']);
    final slots = asStrList(data['availableSlots']);
    if (slots.isNotEmpty) return slots;
    return [
      for (final s in asMapList(data['slots']))
        if (asBool(s['available'])) asStr(s['time']) ?? '',
    ];
  }

  Future<AppointmentSummary> create({
    required String technicianId,
    required String serviceId,
    required String serviceName,
    required DateTime date,
    required String time,
    required bool isHome,
    required String paymentMethod,
    String? address,
    String? notes,
  }) async {
    final body = await _api.post(ApiEndpoints.appointments, data: {
      'technicianId': int.tryParse(technicianId) ?? technicianId,
      'serviceId': int.tryParse(serviceId) ?? serviceId,
      'date': DateFormatter.apiDate(date),
      'time': time,
      'mode': isHome ? 'HOME' : 'LOCAL',
      if (isHome && address != null) 'address': address,
      'paymentMethod': paymentMethod,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    final data = asMap(body['data']);
    final summary = asMap(data['summary']);
    final order = asMap(data['order']);
    return AppointmentSummary(
      orderId: asId(order['id']),
      serviceName: serviceName,
      servicePrice: asInt(summary['service'] ?? order['baseAmount']),
      homeFee: asInt(summary['homeFee'] ?? order['homeFee']),
      total: asInt(summary['total'] ?? order['amount']),
      date: DateFormatter.apiDate(date),
      time: time,
      paymentMethod: paymentMethod,
      isHome: isHome,
      currency: asStr(summary['currency']) ?? asStr(order['currency']),
    );
  }
}

final appointmentsRepositoryProvider = Provider<AppointmentsRepository>(
    (ref) => AppointmentsRepository(ref.watch(apiClientProvider)));

typedef AvailabilityKey = ({String technicianId, DateTime day});

final availabilityProvider = FutureProvider.autoDispose
    .family<List<String>, AvailabilityKey>((ref, k) => ref
        .watch(appointmentsRepositoryProvider)
        .availability(k.technicianId, k.day));
