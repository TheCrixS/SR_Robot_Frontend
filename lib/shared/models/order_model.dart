import 'json_utils.dart';

/// Los 5 estados secuenciales que muestra la línea de tiempo.
enum OrderState {
  solicitado('SOLICITADO'),
  diagnostico('DIAGNOSTICO'),
  enReparacion('EN_REPARACION'),
  listo('LISTO'),
  entregado('ENTREGADO'),
  cancelado('CANCELADO'),
  disputa('DISPUTA');

  const OrderState(this.api);
  final String api;

  static OrderState fromApi(String? v) => OrderState.values
      .firstWhere((s) => s.api == v, orElse: () => OrderState.solicitado);

  static const sequence = [solicitado, diagnostico, enReparacion, listo, entregado];

  int get step => sequence.indexOf(this);
}

class MediaItem {
  final String url;
  final String type;
  const MediaItem(this.url, this.type);

  factory MediaItem.fromJson(Map<String, dynamic> j) =>
      MediaItem(asStr(j['url']) ?? '', asStr(j['type']) ?? 'IMAGE');
}

class TimelineEntry {
  final OrderState state;
  final String? note;
  final List<MediaItem> media;
  final DateTime? timestamp;

  const TimelineEntry(this.state, this.note, this.media, this.timestamp);

  factory TimelineEntry.fromJson(Map<String, dynamic> j) => TimelineEntry(
        OrderState.fromApi(asStr(j['state'])),
        asStr(j['note']),
        asMapList(j['media']).map(MediaItem.fromJson).toList(),
        asDate(j['timestamp']),
      );
}

class Adjustment {
  final String id;
  final int amount;
  final String reason;
  final String status;
  const Adjustment(this.id, this.amount, this.reason, this.status);

  factory Adjustment.fromJson(Map<String, dynamic> j) => Adjustment(
        asId(j['id']),
        asInt(j['amount']),
        asStr(j['reason']) ?? '',
        asStr(j['status']) ?? 'PENDING',
      );
}

class OrderModel {
  final String id;
  final String clientName;
  final String technicianId;
  final String technicianName;
  final String serviceName;
  final int amount;
  final int baseAmount;
  final int homeFee;
  final int adjustmentsTotal;
  final int platformFee;
  /// Moneda en que se cobró la orden. Null si el backend no la envía.
  final String? currency;
  final bool isHomeService;
  final String? address;
  final String paymentMethod;
  final OrderState state;
  final String escrowStatus;
  final DateTime? estimatedDelivery;
  final DateTime? createdAt;
  final List<TimelineEntry> timeline;
  final Adjustment? pendingAdjustment;
  final int warrantyDays;
  final DateTime? warrantyExpiresAt;
  final bool warrantyActive;
  final bool reviewed;

  const OrderModel({
    required this.id,
    required this.clientName,
    required this.technicianId,
    required this.technicianName,
    required this.serviceName,
    required this.amount,
    required this.baseAmount,
    required this.homeFee,
    required this.adjustmentsTotal,
    required this.platformFee,
    this.currency,
    required this.isHomeService,
    required this.paymentMethod,
    required this.state,
    required this.escrowStatus,
    required this.timeline,
    required this.warrantyDays,
    required this.warrantyActive,
    required this.reviewed,
    this.address,
    this.estimatedDelivery,
    this.createdAt,
    this.pendingAdjustment,
    this.warrantyExpiresAt,
  });

  bool get isActive =>
      state != OrderState.entregado &&
      state != OrderState.cancelado;

  factory OrderModel.fromJson(Map<String, dynamic> j) {
    final pb = asMap(j['paymentBreakdown']);
    final w = asMap(j['warranty']);
    final adj = j['pendingAdjustment'];
    final timeline =
        asMapList(j['timeline']).map(TimelineEntry.fromJson).toList();
    return OrderModel(
      id: asId(j['id']),
      clientName: asStr(j['clientName']) ?? '',
      technicianId: asId(j['technicianId']),
      technicianName: asStr(j['technicianName']) ?? '',
      serviceName: asStr(j['serviceName']) ?? asStr(j['description']) ?? '',
      amount: asInt(j['amount']),
      baseAmount: asInt(pb['service'] ?? j['baseAmount']),
      homeFee: asInt(pb['homeFee'] ?? j['homeFee']),
      adjustmentsTotal: asInt(pb['adjustments'] ?? j['adjustmentsTotal']),
      platformFee: asInt(pb['platformFee']),
      currency: asStr(j['currency']) ?? asStr(pb['currency']),
      isHomeService: asBool(j['isHomeService']),
      address: asStr(j['address']),
      paymentMethod: asStr(j['paymentMethod']) ?? '',
      state: OrderState.fromApi(asStr(j['state'])),
      escrowStatus: asStr(j['escrowStatus']) ?? '',
      estimatedDelivery: asDate(j['estimatedDelivery']),
      createdAt: asDate(j['createdAt']) ??
          (timeline.isNotEmpty ? timeline.first.timestamp : null),
      timeline: timeline,
      pendingAdjustment: adj is Map
          ? Adjustment.fromJson(Map<String, dynamic>.from(adj))
          : null,
      warrantyDays: asInt(w['days'], 90),
      warrantyExpiresAt: asDate(w['expiresAt']),
      warrantyActive: asBool(w['active']),
      reviewed: asBool(j['reviewed']),
    );
  }
}
