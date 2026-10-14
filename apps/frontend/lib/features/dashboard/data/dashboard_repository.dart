import 'dart:convert';
import '../../../core/services/api_client.dart';
import '../domain/models/dashboard_overview.dart';

class DashboardRepository {
  Future<DashboardOverview> fetchOverview() async {
    final response = await ApiClient.get('/dashboard/overview');
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || json['success'] != true) {
      throw Exception(json['message'] ?? 'Failed to load dashboard overview');
    }

    final data = json['data'] as Map<String, dynamic>;
    return DashboardOverview.fromJson(data);
  }
}
