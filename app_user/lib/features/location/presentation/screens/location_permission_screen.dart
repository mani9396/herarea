import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:her_area/core/routing/route_paths.dart';
import 'package:her_area/core/state/app_state_provider.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_typography.dart';
import 'package:shared/widgets/custom_button.dart';

class LocationPermissionScreen extends ConsumerStatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  ConsumerState<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends ConsumerState<LocationPermissionScreen> {
  bool _isLoading = false;

  Future<void> _onAllowGps() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }
      
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      
      String areaName = 'Unknown Area';
      
      try {
        final dio = Dio();
        final response = await dio.get(
          'https://nominatim.openstreetmap.org/reverse',
          queryParameters: {
            'lat': position.latitude,
            'lon': position.longitude,
            'format': 'json',
          },
        );
        if (response.statusCode == 200) {
          final address = response.data['address'];
          if (address != null) {
            final subLocality = address['suburb'] ?? address['neighbourhood'] ?? address['sublocality'] ?? '';
            final locality = address['city'] ?? address['town'] ?? address['county'] ?? '';
            if (subLocality.isNotEmpty && locality.isNotEmpty) {
              areaName = '$subLocality, $locality';
            } else if (locality.isNotEmpty) {
              areaName = locality;
            } else if (subLocality.isNotEmpty) {
              areaName = subLocality;
            }
          }
        }
      } catch (_) {
        // Fallback to Unknown Area if OSM fails
      }
      
      ref.read(userLocationProvider.notifier).setLocation(UserLocationState(
        latitude: position.latitude,
        longitude: position.longitude,
        cityName: areaName,
      ));
      
      if (mounted) {
        context.push(RoutePaths.interestSelection);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
