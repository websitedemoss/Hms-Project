class BedOccupancy {
  final int occupied;
  final int total;
  final int ratePercent;

  const BedOccupancy({
    required this.occupied,
    required this.total,
    required this.ratePercent,
  });

  factory BedOccupancy.fromJson(Map<String, dynamic> json) {
    return BedOccupancy(
      occupied: json['occupied'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      ratePercent: json['ratePercent'] as int? ?? 0,
    );
  }
}

class DashboardKpis {
  final int totalPatients;
  final int todayAppointments;
  final int waitingQueue;
  final int inConsultation;
  final BedOccupancy bedOccupancy;
  final int activeDoctors;
  final int emergencyCases;

  const DashboardKpis({
    required this.totalPatients,
    required this.todayAppointments,
    required this.waitingQueue,
    required this.inConsultation,
    required this.bedOccupancy,
    required this.activeDoctors,
    required this.emergencyCases,
  });

  factory DashboardKpis.fromJson(Map<String, dynamic> json) {
    return DashboardKpis(
      totalPatients: json['totalPatients'] as int? ?? 0,
      todayAppointments: json['todayAppointments'] as int? ?? 0,
      waitingQueue: json['waitingQueue'] as int? ?? 0,
      inConsultation: json['inConsultation'] as int? ?? 0,
      bedOccupancy: json['bedOccupancy'] != null
          ? BedOccupancy.fromJson(json['bedOccupancy'] as Map<String, dynamic>)
          : const BedOccupancy(occupied: 0, total: 0, ratePercent: 0),
      activeDoctors: json['activeDoctors'] as int? ?? 0,
      emergencyCases: json['emergencyCases'] as int? ?? 0,
    );
  }
}

class ActivityItem {
  final int id;
  final String patientMrn;
  final String patientName;
  final String eventTime;
  final String description;
  final DateTime? createdAt;

  const ActivityItem({
    required this.id,
    required this.patientMrn,
    required this.patientName,
    required this.eventTime,
    required this.description,
    this.createdAt,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id'] as int? ?? 0,
      patientMrn: json['patientMrn'] as String? ?? '',
      patientName: json['patientName'] as String? ?? '',
      eventTime: json['eventTime'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
}

class DashboardOverview {
  final DashboardKpis kpis;
  final List<ActivityItem> recentActivity;

  const DashboardOverview({
    required this.kpis,
    required this.recentActivity,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    final kpisMap = json['kpis'] as Map<String, dynamic>? ?? {};
    final activityList = json['recentActivity'] as List<dynamic>? ?? [];

    return DashboardOverview(
      kpis: DashboardKpis.fromJson(kpisMap),
      recentActivity: activityList.map((e) => ActivityItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
