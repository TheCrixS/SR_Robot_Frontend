import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/session_controller.dart';
import '../../core/config/regional_profile.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/json_utils.dart';
import '../models/quote_model.dart';
import 'location_provider.dart';

class NewQuoteRequest {
  final String deviceType;
  final String brandModel;
  final String issueDescription;
  final Urgency urgency;
  final bool isHomeService;
  final String? address;
  final GeoPoint? location;
  final String? targetTechnicianId;
  final List<String> filePaths;

  const NewQuoteRequest({
    required this.deviceType,
    required this.brandModel,
    required this.issueDescription,
    required this.urgency,
    required this.isHomeService,
    required this.filePaths,
    this.address,
    this.location,
    this.targetTechnicianId,
  });
}

class QuotesRepository {
  QuotesRepository(this._api);
  final ApiClient _api;

  Future<QuoteRequestModel> create(NewQuoteRequest r) async {
    final fields = <String, dynamic>{
      'deviceType': r.deviceType,
      'brandModel': r.brandModel,
      'issueDescription': r.issueDescription,
      'urgency': r.urgency.api,
      'isHomeService': r.isHomeService.toString(),
      if (r.address != null && r.address!.isNotEmpty) 'address': r.address,
      if (r.location != null) 'lat': r.location!.lat.toString(),
      if (r.location != null) 'lng': r.location!.lng.toString(),
      if (r.targetTechnicianId != null)
        'targetTechnicianId': r.targetTechnicianId,
    };

    final Object payload;
    if (r.filePaths.isEmpty) {
      payload = {
        ...fields,
        'isHomeService': r.isHomeService,
        if (r.location != null) 'lat': r.location!.lat,
        if (r.location != null) 'lng': r.location!.lng,
        if (r.targetTechnicianId != null)
          'targetTechnicianId': int.tryParse(r.targetTechnicianId!) ??
              r.targetTechnicianId,
      };
    } else {
      payload = FormData.fromMap({
        ...fields,
        'media': [
          for (final p in r.filePaths)
            await MultipartFile.fromFile(p, filename: p.split(RegExp(r'[\\/]')).last),
        ],
      }, ListFormat.multiCompatible);
    }

    final body = await _api.post(ApiEndpoints.quoteRequests, data: payload);
    return QuoteRequestModel.fromJson(asMap(body['data']));
  }

  Future<List<QuoteRequestModel>> mine({String? status}) async {
    final body = await _api.get(ApiEndpoints.myQuoteRequests,
        query: {'status': status, 'limit': 50});
    return asMapList(body['data']).map(QuoteRequestModel.fromJson).toList();
  }

  Future<QuoteRequestModel> detail(String id) async {
    final body = await _api.get(ApiEndpoints.quoteRequest(id));
    return QuoteRequestModel.fromJson(asMap(body['data']));
  }

  Future<QuotesResult> quotes(String requestId) async {
    final body = await _api.get(ApiEndpoints.quotes(requestId));
    return QuotesResult(
      asMapList(body['data']).map(QuoteModel.fromJson).toList(),
      asBool(body['waiting']),
      asStr(body['status']) ?? 'OPEN',
      asDate(body['expiresAt']),
    );
  }

  /// Acepta una oferta y devuelve el id de la orden creada.
  Future<String> accept(
      String requestId, String quoteId, String paymentMethod) async {
    final body = await _api.post(ApiEndpoints.acceptQuote(requestId, quoteId),
        data: {'paymentMethod': paymentMethod});
    final data = asMap(body['data']);
    return asId(asMap(data['order'])['id']);
  }

  Future<void> cancel(String requestId) async {
    await _api.post('${ApiEndpoints.quoteRequest(requestId)}/cancel');
  }
}

final quotesRepositoryProvider = Provider<QuotesRepository>(
    (ref) => QuotesRepository(ref.watch(apiClientProvider)));

final myOpenQuoteRequestsProvider =
    FutureProvider.autoDispose<List<QuoteRequestModel>>((ref) =>
        ref.watch(quotesRepositoryProvider).mine(status: 'OPEN'));

final quotesProvider = FutureProvider.autoDispose
    .family<QuotesResult, String>((ref, requestId) =>
        ref.watch(quotesRepositoryProvider).quotes(requestId));

final quoteRequestProvider = FutureProvider.autoDispose
    .family<QuoteRequestModel, String>((ref, id) =>
        ref.watch(quotesRepositoryProvider).detail(id));

/// Métodos de pago reales del país del usuario (`GET /payments/methods`).
/// Se vuelve a pedir cuando cambia el país de la cuenta; si falla se usan los
/// del perfil regional activo.
final paymentMethodsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  ref.watch(currentUserProvider.select((u) => u?.country));
  final fallback = ref.read(regionProfileProvider).availablePaymentMethods;
  try {
    final body =
        await ref.watch(apiClientProvider).get(ApiEndpoints.paymentMethods);
    final data = body['data'];
    final list = data is List
        ? data.map((e) => e.toString()).toList()
        : asStrList(asMap(data)['methods']);
    return list.isEmpty ? fallback : list;
  } catch (_) {
    return fallback;
  }
});
