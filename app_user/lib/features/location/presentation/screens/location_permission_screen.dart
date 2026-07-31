import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:her_area/core/routing/route_paths.dart';
import 'package:her_area/core/state/app_state_provider.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_typography.dart';
import 'package:shared/widgets/custom_button.dart';
import 'package:her_area/data/mock/mock_data.dart';

class LocationPermissionScreen extends ConsumerStatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  ConsumerState<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends ConsumerState<LocationPermissionScreen> {
  bool _isLoading = false;

  void _onAllowGps() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 650)); // Simulate GPS triangulation
    if (mounted) {
      setState(() => _isLoading = false);
      ref.read(userLocationProvider.notifier).state = const UserLocationState(
        latitude: 17.4326,
        longitude: 78.4071,
        cityName: 'Jubilee Hills, Hyderabad',
      );
      context.push(RoutePaths.interestSelection);
    }
  }

  void _showManualLocationDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final allLocalities = [
      const UserLocationState(latitude: 17.4326, longitude: 78.4071, cityName: 'Jubilee Hills, Hyderabad'),
      const UserLocationState(latitude: 17.4126, longitude: 78.4371, cityName: 'Banjara Hills, Hyderabad'),
      const UserLocationState(latitude: 17.4486, longitude: 78.3911, cityName: 'Madhapur, Hitec City'),
      const UserLocationState(latitude: 17.4346, longitude: 78.3811, cityName: 'Inorbit Road, Cyberabad'),
      const UserLocationState(latitude: 17.4400, longitude: 78.4800, cityName: 'Begumpet & Somajiguda'),
      const UserLocationState(latitude: 17.4455, longitude: 78.3489, cityName: 'Gachibowli Financial District'),
    ];

    List<UserLocationState> filteredLocalities = List.from(allLocalities);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bottomContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.8,
                maxWidth: 640,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Neighborhood Hub',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontFamily: AppTypography.displayFont,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Close neighborhood selector',
                          onPressed: () => Navigator.pop(bottomContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Choose an active HER AREA zone to discover nearby designers and tailoring masters.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    TextField(
                      onChanged: (val) {
                        setModalState(() {
                          if (val.trim().isEmpty) {
                            filteredLocalities = List.from(allLocalities);
                          } else {
                            filteredLocalities = allLocalities
                                .where((loc) => loc.cityName.toLowerCase().contains(val.toLowerCase()))
                                .toList();
                          }
                        });
                      },
                      style: TextStyle(fontFamily: AppTypography.bodyFont, color: isDark ? AppColors.textHighDark : AppColors.textHighLight),
                      decoration: InputDecoration(
                        hintText: 'Search locality (e.g. Jubilee Hills, Hitec City)...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryRuby),
                        filled: true,
                        fillColor: isDark ? AppColors.backgroundDark : AppColors.surfaceVariantLight.withValues(alpha: 0.4),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'ACTIVE O2O CURATION CENTERS (${filteredLocalities.length})',
                      style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    Flexible(
                      child: filteredLocalities.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Text(
                                  'No matching neighborhood found in our current test data.',
                                  style: TextStyle(color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filteredLocalities.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final loc = filteredLocalities[index];
                                final isSelected = ref.read(userLocationProvider).cityName == loc.cityName;

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  leading: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primaryRuby : (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.location_on_rounded,
                                      size: 20,
                                      color: isSelected ? Colors.white : AppColors.primaryRuby,
                                    ),
                                  ),
                                  title: Text(
                                    loc.cityName,
                                    style: TextStyle(
                                      fontFamily: AppTypography.bodyFont,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      fontSize: 15,
                                      color: isDark ? AppColors.textHighDark : AppColors.textHighLight,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${MockData.allStores.length}+ verified boutiques around this locality',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryRuby, size: 22)
                                      : Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 16,
                                          color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
                                        ),
                                  onTap: () {
                                    ref.read(userLocationProvider.notifier).state = loc;
                                    Navigator.pop(bottomContext);
                                    context.push(RoutePaths.interestSelection);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
              child: Container(
                padding: EdgeInsets.all(isWide ? 44 : 0),
                decoration: isWide
                    ? BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      )
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    // Luxury Geo-Medallion Iconography
                    Semantics(
                      label: 'HER AREA GPS Discovery Compass Medallion',
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: isDark ? AppColors.primaryGradient : null,
                          color: isDark ? null : AppColors.surfaceVariantLight,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryRuby.withValues(alpha: 0.18),
                              blurRadius: 28,
                              spreadRadius: 8,
                            ),
                          ],
                          border: Border.all(color: AppColors.accentGold, width: 2),
                        ),
                        child: const Icon(
                          Icons.explore_rounded,
                          size: 72,
                          color: AppColors.primaryRubyLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'Discover Local Treasures',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontFamily: AppTypography.displayFont,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      "HER AREA connects you with vetted neighborhood saree handlooms, bespoke maggam tailors, and private bridal salons using exact proximity. Your location remains entirely private.",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Trust Badges Grid / Row
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceVariantDark.withValues(alpha: 0.5) : AppColors.surfaceVariantLight.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTrustBadge(Icons.security_rounded, 'Privacy First', isDark),
                          _buildDivider(isDark),
                          _buildTrustBadge(Icons.radar_rounded, '5km Radius Hubs', isDark),
                          _buildDivider(isDark),
                          _buildTrustBadge(Icons.verified_user_rounded, 'Verified Artisans', isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    CustomButton(
                      label: 'Allow GPS Auto-Detection',
                      icon: Icons.my_location_rounded,
                      isLoading: _isLoading,
                      onPressed: _onAllowGps,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CustomButton(
                      label: 'Select Neighborhood Manually',
                      icon: Icons.map_outlined,
                      variant: ButtonVariant.outline,
                      onPressed: _showManualLocationDialog,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label, bool isDark) {
    return Expanded(
      child: Semantics(
        label: 'Trust badge: $label',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.accentGold, size: 26),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textHighDark : AppColors.textHighLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 36,
      width: 1,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }
}
