import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/appointment.dart';
import '../providers/appointments_provider.dart';
import '../widgets/appointment_booking_dialog.dart';
import '../widgets/clinical_workstation_modal.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  void _openBookingDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const AppointmentBookingDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final queueState = ref.watch(queueProvider);
    final appointmentsState = ref.watch(appointmentsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appointments & Triage Queue',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimaryLight,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Live token queues, stage progression, and clinical workstation',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh Queue & Appointments',
                        onPressed: () {
                          ref.read(queueProvider.notifier).loadQueue();
                          ref.read(appointmentsProvider.notifier).loadAppointments(appointmentsState.selectedDate);
                        },
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _openBookingDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Book Slot'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(140, 44),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tab Bar
              const TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondaryLight,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: "Today's Live Queue (Token Order)"),
                  Tab(text: "All Scheduled Appointments"),
                ],
              ),
              const SizedBox(height: 16),

              // Tab Views
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: Live Triage Queue
                    _buildLiveQueueTab(queueState),

                    // Tab 2: All Scheduled Appointments
                    _buildAllAppointmentsTab(appointmentsState),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 1: LIVE QUEUE ---
  Widget _buildLiveQueueTab(QueueState queue) {
    if (queue.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (queue.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(queue.errorMessage!, style: const TextStyle(color: AppColors.danger)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.read(queueProvider.notifier).loadQueue(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final allQueueAppointments = [
      ...queue.waiting,
      ...queue.inConsultation,
      ...queue.observation,
      ...queue.completed,
    ];

    if (allQueueAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.queue_outlined, size: 56, color: AppColors.textSecondaryLight),
            const SizedBox(height: 12),
            const Text(
              'No patients in today\'s queue yet.',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openBookingDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Book First Appointment'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Queue Stage Counts Header
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _StageCountBadge(
                label: 'Waiting in OPD',
                count: queue.waiting.length,
                color: AppColors.warning,
                icon: Icons.hourglass_top,
              ),
              const SizedBox(width: 10),
              _StageCountBadge(
                label: 'In Consultation',
                count: queue.inConsultation.length,
                color: AppColors.info,
                icon: Icons.medical_services,
              ),
              const SizedBox(width: 10),
              _StageCountBadge(
                label: 'Observation / Tests',
                count: queue.observation.length,
                color: AppColors.secondary,
                icon: Icons.biotech,
              ),
              const SizedBox(width: 10),
              _StageCountBadge(
                label: 'Completed',
                count: queue.completed.length,
                color: AppColors.success,
                icon: Icons.check_circle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Live Queue Cards List
        Expanded(
          child: ListView.separated(
            itemCount: allQueueAppointments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final appt = allQueueAppointments[index];
              return _QueueAppointmentCard(
                appointment: appt,
                onAdvanceStage: (nextStage, status) {
                  ref.read(queueProvider.notifier).updateStage(appt.id, nextStage, status: status);
                },
                onOpenWorkstation: () {
                  ClinicalWorkstationModal.show(context, appt);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TAB 2: ALL SCHEDULED APPOINTMENTS ---
  Widget _buildAllAppointmentsTab(AppointmentsState state) {
    return Column(
      children: [
        // Date selector row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Date: ${state.selectedDate}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.event, size: 16),
              label: const Text('Change Date'),
              onPressed: () async {
                final current = DateTime.tryParse(state.selectedDate) ?? DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: current,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 180)),
                );
                if (picked != null) {
                  final dateStr = picked.toIso8601String().split('T')[0];
                  ref.read(appointmentsProvider.notifier).loadAppointments(dateStr);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (state.isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (state.appointments.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'No appointments scheduled for ${state.selectedDate}',
                style: const TextStyle(color: AppColors.textSecondaryLight),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: state.appointments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final appt = state.appointments[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
                      child: Text('#${appt.tokenNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                    title: Text('${appt.patientName} (${appt.patientMrn})',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Dr. ${appt.doctorName} (${appt.departmentName}) • Slot: ${appt.slotTime} • Stage: ${_getStageLabel(appt.queueStage)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: OutlinedButton(
                      onPressed: () => ClinicalWorkstationModal.show(context, appt),
                      child: const Text('Workstation'),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  static String _getStageLabel(int stage) {
    switch (stage) {
      case 1:
        return 'Waiting';
      case 2:
        return 'In Consultation';
      case 3:
        return 'Observation';
      case 4:
        return 'Completed';
      default:
        return 'Stage $stage';
    }
  }
}

class _StageCountBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StageCountBadge({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '$count $label',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final void Function(int nextStage, String status) onAdvanceStage;
  final VoidCallback onOpenWorkstation;

  const _QueueAppointmentCard({
    required this.appointment,
    required this.onAdvanceStage,
    required this.onOpenWorkstation,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'in consultation':
        return AppColors.info;
      case 'observation':
        return AppColors.secondary;
      case 'admitted':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appt = appointment;
    final statusColor = _getStatusColor(appt.status);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      radius: 18,
                      child: Text(
                        '#${appt.tokenNumber}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${appt.patientName} (${appt.patientMrn})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          'Dr. ${appt.doctorName} • ${appt.departmentName}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    appt.status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: AppColors.textSecondaryLight),
                const SizedBox(width: 6),
                Text(appt.slotTime, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 16),
                const Icon(Icons.category_outlined, size: 16, color: AppColors.textSecondaryLight),
                const SizedBox(width: 6),
                Text('${appt.type} • Priority: ${appt.priority}', style: const TextStyle(fontSize: 13)),
                if (appt.chiefComplaints != null && appt.chiefComplaints!.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Complaint: ${appt.chiefComplaints}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Stage Progression Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (appt.queueStage == 1) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.call, size: 16),
                    label: const Text('Call Patient / In-Consultation'),
                    onPressed: () => onAdvanceStage(2, 'In Consultation'),
                  ),
                ] else if (appt.queueStage == 2) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.science_outlined, size: 16),
                    label: const Text('Send to Observation'),
                    onPressed: () => onAdvanceStage(3, 'Observation'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.medical_services_outlined, size: 16),
                    label: const Text('Open Clinical Workstation'),
                    onPressed: onOpenWorkstation,
                  ),
                ] else if (appt.queueStage == 3) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Discharge / Complete'),
                    onPressed: () => onAdvanceStage(4, 'Completed'),
                  ),
                ] else ...[
                  TextButton.icon(
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('View Workstation Notes'),
                    onPressed: onOpenWorkstation,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
