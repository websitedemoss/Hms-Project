import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../domain/models/patient.dart';
import '../providers/patients_provider.dart';

class PatientDossierModal extends ConsumerWidget {
  final Patient patient;

  const PatientDossierModal({super.key, required this.patient});

  static Future<void> show(BuildContext context, Patient patient) {
    return showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 720),
          child: PatientDossierModal(patient: patient),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dossierAsync = ref.watch(patientDossierProvider(patient.id));

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      patient.firstName.isNotEmpty ? patient.firstName[0].toUpperCase() : 'P',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.fullName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              patient.mrn,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${patient.ageGender} • Blood: ${patient.bloodGroup ?? "N/A"}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Longitudinal Dossier Content
          Expanded(
            child: dossierAsync.when(
              loading: () => const Shimmer(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SkeletonBox(width: 160, height: 32, borderRadius: 8),
                          SizedBox(width: 12),
                          SkeletonBox(width: 140, height: 32, borderRadius: 8),
                          SizedBox(width: 12),
                          SkeletonBox(width: 160, height: 32, borderRadius: 8),
                        ],
                      ),
                      SizedBox(height: 24),
                      SkeletonBox(width: double.infinity, height: 110, borderRadius: 12),
                      SizedBox(height: 16),
                      SkeletonBox(width: double.infinity, height: 110, borderRadius: 12),
                      SizedBox(height: 16),
                      SkeletonBox(width: double.infinity, height: 110, borderRadius: 12),
                    ],
                  ),
                ),
              ),
              error: (e, _) => Center(
                child: Text('Error loading clinical dossier: $e', style: AppTypography.bodyMedium(color: AppColors.danger)),
              ),
              data: (dossier) {
                final appointments = dossier['appointments'] as List<dynamic>? ?? [];
                final timeline = dossier['timelineEvents'] as List<dynamic>? ?? [];

                return DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondaryLight,
                        indicatorColor: AppColors.primary,
                        tabs: [
                          Tab(text: 'Clinical Consultations & Rx'),
                          Tab(text: 'Patient Timeline'),
                          Tab(text: 'Demographics & Contacts'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // 1. Consultations & Rx Tab
                            appointments.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No consultation records found for this patient.',
                                      style: TextStyle(color: AppColors.textSecondaryLight),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: appointments.length,
                                    itemBuilder: (context, idx) {
                                      final appt = appointments[idx] is Map ? Map<String, dynamic>.from(appointments[idx] as Map) : <String, dynamic>{};
                                      final doc = appt['doctor'] is Map ? Map<String, dynamic>.from(appt['doctor'] as Map) : null;
                                      final diagnoses = appt['diagnoses'] as List<dynamic>? ?? [];
                                      final prescriptions = appt['prescriptions'] as List<dynamic>? ?? [];

                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Visit Date: ${appt['date'] ?? 'N/A'} (Token #${appt['tokenNumber'] ?? 1})',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                  ),
                                                  Text(
                                                    'Dr. ${doc?['name'] ?? 'Consultant'}',
                                                    style: const TextStyle(
                                                        color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                              if (appt['chiefComplaints'] != null) ...[
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Chief Complaints: ${appt['chiefComplaints']}',
                                                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimaryLight),
                                                ),
                                              ],
                                              // Diagnoses
                                              if (diagnoses.isNotEmpty) ...[
                                                const SizedBox(height: 10),
                                                const Text('Diagnoses (ICD-10):',
                                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 4),
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 4,
                                                  children: diagnoses.map((d) {
                                                    return Chip(
                                                      label: Text(
                                                        '${d['icdCode'] ?? ''}: ${d['description'] ?? ''}',
                                                        style: const TextStyle(fontSize: 11),
                                                      ),
                                                      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                                                      padding: EdgeInsets.zero,
                                                      visualDensity: VisualDensity.compact,
                                                    );
                                                  }).toList(),
                                                ),
                                              ],
                                              // Prescriptions
                                              if (prescriptions.isNotEmpty) ...[
                                                const SizedBox(height: 10),
                                                const Text('Prescribed Medications (Rx):',
                                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 4),
                                                ...prescriptions.map((rx) {
                                                  return Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.medication, size: 14, color: AppColors.secondary),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          '${rx['medicineName']} ${rx['dosage'] ?? ''}',
                                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.infoLight,
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            '${rx['frequency']} (${rx['duration'] ?? 3} days)',
                                                            style: const TextStyle(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.bold,
                                                              color: AppColors.info,
                                                            ),
                                                          ),
                                                        ),
                                                        if (rx['instructions'] != null) ...[
                                                          const SizedBox(width: 8),
                                                          Expanded(
                                                            child: Text(
                                                              '• ${rx['instructions']}',
                                                              style: const TextStyle(
                                                                  fontSize: 11, color: AppColors.textSecondaryLight),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  );
                                                }),
                                              ],
                                              // Doctor Notes
                                              if (appt['doctorNotes'] != null) ...[
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Doctor Clinical Notes: ${appt['doctorNotes']}',
                                                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                            // 2. Patient Timeline Tab
                            timeline.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No timeline events logged yet.',
                                      style: TextStyle(color: AppColors.textSecondaryLight),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: timeline.length,
                                    itemBuilder: (context, idx) {
                                      final item = timeline[idx] is Map ? Map<String, dynamic>.from(timeline[idx] as Map) : <String, dynamic>{};
                                      final eventType = item['eventType'] as String? ?? 'Event';
                                      final desc = item['description'] as String? ?? '';
                                      final createdAt = item['createdAt'] as String? ?? '';

                                      return ListTile(
                                        leading: const Icon(Icons.circle, size: 10, color: AppColors.primary),
                                        title: Text(eventType, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                        subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
                                        trailing: Text(
                                          createdAt.split('T')[0],
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                                        ),
                                      );
                                    },
                                  ),

                            // 3. Demographics & Contacts Tab
                            SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _InfoRow(label: 'Full Legal Name', value: patient.fullName),
                                  _InfoRow(label: 'Medical Record Number (MRN)', value: patient.mrn),
                                  _InfoRow(label: 'Biometric QR Token', value: patient.qrToken ?? 'Not generated'),
                                  _InfoRow(label: 'Gender / DOB', value: '${patient.gender ?? "N/A"} • ${patient.dateOfBirth ?? "N/A"}'),
                                  _InfoRow(label: 'Blood Group', value: patient.bloodGroup ?? 'Not recorded'),
                                  _InfoRow(label: 'Primary Phone', value: patient.phone ?? 'None'),
                                  _InfoRow(label: 'Email', value: patient.email ?? 'None'),
                                  _InfoRow(label: 'Residential Address', value: patient.address ?? 'None'),
                                  if (patient.emergencyContact != null) ...[
                                    const SizedBox(height: 12),
                                    const Text('Emergency Contact:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    _InfoRow(
                                      label: patient.emergencyContact!['name']?.toString() ?? 'Contact',
                                      value:
                                          '${patient.emergencyContact!['phone'] ?? ''} (${patient.emergencyContact!['relation'] ?? ''})',
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
            ),
          ),
        ],
      ),
    );
  }
}
