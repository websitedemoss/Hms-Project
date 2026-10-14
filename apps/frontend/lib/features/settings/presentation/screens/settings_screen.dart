import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System & Hospital Configuration',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hospital metadata, API server endpoints, and device diagnostics',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hospital Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.local_hospital, color: AppColors.primary),
                      title: Text('Medicare Hospital & I.C.U'),
                      subtitle: Text('Code: MEDICARE-01 • 123 Healthcare Boulevard, Medical Zone'),
                    ),
                    const Divider(),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.dns, color: AppColors.secondary),
                      title: Text('Backend API URL'),
                      subtitle: Text('http://localhost:3000/api/v1 (NestJS + Prisma)'),
                      trailing: Chip(
                        label: Text('Online', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
                        backgroundColor: AppColors.successLight,
                      ),
                    ),
                    const Divider(),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.storage, color: AppColors.info),
                      title: Text('Database Engine'),
                      subtitle: Text('PostgreSQL 18 (hospital_db) on localhost:5432'),
                      trailing: Text('Connected', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                    ),
                    const Divider(),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.info_outline, color: AppColors.textSecondaryLight),
                      title: Text('Client App Version'),
                      subtitle: Text('v1.0.0 (Build 1) • Cross-Platform Flutter Release'),
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
