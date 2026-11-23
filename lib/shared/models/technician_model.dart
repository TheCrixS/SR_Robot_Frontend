import '../../core/config/regional_profile.dart';
import 'json_utils.dart';

class TechService {
  final String id;
  final String name;
  final int priceFrom;
  final String estimatedTime;
  final int warrantyDays;
  final bool active;

  const TechService({
    required this.id,
    required this.name,
    required this.priceFrom,
    required this.estimatedTime,
    required this.warrantyDays,
    required this.active,
  });

  factory TechService.fromJson(Map<String, dynamic> j) => TechService(
        id: asId(j['id']),
        name: asStr(j['name']) ?? '',
        priceFrom: asInt(j['priceFrom']),
        estimatedTime: asStr(j['estimatedTime']) ?? '',
        warrantyDays: asInt(j['warrantyDays'], 90),
        active: asBool(j['active'], true),
      );
}

class ReviewModel {
  final String id;
  final String clientName;
  final int rating;
  final List<String> tags;
  final String? comment;
  final String? replyText;
  final DateTime? createdAt;

  const ReviewModel({
    required this.id,
    required this.clientName,
    required this.rating,
    required this.tags,
    this.comment,
    this.replyText,
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> j) => ReviewModel(
        id: asId(j['id']),
        clientName: asStr(j['clientName']) ?? '',
        rating: asInt(j['rating']),
        tags: asStrList(j['tags']),
        comment: asStr(j['comment']),
        replyText: asStr(asMap(j['reply'])['text']),
        createdAt: asDate(j['createdAt']),
      );
}

class DaySchedule {
  final bool enabled;
  final String open;
  final String close;
  const DaySchedule(this.enabled, this.open, this.close);
}

class TechnicianModel {
  final String id;
  final String businessName;
  final String description;
  final List<String> categories;
  final double rating;
  final int reviewsCount;
  final bool isVerified;
  final String plan;
  final double? lat;
  final double? lng;
  final String? address;
  final String? city;
  final bool homeService;
  final int homeExtraFee;
  final int coverageRadiusKm;
  final bool available;
  final String? responseTime;
  final Map<String, DaySchedule> schedule;
  final List<String> photos;
  final int completedOrders;
  final double? distanceKm;
  final List<TechService> services;
  final List<ReviewModel> reviews;
  final Map<int, int> ratingDistribution;
  final bool isFavorite;
  final String verificationStatus;

  /// Moneda de sus precios (`currency` o `country` del backend). Null → la del país activo.
  final String? currency;

  const TechnicianModel({
    required this.id,
    required this.businessName,
    required this.description,
    required this.categories,
    required this.rating,
    required this.reviewsCount,
    required this.isVerified,
    required this.plan,
    required this.homeService,
    required this.homeExtraFee,
    required this.coverageRadiusKm,
    required this.available,
    required this.schedule,
    required this.photos,
    required this.completedOrders,
    required this.services,
    required this.reviews,
    required this.ratingDistribution,
    required this.isFavorite,
    this.verificationStatus = 'PENDING',
    this.currency,
    this.lat,
    this.lng,
    this.address,
    this.city,
    this.responseTime,
    this.distanceKm,
  });

  bool get canQuote => verificationStatus == 'VERIFIED';

  String get mainCategory => categories.isEmpty ? '' : categories.first;

  String get initials {
    final parts = businessName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return (parts.first[0] + (parts.length > 1 ? parts[1][0] : ''))
        .toUpperCase();
  }

  int? get minPrice {
    final active = services.where((s) => s.active).toList();
    if (active.isEmpty) return null;
    return active.map((s) => s.priceFrom).reduce((a, b) => a < b ? a : b);
  }

  factory TechnicianModel.fromJson(Map<String, dynamic> j) {
    final loc = asMap(j['location']);
    final cats = asStrList(j['categories']);
    final schedRaw = asMap(j['schedule']);
    final distRaw = asMap(j['ratingDistribution']);
    return TechnicianModel(
      id: asId(j['id']),
      businessName: asStr(j['businessName']) ?? '',
      currency: asStr(j['currency']) ??
          asStr(loc['currency']) ??
          RegionProfile.currencyForCountry(
              asStr(j['country']) ?? asStr(loc['country'])),
      description: asStr(j['description']) ?? '',
      categories: cats.isNotEmpty
          ? cats
          : [if (j['category'] != null) j['category'].toString()],
      rating: asDouble(j['rating']),
      reviewsCount: asInt(j['reviewsCount']),
      isVerified: asBool(j['isVerified']),
      plan: asStr(j['plan']) ?? 'BASIC',
      lat: loc['lat'] == null ? null : asDouble(loc['lat']),
      lng: loc['lng'] == null ? null : asDouble(loc['lng']),
      address: asStr(loc['address']),
      city: asStr(loc['city']),
      homeService: asBool(j['homeService']),
      homeExtraFee: asInt(j['homeExtraFee']),
      coverageRadiusKm: asInt(j['coverageRadiusKm']),
      available: asBool(j['available'], true),
      responseTime: asStr(j['responseTime']),
      schedule: {
        for (final e in schedRaw.entries)
          e.key: DaySchedule(
            asBool(asMap(e.value)['enabled']),
            asStr(asMap(e.value)['open']) ?? '',
            asStr(asMap(e.value)['close']) ?? '',
          ),
      },
      photos: asStrList(j['photos']),
      completedOrders: asInt(j['completedOrders']),
      distanceKm: j['distanceKm'] == null ? null : asDouble(j['distanceKm']),
      services: asMapList(j['services']).map(TechService.fromJson).toList(),
      reviews: asMapList(j['reviews']).map(ReviewModel.fromJson).toList(),
      ratingDistribution: {
        for (final e in distRaw.entries)
          if (int.tryParse(e.key) != null) int.parse(e.key): asInt(e.value),
      },
      isFavorite: asBool(j['isFavorite']),
      verificationStatus: asStr(j['verificationStatus']) ??
          (asBool(j['isVerified']) ? 'VERIFIED' : 'PENDING'),
    );
  }
}
