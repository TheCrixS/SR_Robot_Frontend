import 'json_utils.dart';

enum UserRole { client, technician, supplier, admin }

UserRole roleFromApi(String? v) => switch (v) {
      'TECHNICIAN' => UserRole.technician,
      'SUPPLIER' => UserRole.supplier,
      'ADMIN' => UserRole.admin,
      _ => UserRole.client,
    };

String roleToApi(UserRole r) => switch (r) {
      UserRole.technician => 'TECHNICIAN',
      UserRole.supplier => 'SUPPLIER',
      UserRole.admin => 'ADMIN',
      UserRole.client => 'CLIENT',
    };

class UserModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final List<UserRole> roles;
  final UserRole activeRole;
  final String country;
  final String locale;

  const UserModel({
    required this.id,
    required this.name,
    required this.roles,
    required this.activeRole,
    this.email,
    this.phone,
    this.country = 'CO',
    this.locale = 'es-CO',
  });

  String get firstName => name.trim().split(' ').first;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final a = parts.first[0];
    final b = parts.length > 1 ? parts[1][0] : '';
    return (a + b).toUpperCase();
  }

  bool get hasTechnicianRole => roles.contains(UserRole.technician);

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: asId(j['id']),
        name: asStr(j['name']) ?? '',
        email: asStr(j['email']),
        phone: asStr(j['phone']),
        roles: asStrList(j['roles']).map(roleFromApi).toList(),
        activeRole: roleFromApi(asStr(j['activeRole']) ?? asStr(j['role'])),
        country: asStr(j['country']) ?? 'CO',
        locale: asStr(j['locale']) ?? 'es-CO',
      );

  UserModel copyWith({UserRole? activeRole, String? country, String? locale}) =>
      UserModel(
        id: id,
        name: name,
        email: email,
        phone: phone,
        roles: roles,
        activeRole: activeRole ?? this.activeRole,
        country: country ?? this.country,
        locale: locale ?? this.locale,
      );
}
