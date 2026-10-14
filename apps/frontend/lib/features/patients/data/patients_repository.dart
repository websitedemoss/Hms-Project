import 'dart:convert';
import '../../../core/services/api_client.dart';
import '../domain/models/patient.dart';

class PatientsRepository {
  Future<Map<String, dynamic>> fetchPatients({String? q, int page = 1, int limit = 15}) async {
    final queryParams = <String>[
      'page=$page',
      'limit=$limit',
      if (q != null && q.isNotEmpty) 'q=${Uri.encodeComponent(q)}',
    ].join('&');

    final response = await ApiClient.get('/patients?$queryParams');
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to fetch patients');
    }

    List<Patient> list = [];
    int total = 0;
    int pageNum = page;
    int totalPages = 1;

    final rawData = json['data'];
    if (rawData is List) {
      list = rawData.map((e) => Patient.fromJson(e as Map<String, dynamic>)).toList();
      final meta = json['meta'] as Map<String, dynamic>? ?? {};
      total = meta['total'] as int? ?? list.length;
      pageNum = meta['page'] as int? ?? page;
      totalPages = meta['totalPages'] as int? ?? 1;
    } else if (rawData is Map<String, dynamic>) {
      final listData = rawData['data'] as List<dynamic>? ?? [];
      list = listData.map((e) => Patient.fromJson(e as Map<String, dynamic>)).toList();
      final meta = rawData['meta'] as Map<String, dynamic>? ?? json['meta'] as Map<String, dynamic>? ?? {};
      total = meta['total'] as int? ?? list.length;
      pageNum = meta['page'] as int? ?? page;
      totalPages = meta['totalPages'] as int? ?? 1;
    }

    return {
      'patients': list,
      'total': total,
      'page': pageNum,
      'totalPages': totalPages,
    };
  }

  Future<Map<String, dynamic>> checkDuplicate({
    required String name,
    required String surname,
    String? phone,
  }) async {
    final response = await ApiClient.post('/patients/check-duplicate', body: {
      'name': name,
      'surname': surname,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Duplicate check failed');
    }
    return json['data'] as Map<String, dynamic>;
  }

  Future<Patient> createPatient(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/patients', body: data);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201 || json['success'] != true) {
      final msg = json['message'];
      final text = msg is List ? msg.join(', ') : (msg?.toString() ?? 'Failed to register patient');
      throw Exception(text);
    }
    return Patient.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getDossier(String id) async {
    final response = await ApiClient.get('/patients/$id/dossier');
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to fetch patient dossier');
    }
    return json['data'] as Map<String, dynamic>;
  }
}
