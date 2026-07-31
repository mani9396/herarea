import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:her_area/core/routing/route_paths.dart';
import 'package:her_area/core/state/app_state_provider.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_typography.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final pushEnabled = ref.watch(pushNotificationsProvider);
    final promosEnabled = ref.watch(promotionalAlertsProvider);
    final radius = ref.watch(discoveryRadiusProvider);
    final location = ref.watch(userLocationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings', style: TextStyle(fontFamily: AppTypography.displayFont, fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(context, 'THEME & VISUAL AESTHETICS'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Midnight Dark Mode', style: TextStyle(fontWeight: FontWeight.w700, fontFamily: AppTypography.displayFont)),
                      subtitle: const Text('Switch between luxury blush gold and midnight velvet ruby aesthetics.'),
                      value: isDark,
                      activeThumbColor: AppColors.primaryRuby,
                      secondary: Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: AppColors.primaryRuby,
                      ),
                      onChanged: (val) => ref.read(themeModeProvider.notifier).state = val,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              _buildSectionHeader(context, 'LOCAL O2O DISCOVERY RADIUS'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.my_location_rounded, color: AppColors.primaryRuby),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Search Area: ${radius.toStringAsFixed(1)} km around ${location.cityName}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primaryRuby,
                          thumbColor: AppColors.accentGold,
                          overlayColor: AppColors.accentGold.withValues(alpha: 0.2),
                          valueIndicatorColor: AppColors.primaryRuby,
                        ),
                        child: Slider(
                          value: radius,
                          min: 2.0,
                          max: 25.0,
                          divisions: 23,
                          label: '${radius.toStringAsFixed(1)} km',
                          onChanged: (val) => ref.read(discoveryRadiusProvider.notifier).state = val,
                        ),
                      ),
                      Text(
                        'Adjusts how far HER AREA looks for specialized silk handloom houses and bridal studios in your immediate vicinity.',
                        style: TextStyle(fontSize: 13, color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              _buildSectionHeader(context, 'NOTIFICATIONS & ALERTS'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Booking & Consultation Alerts', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('Real-time updates on home measurement appointments and tailoring status.'),
                      value: pushEnabled,
                      activeThumbColor: AppColors.primaryRuby,
                      secondary: const Icon(Icons.event_available_rounded, color: AppColors.primaryRuby),
                      onChanged: (val) => ref.read(pushNotificationsProvider.notifier).state = val,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('VIP Offers & New Weave Drops', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('Receive notifications when top neighborhood boutiques introduce seasonal collections.'),
                      value: promosEnabled,
                      activeThumbColor: AppColors.primaryRuby,
                      secondary: const Icon(Icons.card_giftcard_rounded, color: AppColors.accentGold),
                      onChanged: (val) => ref.read(promotionalAlertsProvider.notifier).state = val,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              _buildSectionHeader(context, 'PREFERENCES & LOCATIONS'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.style_rounded, color: AppColors.primaryRuby),
                      title: const Text('Personalized Style Interests', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('Modify your selected fashion categories and artisanal preferences.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(RoutePaths.interestSelection),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.location_city_rounded, color: AppColors.primaryRuby),
                      title: const Text('Location Permissions & Hubs', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('Current discovery zone: ${location.cityName}'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(RoutePaths.locationPermission),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: AppTypography.displayFont,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: AppColors.primaryRuby,
        ),
      ),
    );
  }
}
