import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        'Manage live token queues, slots, and clinical stages',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Book Slot'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(140, 44),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

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

              Expanded(
                child: TabBarView(
                  children: [
                    ListView(
                      children: const [
                        _AppointmentTile(
                          tokenNumber: 1,
                          patient: 'Ramesh Patel (CP-2026-001)',
                          doctor: 'Dr. Rajesh Sharma (Cardiology)',
                          slot: '10:00 AM • Walk-in',
                          symptoms: 'Mild chest tightness, shortness of breath',
                          status: 'Completed',
                          statusColor: AppColors.success,
                          stage: 4,
                        ),
                        SizedBox(height: 12),
                        _AppointmentTile(
                          tokenNumber: 2,
                          patient: 'Meena Shah (CP-2026-002)',
                          doctor: 'Dr. Priya Desai (Neurology)',
                          slot: '10:30 AM • Online Booking',
                          symptoms: 'Recurring migraine with visual aura',
                          status: 'In Consultation',
                          statusColor: AppColors.warning,
                          stage: 3,
                        ),
                      ],
                    ),
                    const Center(child: Text('All appointments list')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final int tokenNumber;
  final String patient;
  final String doctor;
  final String slot;
  final String symptoms;
  final String status;
  final Color statusColor;
  final int stage;

  const _AppointmentTile({
    required this.tokenNumber,
    required this.patient,
    required this.doctor,
    required this.slot,
    required this.symptoms,
    required this.status,
    required this.statusColor,
    required this.stage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      foregroundColor: AppColors.primary,
                      radius: 18,
                      child: Text('#$tokenNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patient, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(doctor, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
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
                    status,
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
                Text(slot, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 20),
                const Icon(Icons.healing_outlined, size: 16, color: AppColors.textSecondaryLight),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    symptoms,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
