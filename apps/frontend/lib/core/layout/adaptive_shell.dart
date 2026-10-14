import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import 'responsive_helper.dart';

class AdaptiveShell extends StatelessWidget {
  final Widget child;

  const AdaptiveShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final currentPath = GoRouterState.of(context).uri.path;

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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Medicare HMS',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                              Text(
                                'Hospital & I.C.U',
                                style: TextStyle(
                                  fontSize: 12,
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

                  // Navigation Item List
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      children: [
                        _SidebarItem(
                          icon: Icons.dashboard_outlined,
                          activeIcon: Icons.dashboard,
                          label: 'Dashboard',
                          path: '/dashboard',
                          isActive: currentPath == '/dashboard',
                        ),
                        _SidebarItem(
                          icon: Icons.people_alt_outlined,
                          activeIcon: Icons.people_alt,
                          label: 'Patients',
                          path: '/patients',
                          isActive: currentPath == '/patients',
                        ),
                        _SidebarItem(
                          icon: Icons.calendar_today_outlined,
                          activeIcon: Icons.calendar_today,
                          label: 'Appointments',
                          path: '/appointments',
                          isActive: currentPath == '/appointments',
                        ),
                        _SidebarItem(
                          icon: Icons.hotel_outlined,
                          activeIcon: Icons.hotel,
                          label: 'Beds & Wards',
                          path: '/beds',
                          isActive: currentPath == '/beds',
                        ),
                        _SidebarItem(
                          icon: Icons.medical_services_outlined,
                          activeIcon: Icons.medical_services,
                          label: 'Doctors',
                          path: '/doctors',
                          isActive: currentPath == '/doctors',
                        ),
                        _SidebarItem(
                          icon: Icons.how_to_reg_outlined,
                          activeIcon: Icons.how_to_reg,
                          label: 'Staff Attendance',
                          path: '/attendance',
                          isActive: currentPath == '/attendance',
                        ),
                        _SidebarItem(
                          icon: Icons.auto_awesome_outlined,
                          activeIcon: Icons.auto_awesome,
                          label: 'BHOOMA AI',
                          path: '/bhooma-ai',
                          isActive: currentPath == '/bhooma-ai',
                          badge: 'AI',
                        ),
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
                        const CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          radius: 18,
                          child: Text('AD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Administrator',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Super Admin',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, size: 18, color: AppColors.textSecondaryLight),
                          onPressed: () {},
                          tooltip: 'Logout',
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
            const Text('Medicare HMS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF7C3AED)),
            tooltip: 'BHOOMA AI',
            onPressed: () => context.go('/bhooma-ai'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Text('AD', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              accountName: const Text('Hospital Administrator', style: TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: const Text('admin@medicare.in'),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                context.go('/dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_alt_outlined),
              title: const Text('Patients'),
              onTap: () {
                Navigator.pop(context);
                context.go('/patients');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Appointments'),
              onTap: () {
                Navigator.pop(context);
                context.go('/appointments');
              },
            ),
            ListTile(
              leading: const Icon(Icons.hotel_outlined),
              title: const Text('Beds & Wards'),
              onTap: () {
                Navigator.pop(context);
                context.go('/beds');
              },
            ),
            ListTile(
              leading: const Icon(Icons.medical_services_outlined),
              title: const Text('Doctors'),
              onTap: () {
                Navigator.pop(context);
                context.go('/doctors');
              },
            ),
            ListTile(
              leading: const Icon(Icons.how_to_reg_outlined),
              title: const Text('Staff Attendance'),
              onTap: () {
                Navigator.pop(context);
                context.go('/attendance');
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined, color: Color(0xFF7C3AED)),
              title: const Text('BHOOMA AI Assistant'),
              onTap: () {
                Navigator.pop(context);
                context.go('/bhooma-ai');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                context.go('/settings');
              },
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
            label: 'Queue',
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
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          isActive ? activeIcon : icon,
          color: isActive ? AppColors.primary : AppColors.textSecondaryLight,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? AppColors.primary : AppColors.textPrimaryLight,
            fontSize: 13,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              )
            : null,
        onTap: () => context.go(path),
      ),
    );
  }
}
