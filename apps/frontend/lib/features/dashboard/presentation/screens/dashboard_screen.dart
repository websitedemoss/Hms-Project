import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/layout/responsive_helper.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final overviewAsync = ref.watch(dashboardOverviewProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardOverviewProvider);
          await ref.read(dashboardOverviewProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clinical Welcome Header
              FadeSlideIn(
                offset: -8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Clinical Dashboard',
                            style: AppTypography.headingLarge(),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Medicare Hospital & I.C.U • Real-Time Clinical Operations Center',
                            style: AppTypography.bodyMedium(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.circle, color: AppColors.success, size: 8),
                              const SizedBox(width: 6),
                              Text(
                                'Supabase Cloud Active',
                                style: AppTypography.labelSmall(color: const Color(0xFF047857)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.sync_rounded, size: 20, color: AppColors.textSecondaryLight),
                          tooltip: 'Refresh Metrics',
                          onPressed: () => ref.refresh(dashboardOverviewProvider),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              overviewAsync.when(
                loading: () => const SkeletonDashboard(),
                error: (error, stack) => Card(
                  color: AppColors.dangerLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Failed to load live metrics: $error',
                            style: AppTypography.bodyMedium(color: AppColors.danger),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => ref.refresh(dashboardOverviewProvider),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Retry'),
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
                      // 1. KPI Summary Cards Grid
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = ResponsiveHelper.getGridColumnCount(context);
                          return GridView.count(
                            crossAxisCount: columns,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: isDesktop ? 1.85 : 2.0,
                            children: [
                              FadeSlideIn(
                                delay: const Duration(milliseconds: 30),
                                child: _KpiCard(
                                  title: 'Total Patients',
                                  value: '${kpis.totalPatients}',
                                  subtitle: 'Verified longitudinal dossiers',
                                  icon: Icons.people_outline_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                              FadeSlideIn(
                                delay: const Duration(milliseconds: 60),
                                child: _KpiCard(
                                  title: "Today's Appointments",
                                  value: '${kpis.todayAppointments}',
                                  subtitle: '${kpis.waitingQueue} in queue • ${kpis.inConsultation} in consult',
                                  icon: Icons.calendar_today_rounded,
                                  color: const Color(0xFFD97706),
                                ),
                              ),
                              FadeSlideIn(
                                delay: const Duration(milliseconds: 90),
                                child: _KpiCard(
                                  title: 'Inpatient Beds',
                                  value: '${kpis.bedOccupancy.occupied} / ${kpis.bedOccupancy.total}',
                                  subtitle: '${kpis.bedOccupancy.ratePercent}% Total Occupancy Rate',
                                  icon: Icons.single_bed_rounded,
                                  color: AppColors.secondary,
                                ),
                              ),
                              FadeSlideIn(
                                delay: const Duration(milliseconds: 120),
                                child: _KpiCard(
                                  title: 'Specialists On Duty',
                                  value: '${kpis.activeDoctors}',
                                  subtitle: 'Cardiology, Neuro, Ortho, Med',
                                  icon: Icons.medical_services_outlined,
                                  color: AppColors.info,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 28),

                      // 2. Quick Clinical Actions Bar
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 150),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Clinical Workflows & Actions',
                              style: AppTypography.headingSmall(),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _ActionButton(
                                  icon: Icons.person_add_alt_1_rounded,
                                  label: 'Register Patient',
                                  color: AppColors.primary,
                                  onTap: () => context.go('/patients'),
                                ),
                                _ActionButton(
                                  icon: Icons.event_available_rounded,
                                  label: 'Book Consultation',
                                  color: AppColors.secondary,
                                  onTap: () => context.go('/appointments'),
                                ),
                                _ActionButton(
                                  icon: Icons.hourglass_top_rounded,
                                  label: 'Live Triage Queue',
                                  color: const Color(0xFFD97706),
                                  onTap: () => context.go('/appointments'),
                                ),
                                _ActionButton(
                                  icon: Icons.auto_awesome_rounded,
                                  label: 'BHOOMA AI Assistant',
                                  color: const Color(0xFF7C3AED),
                                  onTap: () => context.go('/bhooma-ai'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // 3. Bed Occupancy & Activity Stream Split
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 180),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Bed Occupancy Progress Card
                            Expanded(
                              flex: isDesktop ? 3 : 1,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Bed Capacity & Utilization',
                                          style: AppTypography.headingSmall(),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${kpis.bedOccupancy.ratePercent}% Used',
                                            style: AppTypography.monoMrn(color: AppColors.secondary, fontSize: 11),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // Smooth Progress Bar
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: (kpis.bedOccupancy.total > 0)
                                            ? (kpis.bedOccupancy.occupied / kpis.bedOccupancy.total).clamp(0.0, 1.0)
                                            : 0.0,
                                        minHeight: 10,
                                        backgroundColor: const Color(0xFFF1F5F9),
                                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _MetricPill(
                                          label: 'Occupied Beds',
                                          value: '${kpis.bedOccupancy.occupied}',
                                          color: AppColors.danger,
                                          icon: Icons.bed_rounded,
                                        ),
                                        _MetricPill(
                                          label: 'Available Beds',
                                          value: '${kpis.bedOccupancy.total - kpis.bedOccupancy.occupied}',
                                          color: AppColors.success,
                                          icon: Icons.check_circle_outline_rounded,
                                        ),
                                        _MetricPill(
                                          label: 'Total Capacity',
                                          value: '${kpis.bedOccupancy.total}',
                                          color: AppColors.primary,
                                          icon: Icons.domain_rounded,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // 4. Live Activity Stream Feed
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 210),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Recent Clinical Activity Log',
                                  style: AppTypography.headingSmall(),
                                ),
                                Text(
                                  'Live Stream',
                                  style: AppTypography.monoCode(color: AppColors.textSecondaryLight),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: overview.recentActivity.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                                      child: Center(
                                        child: Column(
                                          children: [
                                            const Icon(
                                              Icons.event_note_outlined,
                                              size: 40,
                                              color: AppColors.textSecondaryLight,
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              'No clinical events logged today yet',
                                              style: AppTypography.bodyMedium(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: overview.recentActivity.length,
                                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
                                      itemBuilder: (context, index) {
                                        final item = overview.recentActivity[index];
                                        return ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                          leading: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.08),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.assignment_outlined,
                                              size: 18,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          title: Text(
                                            '${item.patientName} (${item.patientMrn})',
                                            style: AppTypography.labelLarge(),
                                          ),
                                          subtitle: Text(
                                            item.description,
                                            style: AppTypography.bodySmall(),
                                          ),
                                          trailing: Text(
                                            item.eventTime,
                                            style: AppTypography.monoCode(
                                              color: AppColors.textSecondaryLight,
                                              fontSize: 12,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
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

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTypography.monoMrn(color: color, fontSize: 13)),
            Text(label, style: AppTypography.labelSmall()),
          ],
        ),
      ],
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
    return CardHover(
      borderRadius: 12,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
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
              style: AppTypography.monoKpi(fontSize: 26),
            ),
            Text(
              subtitle,
              style: AppTypography.labelSmall(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    return CardHover(
      onTap: onTap,
      borderRadius: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelLarge(),
            ),
          ],
        ),
      ),
    );
  }
}
