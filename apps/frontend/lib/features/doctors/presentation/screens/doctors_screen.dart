import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/layout/responsive_helper.dart';

class DoctorsScreen extends StatelessWidget {
  const DoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveHelper.getGridColumnCount(context);

    final doctors = [
      {
        'id': 'DOC001',
        'name': 'Dr. Rajesh Sharma',
        'dept': 'Cardiology',
        'qual': 'MBBS, MD, DM (Cardio)',
        'exp': '15 Years',
        'fee': '₹800',
        'phone': '+91 98765 00001',
        'status': 'Available',
      },
      {
        'id': 'DOC002',
        'name': 'Dr. Priya Desai',
        'dept': 'Neurology',
        'qual': 'MBBS, MS, MCh (Neuro)',
        'exp': '12 Years',
        'fee': '₹1,000',
        'phone': '+91 98765 00002',
        'status': 'Available',
      },
      {
        'id': 'DOC003',
        'name': 'Dr. Amit Verma',
        'dept': 'Orthopedics',
        'qual': 'MBBS, MS (Ortho)',
        'exp': '10 Years',
        'fee': '₹700',
        'phone': '+91 98765 00003',
        'status': 'Available',
      },
      {
        'id': 'DOC004',
        'name': 'Dr. Ananya Iyer',
        'dept': 'General Medicine',
        'qual': 'MBBS, MD (Medicine)',
        'exp': '8 Years',
        'fee': '₹500',
        'phone': '+91 98765 00004',
        'status': 'Available',
      },
    ];

    return Scaffold(
      body: SingleChildScrollView(
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
                        'Medical Doctors & Specialists',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Consultant directory, duty schedules, and OPD consultation slots',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Doctor'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(140, 44)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: doctors.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.3,
              ),
              itemBuilder: (context, index) {
                final doc = doctors[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              foregroundColor: AppColors.primary,
                              radius: 22,
                              child: const Icon(Icons.person, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doc['name']!,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Text(
                                    doc['dept']!,
                                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doc['qual']!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                            const SizedBox(height: 2),
                            Text('Experience: ${doc['exp']} • Fee: ${doc['fee']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(doc['phone']!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                            OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(70, 32),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                              child: const Text('Schedule', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
