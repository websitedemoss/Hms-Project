class AuthHospital {
  final int id;
  final String name;
  final String hospitalCode;
  final String? tagline;

  const AuthHospital({
    required this.id,
    required this.name,
    required this.hospitalCode,
    this.tagline,
  });

  factory AuthHospital.fromJson(Map<String, dynamic> json) {
    return AuthHospital(
      id: json['id'] as int? ?? 1,
      name: json['name'] as String? ?? 'Medicare Hospital & I.C.U',
      hospitalCode: json['hospitalCode'] as String? ?? 'MEDICARE-01',
      tagline: json['tagline'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'hospitalCode': hospitalCode,
        'tagline': tagline,
      };
}

class AuthUser {
  final int id;
  final String staffCode;
  final String username;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String role;
  final String department;
  final String? avatarUrl;
  final AuthHospital hospital;
  final List<String> permissions;

  const AuthUser({
    required this.id,
    required this.staffCode,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    required this.role,
    required this.department,
    this.avatarUrl,
    required this.hospital,
    required this.permissions,
  });

  String get fullName => '$firstName $lastName';

  bool hasPermission(String perm) {
    if (role == 'Super Admin' || role == 'Admin') return true;
    return permissions.contains(perm);
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int? ?? 0,
      staffCode: json['staffCode'] as String? ?? '',
      username: json['username'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'Staff',
      department: json['department'] as String? ?? 'General',
      avatarUrl: json['avatarUrl'] as String?,
      hospital: json['hospital'] != null
          ? AuthHospital.fromJson(json['hospital'] as Map<String, dynamic>)
          : const AuthHospital(
              id: 1,
              name: 'Medicare Hospital & I.C.U',
              hospitalCode: 'MEDICARE-01',
            ),
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'staffCode': staffCode,
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'role': role,
        'department': department,
        'avatarUrl': avatarUrl,
        'hospital': hospital.toJson(),
        'permissions': permissions,
      };
}
