import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/layout/responsive_helper.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final overviewAsync = ref.watch(dashboardOverviewProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardOverviewProvider);
          await ref.read(dashboardOverviewProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clinical Welcome Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clinical Dashboard',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimaryLight,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Medicare Hospital & I.C.U • Live Operations Command Center',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: AppColors.success, size: 10),
                            SizedBox(width: 6),
                            Text(
                              'Supabase Cloud Live',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: 'Refresh Metrics',
                        onPressed: () => ref.refresh(dashboardOverviewProvider),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              overviewAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Card(
                  color: AppColors.dangerLight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.danger),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Failed to load live metrics: $error',
                            style: const TextStyle(color: AppColors.danger, fontSize: 13),
                          ),
                        ),
                        TextButton(
                          onPressed: () => ref.refresh(dashboardOverviewProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (overview) {
                  final kpis = overview.kpis;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // KPI Summary Cards Grid
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = ResponsiveHelper.getGridColumnCount(context);
                          return GridView.count(
                            crossAxisCount: columns,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: isDesktop ? 1.8 : 2.1,
                            children: [
                              _KpiCard(
                                title: 'Total Patients',
                                value: '${kpis.totalPatients}',
                                subtitle: 'Registered in database',
                                icon: Icons.people_alt_outlined,
                                color: AppColors.primary,
                              ),
                              _KpiCard(
                                title: "Today's Appointments",
                                value: '${kpis.todayAppointments}',
                                subtitle: '${kpis.waitingQueue} waiting • ${kpis.inConsultation} in consultation',
                                icon: Icons.calendar_today_outlined,
                                color: AppColors.warning,
                              ),
                              _KpiCard(
                                title: 'Inpatient Beds',
                                value: '${kpis.bedOccupancy.occupied} / ${kpis.bedOccupancy.total}',
                                subtitle: '${kpis.bedOccupancy.ratePercent}% Bed Occupancy Rate',
                                icon: Icons.hotel_outlined,
                                color: AppColors.secondary,
                              ),
                              _KpiCard(
                                title: 'Doctors on Duty',
                                value: '${kpis.activeDoctors} Active',
                                subtitle: 'Cardio, Neuro, Ortho, Med',
                                icon: Icons.medical_services_outlined,
                                color: AppColors.info,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 28),

                      // Quick Actions Bar
                      Text(
                        'Quick Clinical Actions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _ActionButton(
                            icon: Icons.person_add_outlined,
                            label: 'Register Patient',
                            color: AppColors.primary,
                            onTap: () => context.go('/patients'),
                          ),
                          _ActionButton(
                            icon: Icons.calendar_today_outlined,
                            label: 'Book Appointment',
                            color: AppColors.secondary,
                            onTap: () => context.go('/appointments'),
                          ),
                          _ActionButton(
                            icon: Icons.filter_list_rounded,
                            label: 'Live Triage Queue',
                            color: AppColors.warning,
                            onTap: () => context.go('/appointments'),
                          ),
                          _ActionButton(
                            icon: Icons.auto_awesome,
                            label: 'BHOOMA AI Assistant',
                            color: const Color(0xFF7C3AED),
                            onTap: () => context.go('/bhooma-ai'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Live Activity Feed
                      Text(
                        'Recent Clinical Activity Stream',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: overview.recentActivity.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Center(
                                  child: Text(
                                    'No recent clinical events recorded today',
                                    style: TextStyle(color: AppColors.textSecondaryLight),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: overview.recentActivity.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = overview.recentActivity[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                      foregroundColor: AppColors.primary,
                                      child: const Icon(Icons.receipt_long, size: 18),
                                    ),
                                    title: Text(
                                      '${item.patientName} (${item.patientMrn})',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      item.description,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Text(
                                      item.eventTime,
                                      style: const TextStyle(
                                        color: AppColors.textSecondaryLight,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
