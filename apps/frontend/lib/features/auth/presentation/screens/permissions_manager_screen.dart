import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class PermissionsManagerScreen extends ConsumerStatefulWidget {
  const PermissionsManagerScreen({super.key});

  @override
  ConsumerState<PermissionsManagerScreen> createState() =>
      _PermissionsManagerScreenState();
}

class _PermissionsManagerScreenState
    extends ConsumerState<PermissionsManagerScreen> {
  int _selectedStaffId = 1;
  bool _isLoading = false;
  String? _statusMessage;
  bool _isSuccess = false;

  final List<Map<String, dynamic>> _staffList = [
    {'id': 1, 'name': 'Hospital Administrator', 'username': 'admin', 'role': 'Super Admin'},
    {'id': 2, 'name': 'Dr. Rajesh Sharma', 'username': 'dr.rajesh', 'role': 'Doctor'},
    {'id': 3, 'name': 'Pooja Shah', 'username': 'reception', 'role': 'Receptionist'},
    {'id': 4, 'name': 'Sunita Kaur', 'username': 'nurse.sunita', 'role': 'Nurse'},
  ];

  Map<String, bool> _currentPermissions = {};
  String _currentAccountStatus = 'Active';

  final Map<String, String> _permissionDescriptions = {
    'dashboard': 'Executive Dashboard, Real-time KPIs & Bed Occupancy Stats',
    'patients': 'Patient Directory, Medical Records & Lifetime QR Card Lookup',
    'appointments': 'Doctor Scheduling, Time-Slot Allocation & Walk-in Booking',
    'queue': 'Live Token Queue Pipeline & 4-Step Clinical Workstation',
    'doctors': 'Medical Practitioner Registry, Working Day Rosters & Break Slots',
    'staff': 'Staff Registry, Granular Permissions & Role Presets Management',
    'attendance': 'Staff Attendance Roster, Haversine Geofencing & Selfie Log',
    'bed': 'Inpatient Bed Grid, ICU Monitoring & Ward Occupancy Map',
    'medical_files': 'Private S3 Medical Files, Radiology Scans & Download Audit',
    'bhooma_ai': 'BHOOMA AI Clinical Assistant & Safe Tool-Calling Pipeline',
    'settings': 'Hospital Multi-Tenancy Anchor & Institution Configuration',
  };

  @override
  void initState() {
    super.initState();
    _loadStaffPermissions(_selectedStaffId);
  }

  Future<void> _loadStaffPermissions(int staffId) async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      final data = await repo.getStaffPermissions(staffId);
      final rawPerms = data['permissions'] as Map<String, dynamic>? ?? {};

      setState(() {
        _selectedStaffId = staffId;
        _currentAccountStatus = data['accountStatus'] as String? ?? 'Active';
        _currentPermissions = rawPerms.map((k, v) => MapEntry(k, v == true));
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading permissions: $e';
        _isSuccess = false;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyRolePreset(String role) {
    final Map<String, List<String>> presets = {
      'Super Admin': [
        'dashboard', 'patients', 'appointments', 'queue', 'doctors',
        'staff', 'attendance', 'bed', 'medical_files', 'bhooma_ai', 'settings'
      ],
      'Doctor': [
        'dashboard', 'patients', 'appointments', 'queue', 'bed',
        'medical_files', 'bhooma_ai'
      ],
      'Receptionist': [
        'dashboard', 'patients', 'appointments', 'queue', 'attendance'
      ],
      'Nurse': [
        'dashboard', 'patients', 'appointments', 'attendance', 'bed', 'medical_files'
      ],
    };

    final grantedKeys = presets[role] ?? [];
    setState(() {
      for (final key in _permissionDescriptions.keys) {
        _currentPermissions[key] = grantedKeys.contains(key);
      }
      _statusMessage = 'Applied $role preset. Click "Save Permissions Matrix" to commit.';
      _isSuccess = true;
    });
  }

  Future<void> _savePermissions() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.updateStaffPermissions(
        _selectedStaffId,
        _currentPermissions,
        accountStatus: _currentAccountStatus,
      );

      setState(() {
        _statusMessage = 'Permissions successfully updated and committed to PostgreSQL.';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to save permissions: $e';
        _isSuccess = false;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 32 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.security_rounded, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Staff RBAC & Permissions Management',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Configure 11 fine-grained clinical access controls, account statuses, and role presets.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Notification Banner
            if (_statusMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSuccess
                        ? AppColors.success.withValues(alpha: 0.3)
                        : AppColors.danger.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                      color: _isSuccess ? AppColors.success : AppColors.danger,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: _isSuccess ? AppColors.success : AppColors.danger,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Staff Member Selector Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Staff Account to Configure',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _staffList.map((stf) {
                      final isSelected = stf['id'] == _selectedStaffId;
                      return ChoiceChip(
                        label: Text('${stf['name']} (${stf['role']})'),
                        selected: isSelected,
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primary : Colors.grey.shade800,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : Colors.grey.shade300,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            _loadStaffPermissions(stf['id'] as int);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const Divider(height: 32),

                  // Role Presets & Account Status
                  Row(
                    children: [
                      const Text(
                        'Apply Preset:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () => _applyRolePreset('Doctor'),
                            child: const Text('Doctor Preset'),
                          ),
                          OutlinedButton(
                            onPressed: () => _applyRolePreset('Nurse'),
                            child: const Text('Nurse Preset'),
                          ),
                          OutlinedButton(
                            onPressed: () => _applyRolePreset('Receptionist'),
                            child: const Text('Receptionist Preset'),
                          ),
                          OutlinedButton(
                            onPressed: () => _applyRolePreset('Super Admin'),
                            child: const Text('Admin (All Perms)'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 11 Permission Switch Tiles
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _permissionDescriptions.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey.shade100,
                  ),
                  itemBuilder: (context, index) {
                    final key = _permissionDescriptions.keys.elementAt(index);
                    final desc = _permissionDescriptions[key]!;
                    final isGranted = _currentPermissions[key] ?? false;

                    return SwitchListTile.adaptive(
                      value: isGranted,
                      activeTrackColor: AppColors.success,
                      title: Text(
                        key.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      subtitle: Text(
                        desc,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      onChanged: (newVal) {
                        setState(() {
                          _currentPermissions[key] = newVal;
                        });
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 28),

            // Save Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _savePermissions,
              icon: const Icon(Icons.save_rounded),
              label: const Text(
                'Save Permissions Matrix',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
