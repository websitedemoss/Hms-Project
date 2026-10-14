import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/patient.dart';
import '../providers/patients_provider.dart';
import '../widgets/patient_registration_dialog.dart';
import '../widgets/patient_dossier_modal.dart';

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key});

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      ref.read(patientsProvider.notifier).search(query);
    });
  }

  void _openRegistrationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const PatientRegistrationDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientsState = ref.watch(patientsProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient Directory',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Search, register, and inspect longitudinal patient dossiers',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _openRegistrationDialog,
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('New Patient'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(150, 44),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search patients by Name, MRN (CP-2026-xxx), or Mobile...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondaryLight),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(patientsProvider.notifier).search('');
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // Error Banner
            if (patientsState.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        patientsState.errorMessage!,
                        style: const TextStyle(color: AppColors.danger, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.read(patientsProvider.notifier).loadPatients(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),

            // Patient Cards List
            Expanded(
              child: patientsState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : patientsState.patients.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_search_outlined, size: 56, color: AppColors.textSecondaryLight),
                              const SizedBox(height: 12),
                              Text(
                                patientsState.searchQuery.isNotEmpty
                                    ? 'No patients found matching "${patientsState.searchQuery}"'
                                    : 'No patients registered yet.',
                                style: const TextStyle(fontSize: 15, color: AppColors.textSecondaryLight),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _openRegistrationDialog,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Register First Patient'),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: patientsState.patients.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final patient = patientsState.patients[index];
                            return _PatientCard(
                              patient: patient,
                              onTap: () => PatientDossierModal.show(context, patient),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 12),

            // Pagination Controls Footer
            if (patientsState.total > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${patientsState.patients.length} of ${patientsState.total} patients',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: patientsState.page > 1
                            ? () => ref.read(patientsProvider.notifier).setPage(patientsState.page - 1)
                            : null,
                        child: const Text('Previous'),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Page ${patientsState.page} of ${patientsState.totalPages}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: patientsState.page < patientsState.totalPages
                            ? () => ref.read(patientsProvider.notifier).setPage(patientsState.page + 1)
                            : null,
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Patient patient;
  final VoidCallback onTap;

  const _PatientCard({
    required this.patient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                        radius: 20,
                        child: Text(
                          patient.firstName.isNotEmpty ? patient.firstName[0].toUpperCase() : 'P',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                patient.mrn,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '• ${patient.ageGender}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (patient.bloodGroup != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.dangerLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Blood: ${patient.bloodGroup}',
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: AppColors.textSecondaryLight),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 6),
                  Text(patient.phone ?? 'No phone', style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 20),
                  if (patient.emergencyContact != null) ...[
                    const Icon(Icons.emergency_outlined, size: 16, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Emergency: ${patient.emergencyContact!['name'] ?? ''} (${patient.emergencyContact!['phone'] ?? ''})',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
