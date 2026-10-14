import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        'Patient Directory',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Search, register, and manage patient dossiers',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {},
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
              decoration: InputDecoration(
                hintText: 'Search patients by Name, MRN (CP-2026-xxx), or Mobile...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondaryLight),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                  tooltip: 'Scan Patient QR Code',
                  onPressed: () {},
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Patient Cards List
            Expanded(
              child: ListView(
                children: const [
                  _PatientCard(
                    mrn: 'CP-2026-001',
                    name: 'Ramesh Patel',
                    ageGender: '54 Years • Male',
                    bloodGroup: 'B+',
                    phone: '+91 98250 12345',
                    emergencyContact: 'Geeta Patel (Wife)',
                    lastVisit: 'Today (Cardiology - Dr. Rajesh Sharma)',
                  ),
                  SizedBox(height: 12),
                  _PatientCard(
                    mrn: 'CP-2026-002',
                    name: 'Meena Shah',
                    ageGender: '36 Years • Female',
                    bloodGroup: 'O+',
                    phone: '+91 98251 67890',
                    emergencyContact: 'Ketan Shah (Husband)',
                    lastVisit: 'Scheduled Today (Neurology)',
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

class _PatientCard extends StatelessWidget {
  final String mrn;
  final String name;
  final String ageGender;
  final String bloodGroup;
  final String phone;
  final String emergencyContact;
  final String lastVisit;

  const _PatientCard({
    required this.mrn,
    required this.name,
    required this.ageGender,
    required this.bloodGroup,
    required this.phone,
    required this.emergencyContact,
    required this.lastVisit,
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
                      child: Text(
                        name.substring(0, 1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          '$mrn • $ageGender',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Blood: $bloodGroup',
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondaryLight),
                const SizedBox(width: 6),
                Text(phone, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 20),
                const Icon(Icons.emergency_outlined, size: 16, color: AppColors.warning),
                const SizedBox(width: 6),
                Text('Emergency: $emergencyContact', style: const TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.history_outlined, size: 16, color: AppColors.textSecondaryLight),
                const SizedBox(width: 6),
                Text('Recent: $lastVisit', style: const TextStyle(fontSize: 13, color: AppColors.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
