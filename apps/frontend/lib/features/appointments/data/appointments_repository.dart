import 'dart:convert';
import '../../../core/services/api_client.dart';
import '../domain/models/appointment.dart';

class AppointmentsRepository {
  Future<List<Appointment>> fetchAppointments({
    String? date,
    String? doctorId,
    String? status,
  }) async {
    final queryParams = <String>[
      if (date != null && date.isNotEmpty) 'date=$date',
      if (doctorId != null && doctorId.isNotEmpty) 'doctorId=$doctorId',
      if (status != null && status.isNotEmpty) 'status=$status',
    ].join('&');

    final response = await ApiClient.get('/appointments?$queryParams');
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to fetch appointments');
    }

    final list = json['data'] as List<dynamic>? ?? [];
    return list.map((e) => Appointment.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> fetchQueue({String? date}) async {
    final param = date != null ? '?date=$date' : '';
    final response = await ApiClient.get('/appointments/queue$param');
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to fetch queue');
    }

    final data = json['data'] as Map<String, dynamic>;
    final queue = data['queue'] as Map<String, dynamic>? ?? {};

    List<Appointment> parseList(dynamic raw) {
      return (raw as List<dynamic>?)
              ?.map((e) => Appointment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
    }

    return {
      'counts': data['counts'] as Map<String, dynamic>? ?? {},
      'waiting': parseList(queue['waiting']),
      'inConsultation': parseList(queue['inConsultation']),
      'observation': parseList(queue['observation']),
      'completed': parseList(queue['completed']),
    };
  }

  Future<Appointment> bookAppointment(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/appointments', body: data);
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 201 || json['success'] != true) {
      final msg = json['message'];
      final text = msg is List ? msg.join(', ') : (msg?.toString() ?? 'Booking failed');
      throw Exception(text);
    }

    return Appointment.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<Appointment> updateStage(
    int id,
    int stage, {
    String? status,
    String? doctorNotes,
  }) async {
    final response = await ApiClient.patch(
      '/appointments/$id/stage',
      body: {
        'stage': stage,
        if (status != null) 'status': status,
        if (doctorNotes != null) 'doctorNotes': doctorNotes,
      },
    );
    // Wait, let's check: ApiClient has PATCH or PUT? Let's check!
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to advance queue stage');
    }

    return Appointment.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> saveConsultation(
    int appointmentId,
    Map<String, dynamic> consultationData,
  ) async {
    final response = await ApiClient.post(
      '/consultations/$appointmentId',
      body: consultationData,
    );
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || json['success'] != true) {
      final msg = json['message'];
      final text = msg is List ? msg.join(', ') : (msg?.toString() ?? 'Failed to save consultation');
      throw Exception(text);
    }

    return json['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getConsultation(int appointmentId) async {
    final response = await ApiClient.get('/consultations/$appointmentId');
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to load consultation');
    }

    return json['data'] as Map<String, dynamic>;
  }
}
