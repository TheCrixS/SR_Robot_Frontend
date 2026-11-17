import 'json_utils.dart';
import 'order_model.dart';

class EquipmentModel {
  final String id;
  final String type;
  final String brand;
  final String model;
  final String? nickname;
  final DateTime? purchaseDate;
  final String warrantyStatus; // ACTIVE | EXPIRED | NONE
  final DateTime? warrantyExpiresAt;
  final String? lastServiceName;

  const EquipmentModel({
    required this.id,
    required this.type,
    required this.brand,
    required this.model,
    required this.warrantyStatus,
    this.nickname,
    this.purchaseDate,
    this.warrantyExpiresAt,
    this.lastServiceName,
  });

  String get title =>
      (nickname != null && nickname!.isNotEmpty) ? nickname! : '$brand $model';

  factory EquipmentModel.fromJson(Map<String, dynamic> j) {
    final w = asMap(j['warranty']);
    final last = j['lastService'];
    return EquipmentModel(
      id: asId(j['id']),
      type: asStr(j['type']) ?? '',
      brand: asStr(j['brand']) ?? '',
      model: asStr(j['model']) ?? '',
      nickname: asStr(j['nickname']),
      purchaseDate: asDate(j['purchaseDate']),
      warrantyStatus: asStr(w['status']) ?? 'NONE',
      warrantyExpiresAt: asDate(w['expiresAt']),
      lastServiceName: last is Map
          ? (asStr(last['serviceName']) ?? asStr(last['name']))
          : asStr(last),
    );
  }
}

class AddressModel {
  final String id;
  final String address;
  final String? label;
  final String? city;
  final String? notes;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.address,
    required this.isDefault,
    this.label,
    this.city,
    this.notes,
  });

  factory AddressModel.fromJson(Map<String, dynamic> j) => AddressModel(
        id: asId(j['id']),
        address: asStr(j['address']) ?? '',
        label: asStr(j['label']),
        city: asStr(j['city']),
        notes: asStr(j['notes']),
        isDefault: asBool(j['isDefault']),
      );
}

class SavedPaymentMethod {
  final String id;
  final String type;
  final String? brand;
  final String? last4;
  final String? holderName;
  final bool isDefault;

  const SavedPaymentMethod({
    required this.id,
    required this.type,
    required this.isDefault,
    this.brand,
    this.last4,
    this.holderName,
  });

  factory SavedPaymentMethod.fromJson(Map<String, dynamic> j) =>
      SavedPaymentMethod(
        id: asId(j['id']),
        type: asStr(j['type']) ?? 'CARD',
        brand: asStr(j['brand']),
        last4: asStr(j['last4']),
        holderName: asStr(j['holderName']),
        isDefault: asBool(j['isDefault']),
      );
}

class DisputeUpdate {
  final String? note;
  final String? author;
  final List<MediaItem> media;
  final DateTime? createdAt;
  const DisputeUpdate(this.note, this.author, this.media, this.createdAt);

  factory DisputeUpdate.fromJson(Map<String, dynamic> j) => DisputeUpdate(
        asStr(j['note']),
        asStr(j['authorName']) ?? asStr(j['by']) ?? asStr(j['role']),
        asMapList(j['media']).map(MediaItem.fromJson).toList(),
        asDate(j['createdAt'] ?? j['timestamp']),
      );
}

class DisputeModel {
  final String id;
  final String orderId;
  final String reason;
  final String description;
  final String status;
  final List<MediaItem> media;
  final List<DisputeUpdate> updates;
  final String? resolution;
  final DateTime? createdAt;

  const DisputeModel({
    required this.id,
    required this.orderId,
    required this.reason,
    required this.description,
    required this.status,
    required this.media,
    required this.updates,
    this.resolution,
    this.createdAt,
  });

  bool get isOpen => status == 'OPEN';

  factory DisputeModel.fromJson(Map<String, dynamic> j) {
    final res = j['resolution'];
    return DisputeModel(
      id: asId(j['id']),
      orderId: asId(j['orderId']),
      reason: asStr(j['reason']) ?? '',
      description: asStr(j['description']) ?? '',
      status: asStr(j['status']) ?? 'OPEN',
      media: asMapList(j['media']).map(MediaItem.fromJson).toList(),
      updates: asMapList(j['updates']).map(DisputeUpdate.fromJson).toList(),
      resolution: res is Map
          ? (asStr(res['note']) ?? asStr(res['decision']))
          : asStr(res),
      createdAt: asDate(j['createdAt']),
    );
  }
}
