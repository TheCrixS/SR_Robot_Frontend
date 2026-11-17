import 'json_utils.dart';
import 'order_model.dart';

enum Urgency {
  low('LOW'),
  normal('NORMAL'),
  high('HIGH');

  const Urgency(this.api);
  final String api;
}

class QuoteRequestModel {
  final String id;
  final String deviceType;
  final String brandModel;
  final String issueDescription;
  final String status;
  final int quotesCount;
  final bool isHomeService;
  final Urgency urgency;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final List<MediaItem> media;
  final List<String> matchedTechnicianIds;
  // Vista del técnico
  final double? distanceKm;
  final String? myStatus;
  final String? clientName;
  final String? address;
  final int? myQuotePrice;

  const QuoteRequestModel({
    required this.id,
    required this.deviceType,
    required this.brandModel,
    required this.issueDescription,
    required this.status,
    required this.quotesCount,
    required this.isHomeService,
    required this.urgency,
    required this.media,
    required this.matchedTechnicianIds,
    this.expiresAt,
    this.createdAt,
    this.distanceKm,
    this.myStatus,
    this.clientName,
    this.address,
    this.myQuotePrice,
  });

  bool get isOpen => status == 'OPEN';

  factory QuoteRequestModel.fromJson(Map<String, dynamic> j) =>
      QuoteRequestModel(
        id: asId(j['id']),
        deviceType: asStr(j['deviceType']) ?? '',
        brandModel: asStr(j['brandModel']) ?? '',
        issueDescription: asStr(j['issueDescription']) ?? '',
        status: asStr(j['status']) ?? 'OPEN',
        quotesCount: asInt(j['quotesCount']),
        isHomeService: asBool(j['isHomeService']),
        urgency: Urgency.values.firstWhere((u) => u.api == j['urgency'],
            orElse: () => Urgency.normal),
        media: asMapList(j['media']).map(MediaItem.fromJson).toList(),
        matchedTechnicianIds: asStrList(j['matchedTechnicianIds']),
        expiresAt: asDate(j['expiresAt']),
        createdAt: asDate(j['createdAt']),
        distanceKm: j['distanceKm'] == null ? null : asDouble(j['distanceKm']),
        myStatus: asStr(j['myStatus']),
        clientName: asStr(j['clientName']) ?? asStr(asMap(j['client'])['name']),
        address: asStr(j['address']),
        myQuotePrice: j['myQuote'] is Map
            ? asInt((j['myQuote'] as Map)['price'])
            : null,
      );
}

class QuoteModel {
  final String id;
  final String requestId;
  final String technicianId;
  final String technicianName;
  final double technicianRating;
  final int price;
  final String estimatedTime;
  final int estimatedHours;
  final int warrantyDays;
  final String? message;
  final String status;
  final List<String> tags;

  const QuoteModel({
    required this.id,
    required this.requestId,
    required this.technicianId,
    required this.technicianName,
    required this.technicianRating,
    required this.price,
    required this.estimatedTime,
    required this.estimatedHours,
    required this.warrantyDays,
    required this.status,
    required this.tags,
    this.message,
  });

  bool get isBestPrice => tags.contains('BEST_PRICE');
  bool get isFastest => tags.contains('FASTEST');
  bool get isBestRated => tags.contains('BEST_RATED');

  factory QuoteModel.fromJson(Map<String, dynamic> j) => QuoteModel(
        id: asId(j['id']),
        requestId: asId(j['requestId']),
        technicianId: asId(j['technicianId']),
        technicianName: asStr(j['technicianName']) ?? '',
        technicianRating: asDouble(j['technicianRating']),
        price: asInt(j['price']),
        estimatedTime: asStr(j['estimatedTime']) ?? '',
        estimatedHours: asInt(j['estimatedHours']),
        warrantyDays: asInt(j['warrantyDays'], 90),
        message: asStr(j['message']),
        status: asStr(j['status']) ?? 'PENDING',
        tags: asStrList(j['tags']),
      );
}

/// Respuesta de `GET /quote-requests/:id/quotes`.
class QuotesResult {
  final List<QuoteModel> quotes;
  final bool waiting;
  final String status;
  final DateTime? expiresAt;
  const QuotesResult(this.quotes, this.waiting, this.status, this.expiresAt);
}
