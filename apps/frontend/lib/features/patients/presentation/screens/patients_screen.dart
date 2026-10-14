import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/fade_slide_in.dart';
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
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
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
      backgroundColor: AppColors.backgroundLight,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
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
                          'Patient Directory',
                          style: AppTypography.headingLarge(),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Search, register, and inspect longitudinal clinical dossiers & history',
                          style: AppTypography.bodyMedium(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _openRegistrationDialog,
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('New Patient'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(160, 44),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Search Bar with Clean Micro-styling
            FadeSlideIn(
              delay: const Duration(milliseconds: 50),
              offset: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: AppTypography.bodyLarge(),
                  decoration: InputDecoration(
                    hintText: 'Search patients by Name, MRN (e.g. CP-2026-001), or Mobile number...',
                    hintStyle: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondaryLight, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondaryLight),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(patientsProvider.notifier).search('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Error Banner
            if (patientsState.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        patientsState.errorMessage!,
                        style: AppTypography.bodyMedium(color: AppColors.danger),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => ref.read(patientsProvider.notifier).loadPatients(),
                      icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.danger),
                      label: const Text('Retry', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // Patient List or Skeleton
            Expanded(
              child: patientsState.isLoading
                  ? const SkeletonPatientList(count: 5)
                  : patientsState.patients.isEmpty
                      ? Center(
                          child: FadeSlideIn(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundLight,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person_search_rounded,
                                      size: 48,
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    patientsState.searchQuery.isNotEmpty
                                        ? 'No matching patient records found'
                                        : 'No patients registered yet',
                                    style: AppTypography.headingSmall(),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    patientsState.searchQuery.isNotEmpty
                                        ? 'No patient matches "${patientsState.searchQuery}". Check the MRN or name spelling.'
                                        : 'Begin by onboarding the first patient into the clinical directory.',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodyMedium(),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: _openRegistrationDialog,
                                    icon: const Icon(Icons.add_rounded, size: 18),
                                    label: const Text('Register Patient'),
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: patientsState.patients.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final patient = patientsState.patients[index];
                            return FadeSlideIn(
                              delay: Duration(milliseconds: 30 * index),
                              child: _PatientCard(
                                patient: patient,
                                onTap: () => PatientDossierModal.show(context, patient),
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 14),

            // Pagination Controls Footer
            if (patientsState.total > 0)
              FadeSlideIn(
                offset: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.badge_outlined, size: 16, color: AppColors.textSecondaryLight),
                          const SizedBox(width: 8),
                          Text(
                            'Showing ${patientsState.patients.length} of ${patientsState.total} patients',
                            style: AppTypography.bodyMedium(),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: patientsState.page > 1
                                ? () => ref.read(patientsProvider.notifier).setPage(patientsState.page - 1)
                                : null,
                            icon: const Icon(Icons.chevron_left_rounded, size: 16),
                            label: const Text('Previous'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(100, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Page ${patientsState.page} / ${patientsState.totalPages}',
                              style: AppTypography.monoCode(
                                color: AppColors.textPrimaryLight,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          OutlinedButton.icon(
                            onPressed: patientsState.page < patientsState.totalPages
                                ? () => ref.read(patientsProvider.notifier).setPage(patientsState.page + 1)
                                : null,
                            icon: const Icon(Icons.chevron_right_rounded, size: 16),
                            label: const Text('Next'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(90, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
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

  Color _getGenderColor(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'male':
        return const Color(0xFF0284C7); // Sky Blue
      case 'female':
        return const Color(0xFFDB2777); // Pink/Rose
      default:
        return const Color(0xFF7C3AED); // Purple
    }
  }

  IconData _getGenderIcon(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'male':
        return Icons.male_rounded;
      case 'female':
        return Icons.female_rounded;
      default:
        return Icons.person_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final genderColor = _getGenderColor(patient.gender);

    return CardHover(
      onTap: onTap,
      borderRadius: 12,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Patient Identity block
                Expanded(
                  child: Row(
                    children: [
                      // Avatar with Clinical Initials
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryLight,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            patient.firstName.isNotEmpty ? patient.firstName[0].toUpperCase() : 'P',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.headingSmall(),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                // MRN Monospace Badge
                                InkWell(
                                  borderRadius: BorderRadius.circular(4),
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: patient.mrn));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('MRN ${patient.mrn} copied to clipboard'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFDBEAFE)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          patient.mrn,
                                          style: AppTypography.monoMrn(fontSize: 11),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.copy_rounded, size: 11, color: AppColors.primary),
                                      ],
                                    ),
                                  ),
                                ),
                                // Demographics Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: genderColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_getGenderIcon(patient.gender), size: 13, color: genderColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${patient.age ?? "?"} Yrs • ${patient.gender ?? "Unknown"}',
                                        style: AppTypography.labelSmall(color: genderColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Status / Quick Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (patient.bloodGroup != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.dangerLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.water_drop_rounded, size: 13, color: AppColors.danger),
                            const SizedBox(width: 4),
                            Text(
                              patient.bloodGroup!,
                              style: AppTypography.monoMrn(
                                color: AppColors.danger,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Dossier', style: AppTypography.labelSmall(color: AppColors.primary)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 22, color: AppColors.borderLight),

            // Bottom Clinical Contacts Bar
            Row(
              children: [
                const Icon(Icons.call_outlined, size: 15, color: AppColors.textSecondaryLight),
                const SizedBox(width: 6),
                Text(
                  patient.phone ?? 'No phone provided',
                  style: AppTypography.monoCode(
                    color: AppColors.textPrimaryLight,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 24),
                if (patient.emergencyContact != null) ...[
                  const Icon(Icons.contact_emergency_outlined, size: 15, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Emergency Contact: ${patient.emergencyContact!['name'] ?? ''} (${patient.emergencyContact!['phone'] ?? ''})',
                      style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
                      overflow: TextOverflow.ellipsis,
                    ),
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
