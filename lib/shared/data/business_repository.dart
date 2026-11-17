import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/business_models.dart';
import '../models/json_utils.dart';
import '../models/technician_model.dart';

/// "Mi negocio": perfil, horario, servicios, verificación, billetera,
/// métricas, suscripción y reseñas del técnico autenticado.
class BusinessRepository {
  BusinessRepository(this._api);
  final ApiClient _api;

  Future<TechnicianModel> me() async =>
      TechnicianModel.fromJson(asMap((await _api.get(ApiEndpoints.myBusiness))['data']));

  Future<TechnicianModel> update(Map<String, dynamic> fields) async =>
      TechnicianModel.fromJson(
          asMap((await _api.put(ApiEndpoints.myBusiness, data: fields))['data']));

  Future<void> setAvailable(bool available) =>
      _api.put(ApiEndpoints.myBusiness, data: {'available': available});

  Future<Map<String, DaySchedule>> schedule() async {
    final data = asMap((await _api.get(ApiEndpoints.mySchedule))['data']);
    final raw = asMap(data['schedule'] ?? data);
    return {
      for (final e in raw.entries)
        if (e.value is Map)
          e.key: DaySchedule(
            asBool(asMap(e.value)['enabled']),
            asStr(asMap(e.value)['open']) ?? '08:00',
            asStr(asMap(e.value)['close']) ?? '18:00',
          ),
    };
  }

  Future<void> saveSchedule(Map<String, DaySchedule> s) =>
      _api.put(ApiEndpoints.mySchedule, data: {
        'schedule': {
          for (final e in s.entries)
            e.key: {
              'enabled': e.value.enabled,
              'open': e.value.open,
              'close': e.value.close,
            },
        },
      });

  Future<List<TechService>> services() async =>
      asMapList((await _api.get(ApiEndpoints.myServices))['data'])
          .map(TechService.fromJson)
          .toList();

  Future<void> saveService({
    String? id,
    required String name,
    required int priceFrom,
    required String estimatedTime,
    required int warrantyDays,
    bool? active,
  }) {
    final body = {
      'name': name,
      'priceFrom': priceFrom,
      'estimatedTime': estimatedTime,
      'warrantyDays': warrantyDays,
      if (active != null) 'active': active,
    };
    return id == null
        ? _api.post(ApiEndpoints.myServices, data: body)
        : _api.put('${ApiEndpoints.myServices}/$id', data: body);
  }

  Future<void> deactivateService(String id) =>
      _api.delete('${ApiEndpoints.myServices}/$id');

  /// Sube documentos (ID, RUT, LOCAL_PHOTO) y envía a verificación.
  Future<void> submitVerification(Map<String, String> docsByType) async {
    for (final e in docsByType.entries) {
      final form = FormData.fromMap({
        'type': e.key,
        'documents': await MultipartFile.fromFile(e.value,
            filename: e.value.split(RegExp(r'[\\/]')).last),
      });
      await _api.post('${ApiEndpoints.myBusiness}/documents', data: form);
    }
    await _api.post('${ApiEndpoints.myBusiness}/submit-verification');
  }

  Future<WalletModel> wallet() async =>
      WalletModel.fromJson(asMap((await _api.get(ApiEndpoints.myWallet))['data']));

  Future<List<LedgerEntry>> ledger() async =>
      asMapList((await _api.get(ApiEndpoints.myLedger, query: {'limit': 50}))['data'])
          .map(LedgerEntry.fromJson)
          .toList();

  Future<void> withdraw(int amount, String type, String account) =>
      _api.post(ApiEndpoints.myWithdrawals, data: {
        'amount': amount,
        'destination': {'type': type, 'account': account},
      });

  Future<TechnicianAnalytics> analytics({int days = 30}) async =>
      TechnicianAnalytics.fromJson(asMap(
          (await _api.get(ApiEndpoints.myAnalytics, query: {'days': days}))['data']));

  Future<List<PlanModel>> plans() async =>
      asMapList((await _api.get(ApiEndpoints.plans))['data'])
          .map(PlanModel.fromJson)
          .toList();

  Future<MySubscription> mySubscription() async =>
      MySubscription.fromJson(asMap((await _api.get(ApiEndpoints.mySubscription))['data']));

  Future<void> changePlan(String plan, String paymentMethod) =>
      _api.put(ApiEndpoints.mySubscription,
          data: {'plan': plan, 'paymentMethod': paymentMethod});

  Future<void> cancelSubscription() => _api.delete(ApiEndpoints.mySubscription);

  Future<List<ReviewModel>> reviews(String technicianId) async =>
      asMapList((await _api.get(ApiEndpoints.technicianReviews(technicianId),
              query: {'limit': 50}))['data'])
          .map(ReviewModel.fromJson)
          .toList();

  Future<void> replyReview(String reviewId, String text) =>
      _api.post('/reviews/$reviewId/reply', data: {'replyText': text});
}

final businessRepositoryProvider = Provider<BusinessRepository>(
    (ref) => BusinessRepository(ref.watch(apiClientProvider)));

final myBusinessProvider = FutureProvider.autoDispose<TechnicianModel>(
    (ref) => ref.watch(businessRepositoryProvider).me());

final analyticsProvider = FutureProvider.autoDispose<TechnicianAnalytics>(
    (ref) => ref.watch(businessRepositoryProvider).analytics());

final walletProvider = FutureProvider.autoDispose<WalletModel>(
    (ref) => ref.watch(businessRepositoryProvider).wallet());

final ledgerProvider = FutureProvider.autoDispose<List<LedgerEntry>>(
    (ref) => ref.watch(businessRepositoryProvider).ledger());

final plansProvider = FutureProvider.autoDispose<List<PlanModel>>(
    (ref) => ref.watch(businessRepositoryProvider).plans());

final mySubscriptionProvider = FutureProvider.autoDispose<MySubscription>(
    (ref) => ref.watch(businessRepositoryProvider).mySubscription());

final myServicesProvider = FutureProvider.autoDispose<List<TechService>>(
    (ref) => ref.watch(businessRepositoryProvider).services());

final myScheduleProvider = FutureProvider.autoDispose<Map<String, DaySchedule>>(
    (ref) => ref.watch(businessRepositoryProvider).schedule());

final myReviewsProvider =
    FutureProvider.autoDispose<List<ReviewModel>>((ref) async {
  final me = await ref.watch(myBusinessProvider.future);
  return ref.watch(businessRepositoryProvider).reviews(me.id);
});
