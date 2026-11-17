import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/json_utils.dart';
import '../models/technician_model.dart';
import 'location_provider.dart';

/// Filtros de `GET /technicians`.
class TechnicianQuery {
  final String? q;
  final String? category;
  final bool home;
  final bool verified;
  final double? minRating;
  final String sort;
  final int limit;

  const TechnicianQuery({
    this.q,
    this.category,
    this.home = false,
    this.verified = false,
    this.minRating,
    this.sort = 'distance',
    this.limit = 20,
  });

  TechnicianQuery copyWith({
    String? q,
    String? category,
    bool clearCategory = false,
    bool? home,
    bool? verified,
    double? minRating,
    bool clearMinRating = false,
    String? sort,
  }) =>
      TechnicianQuery(
        q: q ?? this.q,
        category: clearCategory ? null : (category ?? this.category),
        home: home ?? this.home,
        verified: verified ?? this.verified,
        minRating: clearMinRating ? null : (minRating ?? this.minRating),
        sort: sort ?? this.sort,
        limit: limit,
      );

  @override
  bool operator ==(Object other) =>
      other is TechnicianQuery &&
      other.q == q &&
      other.category == category &&
      other.home == home &&
      other.verified == verified &&
      other.minRating == minRating &&
      other.sort == sort &&
      other.limit == limit;

  @override
  int get hashCode =>
      Object.hash(q, category, home, verified, minRating, sort, limit);
}

class TechniciansRepository {
  TechniciansRepository(this._api);
  final ApiClient _api;

  Future<List<TechnicianModel>> search(TechnicianQuery f, GeoPoint? loc) async {
    final body = await _api.get(ApiEndpoints.technicians, query: {
      'q': f.q,
      'cat': f.category,
      'home': f.home ? true : null,
      'verified': f.verified ? true : null,
      'minRating': f.minRating,
      'sort': f.sort,
      'lat': loc?.lat,
      'lng': loc?.lng,
      'limit': f.limit,
    });
    return asMapList(body['data']).map(TechnicianModel.fromJson).toList();
  }

  Future<TechnicianModel> detail(String id, GeoPoint? loc) async {
    final body = await _api.get(ApiEndpoints.technician(id),
        query: {'lat': loc?.lat, 'lng': loc?.lng});
    return TechnicianModel.fromJson(asMap(body['data']));
  }

  Future<void> setFavorite(String id, bool favorite) async {
    final path = '${ApiEndpoints.favorites}/$id';
    if (favorite) {
      await _api.post(path);
    } else {
      await _api.delete(path);
    }
  }
}

final techniciansRepositoryProvider = Provider<TechniciansRepository>(
    (ref) => TechniciansRepository(ref.watch(apiClientProvider)));

final techniciansSearchProvider = FutureProvider.autoDispose
    .family<List<TechnicianModel>, TechnicianQuery>((ref, query) async {
  final loc = await ref.watch(locationProvider.future);
  return ref.watch(techniciansRepositoryProvider).search(query, loc);
});

final technicianDetailProvider = FutureProvider.autoDispose
    .family<TechnicianModel, String>((ref, id) async {
  final loc = await ref.watch(locationProvider.future);
  return ref.watch(techniciansRepositoryProvider).detail(id, loc);
});
