import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/layout/responsive_helper.dart';

class BedsScreen extends StatelessWidget {
  const BedsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveHelper.getGridColumnCount(context);

    final beds = [
      {'number': 'ICU-01', 'type': 'ICU', 'wing': 'Critical Care Unit', 'status': 'Occupied', 'patient': 'Ramesh Patel', 'charge': '₹3,500/day'},
      {'number': 'ICU-02', 'type': 'ICU', 'wing': 'Critical Care Unit', 'status': 'Available', 'patient': null, 'charge': '₹3,500/day'},
      {'number': 'ICU-03', 'type': 'ICU', 'wing': 'Critical Care Unit', 'status': 'Available', 'patient': null, 'charge': '₹3,500/day'},
      {'number': 'ICU-04', 'type': 'ICU', 'wing': 'Critical Care Unit', 'status': 'Maintenance', 'patient': null, 'charge': '₹3,500/day'},
      {'number': 'GEN-01', 'type': 'General Ward', 'wing': 'Ward A', 'status': 'Occupied', 'patient': 'Patient #284', 'charge': '₹1,200/day'},
      {'number': 'GEN-02', 'type': 'General Ward', 'wing': 'Ward A', 'status': 'Available', 'patient': null, 'charge': '₹1,200/day'},
      {'number': 'GEN-03', 'type': 'General Ward', 'wing': 'Ward B', 'status': 'Available', 'patient': null, 'charge': '₹1,200/day'},
      {'number': 'GEN-04', 'type': 'General Ward', 'wing': 'Ward B', 'status': 'Available', 'patient': null, 'charge': '₹1,200/day'},
      {'number': 'PVT-01', 'type': 'Private Room', 'wing': 'Executive Wing', 'status': 'Available', 'patient': null, 'charge': '₹2,500/day'},
      {'number': 'PVT-02', 'type': 'Private Room', 'wing': 'Executive Wing', 'status': 'Occupied', 'patient': 'Patient #190', 'charge': '₹2,500/day'},
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
                        'Inpatient Bed & Ward Management',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real-time bed occupancy, ICU monitoring, and allocation',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '7 Available / 10 Total',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: beds.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
              ),
              itemBuilder: (context, index) {
                final bed = beds[index];
                final isAvailable = bed['status'] == 'Available';
                final isOccupied = bed['status'] == 'Occupied';

                final Color statusColor = isAvailable
                    ? AppColors.success
                    : (isOccupied ? AppColors.danger : AppColors.warning);

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
                            Row(
                              children: [
                                Icon(Icons.hotel, color: statusColor, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  bed['number']!,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                bed['status']!,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${bed['type']} • ${bed['wing']}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bed['patient'] != null ? 'Patient: ${bed['patient']}' : 'Ready for admission',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isOccupied ? AppColors.danger : AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              bed['charge']!,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(60, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(isAvailable ? 'Assign' : 'Details'),
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
