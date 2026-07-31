import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_admin/core/routing/admin_route_paths.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_typography.dart';
import 'package:shared/widgets/custom_button.dart';

class AnalyticsHubScreen extends StatelessWidget {
  const AnalyticsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Telemetry, Health & Business Analytics'),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Infrastructure Health Telemetry 🟢', style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.neutralCharcoal)),
                        Text('Real-time mock metrics representing server nodes and PostgreSQL replica state', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                    CustomButton(
                      label: 'Export Ledger CSV 📥',
                      isFullWidth: false,
                      onPressed: () => context.push(AdminRoutePaths.reports),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width < 800 ? 2 : 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 2.1,
                  children: [
                    _buildHealthCard('API Edge Uptime', '99.98%', Icons.cloud_done_rounded, Colors.green),
                    _buildHealthCard('DB Replica Latency', '4.2 ms', Icons.speed_rounded, Colors.cyan),
                    _buildHealthCard('App Cache Memory', '31.4 GB / 64GB', Icons.memory_rounded, Colors.orange),
                    _buildHealthCard('Worker CPU Load', '24.8% avg', Icons.developer_board_rounded, AppColors.primaryRuby),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Regional Bridal Demand Heatmap', style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal)),
                              const SizedBox(height: 16),
                              _buildRegionProgress('Hyderabad Metropolitan Region (Jubilee Hills, Banjara Hills)', 0.68, '68% (₹8.45L GMV)'),
                              const SizedBox(height: 14),
                              _buildRegionProgress('Vijayawada Craft Studios (Benz Circle, MG Road)', 0.18, '18% (₹2.20L GMV)'),
                              const SizedBox(height: 14),
                              _buildRegionProgress('Visakhapatnam & Coastal Andhra', 0.10, '10% (₹1.25L GMV)'),
                              const SizedBox(height: 14),
                              _buildRegionProgress('Emerging Districts & NRI Dispatch', 0.04, '4% (₹0.55L GMV)'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(
                      flex: 2,
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Conversion Funnel KPIs', style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal)),
                              const SizedBox(height: 16),
                              _buildFunnelRow('Profile Visitors', '42,800', '100% baseline'),
                              const Divider(height: 24),
                              _buildFunnelRow('Atelier Chat Inquiries', '14,600', '34.1% conversion'),
                              const Divider(height: 24),
                              _buildFunnelRow('Confirmed Fitting Bookings', '6,150', '14.3% overall'),
                              const Divider(height: 24),
                              _buildFunnelRow('Completed Bridal Deliveries', '5,920', '96.2% fulfillment'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHealthCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color.withValues(alpha: 0.3))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(radius: 22, backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, color: color, size: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionProgress(String name, double value, String percentageText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Text(percentageText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primaryRuby)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: value, backgroundColor: Colors.grey.shade200, color: AppColors.primaryRuby, minHeight: 10, borderRadius: BorderRadius.circular(6)),
      ],
    );
  }

  Widget _buildFunnelRow(String label, String value, String rate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal)),
            Text(rate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primaryRuby)),
      ],
    );
  }
}
