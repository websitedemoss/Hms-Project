import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/layout/responsive_helper.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      body: SingleChildScrollView(
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
                        'Medicare Hospital & I.C.U • Live Hospital Overview',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
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
                        'PostgreSQL Live',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

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
                  children: const [
                    _KpiCard(
                      title: 'Total Patients',
                      value: '1,428',
                      subtitle: '+12 registered today',
                      icon: Icons.people_alt_outlined,
                      color: AppColors.primary,
                    ),
                    _KpiCard(
                      title: "Today's Appointments",
                      value: '24',
                      subtitle: '4 currently waiting in queue',
                      icon: Icons.calendar_today_outlined,
                      color: AppColors.warning,
                    ),
                    _KpiCard(
                      title: 'Inpatient Beds',
                      value: '8 / 10',
                      subtitle: '2 ICU beds available',
                      icon: Icons.hotel_outlined,
                      color: AppColors.secondary,
                    ),
                    _KpiCard(
                      title: 'Doctors on Duty',
                      value: '4 Active',
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
                  label: 'Register Walk-in',
                  color: AppColors.primary,
                  onTap: () {},
                ),
                _ActionButton(
                  icon: Icons.add_circle_outline,
                  label: 'Book Appointment',
                  color: AppColors.secondary,
                  onTap: () {},
                ),
                _ActionButton(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Assign Next Token',
                  color: AppColors.warning,
                  onTap: () {},
                ),
                _ActionButton(
                  icon: Icons.auto_awesome,
                  label: 'BHOOMA AI Assistant',
                  color: const Color(0xFF7C3AED),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Live Queue & Triage Section
            Text(
              'Active Patient Queue (Triage Stage)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _QueueListTile(
                    tokenNumber: 1,
                    patientName: 'Ramesh Patel (54 M)',
                    mrn: 'CP-2026-001',
                    doctor: 'Dr. Rajesh Sharma',
                    dept: 'Cardiology',
                    status: 'In Consultation',
                    statusColor: AppColors.success,
                  ),
                  Divider(),
                  _QueueListTile(
                    tokenNumber: 2,
                    patientName: 'Meena Shah (36 F)',
                    mrn: 'CP-2026-002',
                    doctor: 'Dr. Priya Desai',
                    dept: 'Neurology',
                    status: 'Waiting in OPD',
                    statusColor: AppColors.warning,
                  ),
                  Divider(),
                  _QueueListTile(
                    tokenNumber: 3,
                    patientName: 'Vikram Joshi (42 M)',
                    mrn: 'CP-2026-003',
                    doctor: 'Dr. Amit Verma',
                    dept: 'Orthopedics',
                    status: 'Vitals Checked',
                    statusColor: AppColors.info,
                  ),
                ],
              ),
            ),
          ],
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

class _QueueListTile extends StatelessWidget {
  final int tokenNumber;
  final String patientName;
  final String mrn;
  final String doctor;
  final String dept;
  final String status;
  final Color statusColor;

  const _QueueListTile({
    required this.tokenNumber,
    required this.patientName,
    required this.mrn,
    required this.doctor,
    required this.dept,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        foregroundColor: AppColors.primary,
        child: Text(
          '#$tokenNumber',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        patientName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text('$mrn • $doctor ($dept)', style: const TextStyle(fontSize: 12)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
