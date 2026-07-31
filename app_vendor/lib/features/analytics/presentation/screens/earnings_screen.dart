import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                      const Text('Total O2O Lead Valuation (July 2026)', style: TextStyle(color: AppColors.neutralCharcoal, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      const Text('₹ 3,42,800', style: TextStyle(color: AppColors.neutralCharcoal, fontWeight: FontWeight.w900, fontSize: 36)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: const Text('Zero Commission Saved: ₹ 34,280 (10% standard platform fee waived) 🎉', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryRubyDark)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Recent Consultation Invoices', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.md),
                _buildInvoiceItem('Ananya Rao (Kanjivaram Bridal Set)', '₹ 45,000', 'Paid via UPI Direct'),
                _buildInvoiceItem('Dr. Keerthi Reddy (Maggam Work Alteration)', '₹ 8,900', 'Paid in Boutique Cash'),
                _buildInvoiceItem('Srinidhi Shetty (Bespoke Zardosi Lehenga)', '₹ 1,20,000', 'Direct Bank Transfer'),
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
