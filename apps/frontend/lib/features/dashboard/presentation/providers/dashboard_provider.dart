import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dashboard_repository.dart';
import '../../domain/models/dashboard_overview.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

final dashboardOverviewProvider = FutureProvider<DashboardOverview>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.fetchOverview();
});
