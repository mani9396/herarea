import 'package:flutter/material.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_typography.dart';
import 'package:shared/widgets/custom_button.dart';

class ReportsExportScreen extends StatefulWidget {
  const ReportsExportScreen({super.key});

  @override
  State<ReportsExportScreen> createState() => _ReportsExportScreenState();
}

class _ReportsExportScreenState extends State<ReportsExportScreen> {
  String _selectedReportType = 'Vendor GMV Financial Ledger (Monthly)';
  String _selectedDateRange = 'Last 30 Days (Jul 2026)';
  bool _isExporting = false;

  final List<String> _reportTypes = [
    'Vendor GMV Financial Ledger (Monthly)',
    'GST Tax Compliance & Studio Commission Report',
    'Customer Fitting Appointment & Booking Log',
    'Content Moderation & Dispute Audit Trail',
    'Registered Partner KYC & Legal Verification Status'
  ];

  final List<String> _dateRanges = [
    'Last 7 Days',
    'Last 30 Days (Jul 2026)',
    'Q2 2026 (Apr - Jun)',
    'YTD Financial Year 2026-27',
    'Custom Date Range Select...'
  ];

  void _onExport() async {
    setState(() => _isExporting = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() => _isExporting = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('Report Packaged & Ready!'),
            ],
          ),
          content: Text('Your selected report ("$_selectedReportType" for $_selectedDateRange) has been successfully compiled into a verifiable CSV / PDF archive.\n\nThe download has been dispatched to your corporate admin browser cache.'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRuby, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Acknowledge & Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Administrative Reports'),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.description_rounded, color: AppColors.primaryRuby, size: 40),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Data Export & Regulatory Auditing', style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.neutralCharcoal)),
                              Text('Export marketplace ledgers to spreadsheet compatible CSV or signed PDF format.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text('Select Report Category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.neutralCharcoal)),
                    const SizedBox(height: 12),
                    ..._reportTypes.map((rt) {
                      final isSelected = _selectedReportType == rt;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => setState(() => _selectedReportType = rt),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryRuby.withValues(alpha: 0.08) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isSelected ? AppColors.primaryRuby : Colors.grey.shade300, width: isSelected ? 2 : 1),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                                  color: isSelected ? AppColors.primaryRuby : Colors.grey,
                                  size: 22,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(rt, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 14, color: isSelected ? AppColors.primaryRuby : AppColors.neutralCharcoal)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    const Text('Select Audit Timeframe', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.neutralCharcoal)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDateRange,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                      items: _dateRanges.map((dr) => DropdownMenuItem(value: dr, child: Text(dr, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                      onChanged: (val) => setState(() => _selectedDateRange = val!),
                    ),
                    const SizedBox(height: 36),
                    CustomButton(
                      label: 'Compile & Export CSV Report 📊',
                      isLoading: _isExporting,
                      onPressed: _onExport,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
