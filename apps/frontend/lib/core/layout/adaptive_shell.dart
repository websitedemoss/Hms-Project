import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import 'responsive_helper.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class AdaptiveShell extends ConsumerWidget {
  final Widget child;

  const AdaptiveShell({super.key, required this.child});

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.danger, size: 22),
            SizedBox(width: 10),
            Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to end your clinical workstation session?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final currentPath = GoRouterState.of(context).uri.path;
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final initials = user != null
        ? '${user.firstName.isNotEmpty ? user.firstName[0] : ''}${user.lastName.isNotEmpty ? user.lastName[0] : ''}'
        : 'AD';

    // Desktop Layout (>= 1024px)
    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Clinical Desktop Sidebar
            Container(
              width: 260,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(color: AppColors.borderLight),
                ),
              ),
              child: Column(
                children: [
                  // Hospital Brand Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.local_hospital, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.hospital.name ?? 'Medicare HMS',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                              Text(
                                user?.hospital.tagline ?? 'Hospital & I.C.U',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Navigation Item List (Filtered by Active Granular Permissions)
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      children: [
                        if (user == null || user.hasPermission('dashboard'))
                          _SidebarItem(
                            icon: Icons.dashboard_outlined,
                            activeIcon: Icons.dashboard,
                            label: 'Dashboard',
                            path: '/dashboard',
                            isActive: currentPath == '/dashboard',
                          ),
                        if (user == null || user.hasPermission('patients'))
                          _SidebarItem(
                            icon: Icons.people_alt_outlined,
                            activeIcon: Icons.people_alt,
                            label: 'Patients',
                            path: '/patients',
                            isActive: currentPath == '/patients',
                          ),
                        if (user == null || user.hasPermission('appointments'))
                          _SidebarItem(
                            icon: Icons.calendar_today_outlined,
                            activeIcon: Icons.calendar_today,
                            label: 'Appointments',
                            path: '/appointments',
                            isActive: currentPath == '/appointments',
                          ),
                        if (user == null || user.hasPermission('bed'))
                          _SidebarItem(
                            icon: Icons.hotel_outlined,
                            activeIcon: Icons.hotel,
                            label: 'Beds & Wards',
                            path: '/beds',
                            isActive: currentPath == '/beds',
                          ),
                        if (user == null || user.hasPermission('doctors'))
                          _SidebarItem(
                            icon: Icons.medical_services_outlined,
                            activeIcon: Icons.medical_services,
                            label: 'Doctors',
                            path: '/doctors',
                            isActive: currentPath == '/doctors',
                          ),
                        if (user == null || user.hasPermission('attendance'))
                          _SidebarItem(
                            icon: Icons.how_to_reg_outlined,
                            activeIcon: Icons.how_to_reg,
                            label: 'Staff Attendance',
                            path: '/attendance',
                            isActive: currentPath == '/attendance',
                          ),
                        if (user == null || user.hasPermission('staff'))
                          _SidebarItem(
                            icon: Icons.admin_panel_settings_outlined,
                            activeIcon: Icons.admin_panel_settings,
                            label: 'Staff & RBAC',
                            path: '/permissions',
                            isActive: currentPath == '/permissions',
                            badge: 'RBAC',
                          ),
                        if (user == null || user.hasPermission('bhooma_ai'))
                          _SidebarItem(
                            icon: Icons.auto_awesome_outlined,
                            activeIcon: Icons.auto_awesome,
                            label: 'BHOOMA AI',
                            path: '/bhooma-ai',
                            isActive: currentPath == '/bhooma-ai',
                            badge: 'AI',
                          ),
                        if (user == null || user.hasPermission('settings'))
                          _SidebarItem(
                            icon: Icons.settings_outlined,
                            activeIcon: Icons.settings,
                            label: 'Settings',
                            path: '/settings',
                            isActive: currentPath == '/settings',
                          ),
                      ],
                    ),
                  ),

                  // Staff Profile Pill at bottom
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          radius: 18,
                          child: Text(
                            initials.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Administrator',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                '${user?.role ?? "Super Admin"} • ${user?.department ?? "Clinical"}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, size: 18, color: AppColors.textSecondaryLight),
                          onPressed: () => _showLogoutDialog(context, ref),
                          tooltip: 'Logout Session',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(child: child),
          ],
        ),
      );
    }

    // Mobile / Tablet Layout (< 1024px)
    int getBottomNavIndex() {
      if (currentPath == '/patients') return 1;
      if (currentPath == '/appointments') return 2;
      if (currentPath == '/beds') return 3;
      return 0; // Default to Dashboard
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.local_hospital, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              user?.hospital.name ?? 'Medicare HMS',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          if (user == null || user.hasPermission('bhooma_ai'))
            IconButton(
              icon: const Icon(Icons.auto_awesome, color: Color(0xFF7C3AED)),
              tooltip: 'BHOOMA AI',
              onPressed: () => context.go('/bhooma-ai'),
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: 'Logout',
            onPressed: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  initials.toUpperCase(),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              accountName: Text(
                user?.fullName ?? 'Hospital Administrator',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                '${user?.role ?? "Super Admin"} • ${user?.email ?? "admin@medicare.in"}',
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (user == null || user.hasPermission('dashboard'))
                    ListTile(
                      leading: const Icon(Icons.dashboard_outlined),
                      title: const Text('Dashboard'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/dashboard');
                      },
                    ),
                  if (user == null || user.hasPermission('patients'))
                    ListTile(
                      leading: const Icon(Icons.people_alt_outlined),
                      title: const Text('Patients'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/patients');
                      },
                    ),
                  if (user == null || user.hasPermission('appointments'))
                    ListTile(
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Appointments'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/appointments');
                      },
                    ),
                  if (user == null || user.hasPermission('bed'))
                    ListTile(
                      leading: const Icon(Icons.hotel_outlined),
                      title: const Text('Beds & Wards'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/beds');
                      },
                    ),
                  if (user == null || user.hasPermission('doctors'))
                    ListTile(
                      leading: const Icon(Icons.medical_services_outlined),
                      title: const Text('Doctors'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/doctors');
                      },
                    ),
                  if (user == null || user.hasPermission('attendance'))
                    ListTile(
                      leading: const Icon(Icons.how_to_reg_outlined),
                      title: const Text('Staff Attendance'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/attendance');
                      },
                    ),
                  if (user == null || user.hasPermission('staff'))
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings_outlined),
                      title: const Text('Staff & RBAC'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/permissions');
                      },
                    ),
                  if (user == null || user.hasPermission('bhooma_ai'))
                    ListTile(
                      leading: const Icon(Icons.auto_awesome_outlined),
                      title: const Text('BHOOMA AI Assistant'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/bhooma-ai');
                      },
                    ),
                  if (user == null || user.hasPermission('settings'))
                    ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text('Settings'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/settings');
                      },
                    ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.danger),
                    title: const Text('Sign Out', style: TextStyle(color: AppColors.danger)),
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutDialog(context, ref);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: getBottomNavIndex(),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/patients');
              break;
            case 2:
              context.go('/appointments');
              break;
            case 3:
              context.go('/beds');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt),
            label: 'Patients',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          NavigationDestination(
            icon: Icon(Icons.hotel_outlined),
            selectedIcon: Icon(Icons.hotel),
            label: 'Beds',
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  final bool isActive;
  final String? badge;

  const _SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
    required this.isActive,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () => context.go(path),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 20,
                color: isActive ? AppColors.primary : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? AppColors.primary : AppColors.textPrimaryLight,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badge == 'AI'
                        ? const Color(0xFF7C3AED)
                        : AppColors.secondary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
