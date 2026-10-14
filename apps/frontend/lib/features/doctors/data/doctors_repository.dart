import 'dart:convert';
import '../../../core/services/api_client.dart';
import '../domain/models/doctor.dart';

class DoctorsRepository {
  Future<List<Doctor>> fetchDoctors() async {
    final response = await ApiClient.get('/doctors');
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to fetch doctors');
    }

    final list = json['data'] as List<dynamic>? ?? [];
    return list.map((e) => Doctor.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> fetchAvailableSlots(String doctorId, String date) async {
    final response = await ApiClient.get('/doctors/$doctorId/slots?date=$date');
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to fetch slots');
    }

    final data = json['data'] as Map<String, dynamic>;
    final rawSlots = data['slots'] as List<dynamic>? ?? [];
    final slots = rawSlots.map((e) => DoctorSlotItem.fromJson(e as Map<String, dynamic>)).toList();

    return {
      'date': data['date'] as String? ?? date,
      'availableCount': data['availableCount'] as int? ?? 0,
      'totalSlots': data['totalSlots'] as int? ?? slots.length,
      'slots': slots,
    };
  }
}
