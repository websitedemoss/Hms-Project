class DoctorSlotItem {
  final String slot;
  final bool isAvailable;
  final String status;

  const DoctorSlotItem({
    required this.slot,
    required this.isAvailable,
    required this.status,
  });

  String get time => slot;
  bool get isBooked => !isAvailable;

  factory DoctorSlotItem.fromJson(Map<String, dynamic> json) {
    return DoctorSlotItem(
      slot: json['slot'] as String? ?? '',
      isAvailable: json['isAvailable'] as bool? ?? true,
      status: json['status'] as String? ?? 'Available',
    );
  }
}

class Doctor {
  final String id;
  final String name;
  final String? departmentId;
  final String? departmentName;
  final String? degree;
  final String? experience;
  final String? phone;
  final double consultationFee;
  final String status;

  const Doctor({
    required this.id,
    required this.name,
    this.departmentId,
    this.departmentName,
    this.degree,
    this.experience,
    this.phone,
    required this.consultationFee,
    required this.status,
  });

  String? get specialization => degree ?? experience ?? 'Consultant';

  factory Doctor.fromJson(Map<String, dynamic> json) {
    final dept = json['department'] as Map<String, dynamic>?;
    final fee = json['consultationFee'];
    return Doctor(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      departmentId: json['departmentId'] as String?,
      departmentName: dept?['name'] as String?,
      degree: json['degree'] as String?,
      experience: json['experience'] as String?,
      phone: json['phone'] as String?,
      consultationFee: fee is num ? fee.toDouble() : double.tryParse(fee?.toString() ?? '500') ?? 500.0,
      status: json['status'] as String? ?? 'Available',
    );
  }
}
