import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_vendor/core/state/vendor_app_state.dart';
import 'package:shared/shared.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(vendorStatsProvider).valueOrNull ?? const VendorStatsModel.empty();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Partner Financial Overview 💰'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total O2O Lead Valuation (Live Balance)', style: TextStyle(color: AppColors.neutralCharcoal, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(stats.totalLeadValuation, style: const TextStyle(color: AppColors.neutralCharcoal, fontWeight: FontWeight.w900, fontSize: 36)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Text('Zero Commission Saved: ${stats.commissionSaved} (10% standard platform fee waived) 🎉', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryRubyDark)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Recent Consultation Invoices', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.md),
                ...stats.recentInvoices.map((inv) => _buildInvoiceItem(
                      inv['title'] ?? 'Consultation Invoice',
                      inv['amount'] ?? '₹ 0',
                      inv['method'] ?? 'Paid via Direct Transfer',
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceItem(String title, String amount, String method) {
    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(method, style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryRuby)),
        ],
      ),
    );
  }
}
