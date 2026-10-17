import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class VendorMainWrapperScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const VendorMainWrapperScreen({super.key, required this.navigationShell});

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onTap,
          indicatorColor: AppColors.primaryRuby.withValues(alpha: 0.15),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primaryRuby), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.checkroom_outlined), selectedIcon: Icon(Icons.checkroom_rounded, color: AppColors.primaryRuby), label: 'Products'),
            NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_month_rounded, color: AppColors.primaryRuby), label: 'Enquiries'),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), selectedIcon: Icon(Icons.chat_bubble_rounded, color: AppColors.primaryRuby), label: 'Messages'),
            NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront_rounded, color: AppColors.primaryRuby), label: 'Profile'),
            NavigationDestination(icon: Icon(Icons.amp_stories_outlined), selectedIcon: Icon(Icons.amp_stories_rounded, color: AppColors.primaryRuby), label: 'Stories'),
            NavigationDestination(icon: Icon(Icons.card_membership_outlined), selectedIcon: Icon(Icons.card_membership_rounded, color: AppColors.primaryRuby), label: 'Subscription'),
          ],
        ),
      ),
      desktop: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onTap,
              labelType: NavigationRailLabelType.all,
              selectedLabelTextStyle: const TextStyle(color: AppColors.primaryRuby, fontWeight: FontWeight.bold),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primaryRuby), label: Text('Dashboard')),
                NavigationRailDestination(icon: Icon(Icons.checkroom_outlined), selectedIcon: Icon(Icons.checkroom_rounded, color: AppColors.primaryRuby), label: Text('Products')),
                NavigationRailDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_month_rounded, color: AppColors.primaryRuby), label: Text('Enquiries')),
                NavigationRailDestination(icon: Icon(Icons.chat_bubble_outline_rounded), selectedIcon: Icon(Icons.chat_bubble_rounded, color: AppColors.primaryRuby), label: Text('Messages')),
                NavigationRailDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront_rounded, color: AppColors.primaryRuby), label: Text('Profile')),
                NavigationRailDestination(icon: Icon(Icons.amp_stories_outlined), selectedIcon: Icon(Icons.amp_stories_rounded, color: AppColors.primaryRuby), label: Text('Stories')),
                NavigationRailDestination(icon: Icon(Icons.card_membership_outlined), selectedIcon: Icon(Icons.card_membership_rounded, color: AppColors.primaryRuby), label: Text('Subscription')),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      ),
    );
  }
}
