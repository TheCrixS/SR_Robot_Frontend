import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/date_formatter.dart';
import '../models/client_models.dart';
import '../models/json_utils.dart';
import '../models/technician_model.dart';

/// Cuenta del cliente: equipos, direcciones, métodos de pago, favoritos,
/// garantías y disputas.
class ClientRepository {
  ClientRepository(this._api);
  final ApiClient _api;

  // ---- Equipos ----
  Future<List<EquipmentModel>> equipments() async =>
      asMapList((await _api.get(ApiEndpoints.equipments))['data'])
          .map(EquipmentModel.fromJson)
          .toList();

  Future<void> saveEquipment({
    String? id,
    required String type,
    required String brand,
    required String model,
    String? nickname,
    DateTime? purchaseDate,
  }) {
    final body = {
      'type': type,
      'brand': brand,
      'model': model,
      if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
      if (purchaseDate != null) 'purchaseDate': DateFormatter.apiDate(purchaseDate),
    };
    return id == null
        ? _api.post(ApiEndpoints.equipments, data: body)
        : _api.put('${ApiEndpoints.equipments}/$id', data: body);
  }

  Future<void> deleteEquipment(String id) =>
      _api.delete('${ApiEndpoints.equipments}/$id');

  // ---- Direcciones ----
  Future<List<AddressModel>> addresses() async =>
      asMapList((await _api.get(ApiEndpoints.addresses))['data'])
          .map(AddressModel.fromJson)
          .toList();

  Future<void> saveAddress({
    String? id,
    required String address,
    String? label,
    String? city,
    String? notes,
    bool? isDefault,
  }) {
    final body = {
      'address': address,
      if (label != null && label.isNotEmpty) 'label': label,
      if (city != null && city.isNotEmpty) 'city': city,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (isDefault != null) 'isDefault': isDefault,
    };
    return id == null
        ? _api.post(ApiEndpoints.addresses, data: body)
        : _api.put('${ApiEndpoints.addresses}/$id', data: body);
  }

  Future<void> deleteAddress(String id) =>
      _api.delete('${ApiEndpoints.addresses}/$id');

  // ---- Métodos de pago (tokenizados por la pasarela) ----
  Future<List<SavedPaymentMethod>> paymentMethods() async =>
      asMapList((await _api.get(ApiEndpoints.clientPaymentMethods))['data'])
          .map(SavedPaymentMethod.fromJson)
          .toList();

  Future<void> setDefaultPaymentMethod(String id) => _api
      .put('${ApiEndpoints.clientPaymentMethods}/$id', data: {'isDefault': true});

  Future<void> deletePaymentMethod(String id) =>
      _api.delete('${ApiEndpoints.clientPaymentMethods}/$id');

  // ---- Favoritos ----
  Future<List<TechnicianModel>> favorites() async {
    final data = (await _api.get(ApiEndpoints.favorites))['data'];
    return [
      for (final m in asMapList(data))
        TechnicianModel.fromJson(
            m['technician'] is Map ? asMap(m['technician']) : m),
    ];
  }

  // ---- Garantías ----
  Future<int> activeWarranties() async {
    final list = asMapList((await _api.get(ApiEndpoints.warranties))['data']);
    return list.where((w) => asBool(w['active'])).length;
  }

  // ---- Disputas ----
  Future<List<DisputeModel>> disputes() async =>
      asMapList((await _api.get(ApiEndpoints.disputes, query: {'limit': 50}))['data'])
          .map(DisputeModel.fromJson)
          .toList();

  Future<DisputeModel> dispute(String id) async => DisputeModel.fromJson(
      asMap((await _api.get('${ApiEndpoints.disputes}/$id'))['data']));

  Future<void> openDispute(String orderId,
      {required String reason, required String description, List<String> media = const []}) async {
    final form = FormData.fromMap({
      'reason': reason,
      'description': description,
      if (media.isNotEmpty)
        'media': [
          for (final p in media)
            await MultipartFile.fromFile(p, filename: p.split(RegExp(r'[\\/]')).last),
        ],
    }, ListFormat.multiCompatible);
    await _api.post(ApiEndpoints.orderDisputes(orderId), data: form);
  }

  Future<void> commentDispute(String id, String note,
      {List<String> media = const []}) async {
    final form = FormData.fromMap({
      'note': note,
      if (media.isNotEmpty)
        'media': [
          for (final p in media)
            await MultipartFile.fromFile(p, filename: p.split(RegExp(r'[\\/]')).last),
        ],
    }, ListFormat.multiCompatible);
    await _api.post('${ApiEndpoints.disputes}/$id/comments', data: form);
  }
}

final clientRepositoryProvider = Provider<ClientRepository>(
    (ref) => ClientRepository(ref.watch(apiClientProvider)));

final equipmentsProvider = FutureProvider.autoDispose<List<EquipmentModel>>(
    (ref) => ref.watch(clientRepositoryProvider).equipments());

final addressesProvider = FutureProvider.autoDispose<List<AddressModel>>(
    (ref) => ref.watch(clientRepositoryProvider).addresses());

final savedPaymentMethodsProvider =
    FutureProvider.autoDispose<List<SavedPaymentMethod>>(
        (ref) => ref.watch(clientRepositoryProvider).paymentMethods());

final favoritesProvider = FutureProvider.autoDispose<List<TechnicianModel>>(
    (ref) => ref.watch(clientRepositoryProvider).favorites());

final activeWarrantiesProvider = FutureProvider.autoDispose<int>(
    (ref) => ref.watch(clientRepositoryProvider).activeWarranties());

final disputesProvider = FutureProvider.autoDispose<List<DisputeModel>>(
    (ref) => ref.watch(clientRepositoryProvider).disputes());

final disputeProvider = FutureProvider.autoDispose.family<DisputeModel, String>(
    (ref, id) => ref.watch(clientRepositoryProvider).dispute(id));
