import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/date_formatter.dart';
import '../models/business_models.dart';
import '../models/json_utils.dart';
import '../models/order_model.dart';
import '../models/quote_model.dart';

class ReceivedRequests {
  final List<QuoteRequestModel> items;
  final Map<String, int> counts;
  const ReceivedRequests(this.items, this.counts);
}

/// Operación diaria del técnico: solicitudes, agenda y ejecución de órdenes.
class TechnicianWorkRepository {
  TechnicianWorkRepository(this._api);
  final ApiClient _api;

  /// `status`: NEW | QUOTED | ACCEPTED | REJECTED | CLOSED.
  Future<ReceivedRequests> received(String status) async {
    final body = await _api.get(ApiEndpoints.receivedQuoteRequests,
        query: {'status': status, 'limit': 50});
    final counts = asMap(body['counts'] ?? asMap(body['meta'])['counts']);
    return ReceivedRequests(
      asMapList(body['data']).map(QuoteRequestModel.fromJson).toList(),
      {for (final e in counts.entries) e.key: asInt(e.value)},
    );
  }

  Future<void> sendQuote(
    String requestId, {
    required int price,
    required String estimatedTime,
    int? estimatedHours,
    required int warrantyDays,
    String? message,
  }) =>
      _api.post(ApiEndpoints.quotes(requestId), data: {
        'price': price,
        'estimatedTime': estimatedTime,
        if (estimatedHours != null) 'estimatedHours': estimatedHours,
        'warrantyDays': warrantyDays,
        if (message != null && message.isNotEmpty) 'message': message,
      });

  Future<void> reject(String requestId) =>
      _api.post(ApiEndpoints.rejectRequest(requestId));

  Future<List<AppointmentModel>> appointments(DateTime day) async {
    final body = await _api.get(ApiEndpoints.appointments,
        query: {'date': DateFormatter.apiDate(day)});
    final list = asMapList(body['data']).map(AppointmentModel.fromJson).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    return list;
  }

  Future<void> transition(String orderId, OrderState newState, {String? note}) =>
      _api.post(ApiEndpoints.transitions(orderId), data: {
        'newState': newState.api,
        if (note != null && note.isNotEmpty) 'note': note,
      });

  Future<void> addEvidence(String orderId, List<String> paths, String note) async {
    final form = FormData.fromMap({
      'note': note,
      'media': [
        for (final p in paths)
          await MultipartFile.fromFile(p, filename: p.split(RegExp(r'[\\/]')).last),
      ],
    }, ListFormat.multiCompatible);
    await _api.post(ApiEndpoints.evidence(orderId), data: form);
  }

  Future<void> requestAdjustment(String orderId, int amount, String reason) =>
      _api.post(ApiEndpoints.adjustments(orderId),
          data: {'amount': amount, 'reason': reason});
}

final technicianWorkRepositoryProvider = Provider<TechnicianWorkRepository>(
    (ref) => TechnicianWorkRepository(ref.watch(apiClientProvider)));

final receivedRequestsProvider = FutureProvider.autoDispose
    .family<ReceivedRequests, String>((ref, status) =>
        ref.watch(technicianWorkRepositoryProvider).received(status));

final agendaProvider = FutureProvider.autoDispose
    .family<List<AppointmentModel>, DateTime>((ref, day) =>
        ref.watch(technicianWorkRepositoryProvider).appointments(day));
