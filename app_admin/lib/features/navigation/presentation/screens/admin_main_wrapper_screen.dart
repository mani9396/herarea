import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_admin/core/routing/admin_route_paths.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_typography.dart';

class AdminMainWrapperScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AdminMainWrapperScreen({super.key, required this.navigationShell});

  void _onItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 860;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryRuby.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentGold, width: 1.5),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, size: 20, color: AppColors.primaryRuby),
            ),
            const SizedBox(width: 12),
            const Text(
              'HER AREA CONSOLE',
              style: TextStyle(fontFamily: AppTypography.displayFont, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 18),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('SUPERADMIN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_outlined, color: AppColors.primaryRuby),
            tooltip: 'Broadcast Announcements',
            onPressed: () => context.push(AdminRoutePaths.notificationComposer),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Platform Settings',
            onPressed: () => context.push(AdminRoutePaths.settings),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: InkWell(
              onTap: () => context.push(AdminRoutePaths.adminProfile),
              borderRadius: BorderRadius.circular(20),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryRuby,
                child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      body: isDesktop
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _onItemTapped,
                  labelType: NavigationRailLabelType.all,
                  selectedLabelTextStyle: const TextStyle(color: AppColors.primaryRuby, fontWeight: FontWeight.bold, fontSize: 12),
                  unselectedLabelTextStyle: TextStyle(color: AppColors.neutralCharcoal.withValues(alpha: 0.7), fontSize: 12),
                  selectedIconTheme: const IconThemeData(color: AppColors.primaryRuby),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.store_mall_directory_outlined),
                      selectedIcon: Icon(Icons.store_mall_directory_rounded),
                      label: Text('Vendors'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.fact_check_outlined),
                      selectedIcon: Icon(Icons.fact_check_rounded),
                      label: Text('Moderation'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outline_rounded),
                      selectedIcon: Icon(Icons.people_rounded),
                      label: Text('Customers'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.insights_rounded),
                      selectedIcon: Icon(Icons.insights_rounded),
                      label: Text('Analytics'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: navigationShell),
              ],
            )
          : navigationShell,
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onItemTapped,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primaryRuby),
                  label: 'Dash',
                ),
                NavigationDestination(
                  icon: Icon(Icons.store_mall_directory_outlined),
                  selectedIcon: Icon(Icons.store_mall_directory_rounded, color: AppColors.primaryRuby),
                  label: 'Vendors',
                ),
                NavigationDestination(
                  icon: Icon(Icons.fact_check_outlined),
                  selectedIcon: Icon(Icons.fact_check_rounded, color: AppColors.primaryRuby),
                  label: 'Moderate',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline_rounded),
                  selectedIcon: Icon(Icons.people_rounded, color: AppColors.primaryRuby),
                  label: 'Users',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights_rounded),
                  selectedIcon: Icon(Icons.insights_rounded, color: AppColors.primaryRuby),
                  label: 'Stats',
                ),
              ],
            ),
    );
  }
}
