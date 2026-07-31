import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_typography.dart';

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Legal & Privacy', style: TextStyle(fontFamily: AppTypography.displayFont, fontWeight: FontWeight.w700)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
          bottom: TabBar(
            labelColor: AppColors.primaryRuby,
            unselectedLabelColor: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
            indicatorColor: AppColors.primaryRuby,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontFamily: AppTypography.displayFont),
            tabs: const [
              Tab(text: 'TERMS OF SERVICE'),
              Tab(text: 'PRIVACY POLICY'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _buildLegalSection(
                context,
                isDark,
                title: 'HER AREA O2O Customer Terms of Service',
                lastUpdated: 'Effective Date: July 2026',
                sections: [
                  {
                    'title': '1. Platform Overview & Scope',
                    'content': 'HER AREA is a specialized local discovery and Online-to-Offline (O2O) styling platform. We curate verified neighborhood bridal studios, bespoke tailoring houses, and artisan weaving centers. By accessing the application, you agree to abide by these operating standards.'
                  },
                  {
                    'title': '2. Booking Consultations & Trials',
                    'content': 'When requesting a home measurement or custom saree draping trial, merchants reserve verified female consultants to visit your location. Cancellations must be communicated directly via our integrated WhatsApp concierge at least 4 hours prior to the appointment slot.'
                  },
                  {
                    'title': '3. VIP Perks & Discount Assurance',
                    'content': 'Discounts and exclusive seasonal pricing listed on store profile pages are honored when presenting your active digital profile screen inside participating merchant boutiques.'
                  },
                  {
                    'title': '4. Authentic Reviews & Content Standards',
                    'content': 'All reviews submitted via HER AREA are cross-referenced with location check-ins or booking inquiries to preserve community integrity. Fraudulent or defamatory submissions are strictly removed.'
                  },
                ],
              ),
              _buildLegalSection(
                context,
                isDark,
                title: 'Customer Privacy & Location Security',
                lastUpdated: 'Effective Date: July 2026',
                sections: [
                  {
                    'title': '1. Hyper-Local GPS & Neighborhood Data',
                    'content': 'Your spatial location coordinates are exclusively processed to compute precise distances to nearby silk houses and bridal studios. You may opt to manually fix your discovery hub without continuous GPS streaming at any time.'
                  },
                  {
                    'title': '2. Communication Protection & WhatsApp Integration',
                    'content': 'When tapping "WhatsApp" or "Call Store", direct communication bridges are established with verified store owners. HER AREA does not sell or distribute your mobile number to unauthorized advertisers.'
                  },
                  {
                    'title': '3. Style Profile Customization',
                    'content': 'Preferences selected during onboarding (e.g., Maggam Work, Antique Jewellery) are stored securely to tailor your dynamic discovery feed and curate exclusive promotions.'
                  },
                  {
                    'title': '4. Right to Deletion & Account Control',
                    'content': 'You maintain full sovereignty over your personal data. You may export your saved bookmarks or request full account erasure at any time via the Help & Support concierge.'
                  },
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegalSection(
    BuildContext context,
    bool isDark, {
    required String title,
    required String lastUpdated,
    required List<Map<String, String>> sections,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDark : AppColors.blushPink.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryRuby.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.gavel_rounded, color: AppColors.primaryRuby, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(lastUpdated, style: TextStyle(color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ...sections.map((sec) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sec['title']!,
                  style: const TextStyle(
                    fontFamily: AppTypography.displayFont,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryRuby,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  sec['content']!,
                  style: TextStyle(
                    color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
                    height: 1.6,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
