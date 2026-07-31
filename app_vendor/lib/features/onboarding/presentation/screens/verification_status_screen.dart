import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:shared/shared.dart';

class VerificationStatusScreen extends StatelessWidget {
  const VerificationStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentGold.withValues(alpha: 0.15),
                    border: Border.all(color: AppColors.accentGold, width: 3),
                  ),
                  child: const Icon(Icons.verified_user_rounded, size: 72, color: AppColors.accentGoldDark),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Partner Application Submitted! 🛡️',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Your bridal studio KYC details are currently under review by our Hyderabad curation moderators to maintain quality.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600], height: 1.5),
                ),
                const SizedBox(height: AppSpacing.xxl),
                CustomCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Onboarding Verification Milestones:', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppSpacing.md),
                      _buildMilestoneRow(true, '1. Business Identity & Mobile Verification', 'OTP phone check completed via SMS/WhatsApp.', 'VERIFIED', AppColors.success),
                      const Divider(height: 24),
                      _buildMilestoneRow(true, '2. Studio Coordinates & Operating Hours', 'Tagged in Banjara Hills commercial bridal zone.', 'COMPLETE', AppColors.success),
                      const Divider(height: 24),
                      _buildMilestoneRow(false, '3. Portfolio Craftsmanship Curation', 'Admin moderation team reviewing Silk saree quality.', 'IN PROGRESS', AppColors.accentGoldDark),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: AppColors.primaryRuby.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    children: [
                      Icon(Icons.rocket_launch_rounded, color: AppColors.primaryRuby),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You can explore your O2O command dashboard immediately in preview mode while approval completes!',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryRubyDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                CustomButton(
                  label: 'Enter Partner Dashboard Now 🚀',
                  onPressed: () => context.go(VendorRoutePaths.dashboard),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneRow(bool done, String title, String desc, String badge, Color badgeColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(done ? Icons.check_circle_rounded : Icons.pending_actions_rounded, color: badgeColor, size: 26),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
