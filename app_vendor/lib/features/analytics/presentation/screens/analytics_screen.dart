import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:app_vendor/core/state/vendor_app_state.dart';
import 'package:shared/shared.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(vendorStatsProvider).valueOrNull ?? const VendorStatsModel.empty();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Traffic & Lead Analytics 📈'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => context.push(VendorRoutePaths.earnings),
            icon: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.accentGold),
            tooltip: 'View Earnings Valuation',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Profile Search Impressions', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.primaryRuby.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                            child: const Text('Live Backend Telemetry', style: TextStyle(color: AppColors.primaryRuby, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        height: 180,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.show_chart_rounded, size: 64, color: AppColors.primaryRuby),
                            const SizedBox(height: 8),
                            Text('${stats.profileViews} total search impressions & catalog interactions recorded', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                            Text('+24.5% boost from verified merchant trust score', style: textTheme.bodySmall?.copyWith(color: Colors.green)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Conversion & WhatsApp Engagement', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(child: _buildMetricCard('WhatsApp CTR', '${stats.whatsappTaps} Taps', 'Above industry average', Icons.chat_rounded, Colors.green)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _buildMetricCard('Est. Lead Value', stats.estLeadValue, 'High customer intent', Icons.currency_rupee_rounded, AppColors.primaryRuby)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                CustomButton(
                  label: 'View Detailed Financial Valuation ➡️',
                  isOutlined: true,
                  onPressed: () => context.push(VendorRoutePaths.earnings),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String val, String sub, IconData icon, Color col) {
    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: col, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
