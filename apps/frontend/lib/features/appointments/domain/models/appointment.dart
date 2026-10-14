class DiagnosisItem {
  final int? id;
  final String? icd10Code;
  final String description;

  const DiagnosisItem({
    this.id,
    this.icd10Code,
    required this.description,
  });

  factory DiagnosisItem.fromJson(Map<String, dynamic> json) {
    return DiagnosisItem(
      id: json['id'] as int?,
      icd10Code: json['icd10Code'] as String?,
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        if (icd10Code != null) 'icd10Code': icd10Code,
        'description': description,
      };
}

class PrescriptionItem {
  final int? id;
  final String medicineName;
  final String dosage;
  final String frequency;
  final String duration;
  final String? instructions;

  const PrescriptionItem({
    this.id,
    required this.medicineName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions,
  });

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) {
    return PrescriptionItem(
      id: json['id'] as int?,
      medicineName: json['medicineName'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      frequency: json['frequency'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      instructions: json['instructions'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'medicineName': medicineName,
        'dosage': dosage,
        'frequency': frequency,
        'duration': duration,
        if (instructions != null) 'instructions': instructions,
      };
}

class Appointment {
  final int id;
  final String patientId;
  final String patientName;
  final String? patientPhone;
  final String doctorId;
  final String doctorName;
  final String? departmentName;
  final String date;
  final String slot;
  final int? tokenNumber;
  final String? symptoms;
  final String? allergies;
  final String status;
  final int stage;
  final String? bedNumber;
  final String? doctorNotes;
  final String bookingType;
  final List<DiagnosisItem> diagnoses;
  final List<PrescriptionItem> prescriptions;

  const Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.patientPhone,
    required this.doctorId,
    required this.doctorName,
    this.departmentName,
    required this.date,
    required this.slot,
    this.tokenNumber,
    this.symptoms,
    this.allergies,
    required this.status,
    required this.stage,
    this.bedNumber,
    this.doctorNotes,
    required this.bookingType,
    this.diagnoses = const [],
    this.prescriptions = const [],
  });

  String get patientMrn => patientId;
  String get slotTime => slot;
  int get queueStage => stage;
  String? get chiefComplaints => symptoms;
  String get type => bookingType;
  String get priority => 'Normal';

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final pat = json['patient'] as Map<String, dynamic>?;
    final doc = json['doctor'] as Map<String, dynamic>?;
    final rawDate = json['date']?.toString() ?? '';
    final cleanDate = rawDate.contains('T') ? rawDate.split('T')[0] : rawDate;

    return Appointment(
      id: json['id'] as int? ?? 0,
      patientId: json['patientId'] as String? ?? '',
      patientName: pat != null ? '${pat['name']} ${pat['surname']}' : (json['patientId']?.toString() ?? ''),
      patientPhone: pat?['phone'] as String?,
      doctorId: json['doctorId'] as String? ?? '',
      doctorName: doc?['name'] as String? ?? (json['doctorId']?.toString() ?? 'Doctor'),
      departmentName: doc?['department']?['name'] as String?,
      date: cleanDate,
      slot: json['slot'] as String? ?? '',
      tokenNumber: json['tokenNumber'] as int?,
      symptoms: json['symptoms'] as String?,
      allergies: json['allergies'] as String?,
      status: json['status'] as String? ?? 'Scheduled',
      stage: json['stage'] as int? ?? 1,
      bedNumber: json['bedNumber'] as String?,
      doctorNotes: json['doctorNotes'] as String?,
      bookingType: json['bookingType'] as String? ?? 'walk-in',
      diagnoses: (json['diagnoses'] as List<dynamic>?)
              ?.map((e) => DiagnosisItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      prescriptions: (json['prescriptions'] as List<dynamic>?)
              ?.map((e) => PrescriptionItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
