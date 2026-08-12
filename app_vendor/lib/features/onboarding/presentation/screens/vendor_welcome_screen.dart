import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:shared/shared.dart';

class VendorWelcomeScreen extends StatelessWidget {
  const VendorWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.accentGold, width: 2.5),
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        child: const Icon(Icons.handshake_rounded, size: 64, color: AppColors.accentGold),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const Text(
                        'Empowering Hyderabad Bridal Boutiques 👑',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'Connect directly with thousands of verified brides searching for custom Maggam embroidery, royal Kanjivaram styling, and home measurement trials.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildFeatureTile('Zero Commission O2O', 'Retain 100% of your earnings on every fitting inquiry.'),
                      const SizedBox(height: AppSpacing.md),
                      _buildFeatureTile('Direct WhatsApp Leads', 'Brides connect with you without intermediary platform delays.'),
                      const SizedBox(height: AppSpacing.md),
                      _buildFeatureTile('Verified Gold Badge', 'Build community trust with curated artisan portfolio galleries.'),
                      const SizedBox(height: AppSpacing.xxl),
                      CustomButton(
                        label: 'Get Started — Register Studio ✨',
                        variant: ButtonVariant.primary,
                        onPressed: () => context.push(VendorRoutePaths.signup),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: const BorderSide(color: AppColors.accentGold)),
                          elevation: 0,
                        ),
                        onPressed: () => context.push(VendorRoutePaths.login),
                        child: const Text('Existing Partner? Login Here', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, color: AppColors.accentGold, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
