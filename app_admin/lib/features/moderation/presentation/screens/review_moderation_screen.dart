import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/core/state/admin_providers.dart';
import 'package:app_admin/core/widgets/admin_status_chip.dart';
import 'package:app_admin/domain/models/admin_models.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/widgets/custom_button.dart';
import 'package:shared/widgets/empty_state_widget.dart';

class ReviewModerationScreen extends ConsumerStatefulWidget {
  const ReviewModerationScreen({super.key});

  @override
  ConsumerState<ReviewModerationScreen> createState() => _ReviewModerationScreenState();
}

class _ReviewModerationScreenState extends ConsumerState<ReviewModerationScreen> {
  bool _onlyReported = true;

  void _onDelete(AdminReviewModel r) {
    ref.read(adminReviewsProvider.notifier).deleteReview(r.id);
    ref.read(adminActivityLogProvider.notifier).logActivity('Deleted abusive review by "${r.customerName}" on ${r.vendorName}');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review permanently removed from vendor rating pool.')));
  }

  void _onRestore(AdminReviewModel r) {
    ref.read(adminReviewsProvider.notifier).restoreReview(r.id);
    ref.read(adminActivityLogProvider.notifier).logActivity('Dismissed report & restored review by "${r.customerName}"');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report dismissed; review restored to public visibility.')));
  }

  @override
  Widget build(BuildContext context) {
    final reviews = ref.watch(adminReviewsProvider);
    final displayed = reviews.where((r) => _onlyReported ? (r.isReported && r.status == AdminStatus.pending) : true).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Review & Dispute Moderation'),
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ToggleButtons(
                borderRadius: BorderRadius.circular(12),
                isSelected: [_onlyReported, !_onlyReported],
                onPressed: (idx) => setState(() => _onlyReported = idx == 0),
                constraints: const BoxConstraints(minHeight: 34, minWidth: 140),
                children: const [
                  Text('⚠️ Reported Disputes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('All Testimonials', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: displayed.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.thumb_up_alt_outlined,
                  title: _onlyReported ? 'No Active Dispute Reports' : 'No Reviews matching criteria',
                  description: _onlyReported ? 'Partner boutiques have not flagged any customer testimonials for abusive wording.' : 'No customer reviews recorded yet.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  itemCount: displayed.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.lg),
                  itemBuilder: (context, index) {
                    final r = displayed[index];
                    return _buildReviewCard(context, r);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, AdminReviewModel r) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: r.isReported ? Colors.red.withValues(alpha: 0.5) : Colors.grey.shade300, width: r.isReported ? 1.5 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primaryRuby,
                      child: Text(r.customerName[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.neutralCharcoal)),
                        Text('Reviewed studio: ${r.vendorName}', style: const TextStyle(color: AppColors.primaryRuby, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(12)),
                      child: Text('★ ${r.rating} / 5.0', style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.w900, fontSize: 13)),
                    ),
                    const SizedBox(width: 10),
                    AdminStatusChip(status: r.status),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
              child: Text(r.comment, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.neutralCharcoal, height: 1.4)),
            ),
            if (r.isReported && r.reportReason != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.red.shade200)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.report_problem_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Vendor Dispute Reason Submitted:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(r.reportReason!, style: TextStyle(color: Colors.red.shade900, fontSize: 13, height: 1.3)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (r.status == AdminStatus.pending && r.isReported) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomButton(
                    label: 'Delete Review 🗑️',
                    variant: ButtonVariant.outline,
                    isOutlined: true,
                    isFullWidth: false,
                    onPressed: () => _onDelete(r),
                  ),
                  const SizedBox(width: 16),
                  CustomButton(
                    label: 'Dismiss Report & Restore 🛡️',
                    isFullWidth: false,
                    onPressed: () => _onRestore(r),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
