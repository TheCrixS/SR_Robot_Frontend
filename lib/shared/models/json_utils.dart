/// Lectores tolerantes para JSON del backend.
String? asStr(Object? v) => v?.toString();

String asId(Object? v) => v?.toString() ?? '';

int asInt(Object? v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.round();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

double asDouble(Object? v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

bool asBool(Object? v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is String) return v == 'true';
  return fallback;
}

List<Map<String, dynamic>> asMapList(Object? v) => v is List
    ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : const [];

List<String> asStrList(Object? v) =>
    v is List ? v.map((e) => e.toString()).toList() : const [];

Map<String, dynamic> asMap(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

DateTime? asDate(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toLocal() : null;
