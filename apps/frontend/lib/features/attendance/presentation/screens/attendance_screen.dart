import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Staff Attendance & Geofencing',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryLight,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hospital perimeter validation, biometric selfie verify, and shift logs',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Geofence Campus Card
            Card(
              color: AppColors.successLight.withValues(alpha: 0.5),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.success, size: 36),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Medicare Main Campus Geofence Active',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimaryLight),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'GPS: 23.0225° N, 72.5714° E (250m Radius) • Current Device Inside Perimeter',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Clock-In Selfie'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        minimumSize: const Size(160, 44),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text("Today's Staff Log", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  ListTile(
                    leading: CircleAvatar(child: Text('RS')),
                    title: Text('Dr. Rajesh Sharma (Cardiology)'),
                    subtitle: Text('In: 08:52 AM • Geofence Verified • Shift: Morning'),
                    trailing: Text('Present', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                  ),
                  Divider(),
                  ListTile(
                    leading: CircleAvatar(child: Text('PS')),
                    title: Text('Pooja Shah (Receptionist)'),
                    subtitle: Text('In: 07:55 AM • Geofence Verified • Shift: Morning'),
                    trailing: Text('Present', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                  ),
                  Divider(),
                  ListTile(
                    leading: CircleAvatar(child: Text('SK')),
                    title: Text('Sunita Kaur (ICU Nurse)'),
                    subtitle: Text('In: 08:05 AM • Geofence Verified • Shift: Morning'),
                    trailing: Text('Present', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
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
