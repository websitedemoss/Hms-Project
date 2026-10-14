class Patient {
  final String id;
  final String name;
  final String surname;
  final String? fatherName;
  final String? phone;
  final int? age;
  final String? gender;
  final String? bloodGroup;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? qrToken;
  final DateTime? createdAt;
  final int appointmentsCount;
  final int filesCount;

  const Patient({
    required this.id,
    required this.name,
    required this.surname,
    this.fatherName,
    this.phone,
    this.age,
    this.gender,
    this.bloodGroup,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.qrToken,
    this.createdAt,
    this.appointmentsCount = 0,
    this.filesCount = 0,
  });

  String get mrn => id;
  String get firstName => name;
  String get lastName => surname;
  String get fullName => '$name $surname';
  String get ageGender => '${age ?? "?"} Yrs • ${gender ?? "Unknown"}';
  String? get address => null;
  String? get dateOfBirth => null;
  String? get email => null;

  Map<String, dynamic>? get emergencyContact =>
      (emergencyContactName != null && emergencyContactName!.isNotEmpty)
          ? {
              'name': emergencyContactName,
              'phone': emergencyContactPhone ?? '',
              'relation': 'Emergency Contact',
            }
          : null;

  factory Patient.fromJson(Map<String, dynamic> json) {
    final count = json['_count'] is Map ? Map<String, dynamic>.from(json['_count'] as Map) : null;
    return Patient(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      surname: json['surname'] as String? ?? '',
      fatherName: json['fatherName'] as String?,
      phone: json['phone'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      bloodGroup: json['bloodGroup'] as String?,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      qrToken: json['qrToken'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      appointmentsCount: count?['appointments'] as int? ?? 0,
      filesCount: count?['patientFiles'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'surname': surname,
        'fatherName': fatherName,
        'phone': phone,
        'age': age,
        'gender': gender,
        'bloodGroup': bloodGroup,
        'emergencyContactName': emergencyContactName,
        'emergencyContactPhone': emergencyContactPhone,
        'qrToken': qrToken,
      };
}
