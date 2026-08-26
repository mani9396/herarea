import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_admin/core/state/admin_providers.dart';
import 'package:app_admin/core/widgets/admin_status_chip.dart';
import 'package:app_admin/domain/models/admin_models.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/widgets/empty_state_widget.dart';

class ReviewModerationScreen extends ConsumerStatefulWidget {
  const ReviewModerationScreen({super.key});

  @override
  ConsumerState<ReviewModerationScreen> createState() => _ReviewModerationScreenState();
}

class _ReviewModerationScreenState extends ConsumerState<ReviewModerationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onApprove(AdminReviewModel r) async {
    await ref.read(adminReviewsProvider.notifier).approveReview(r.id);
    ref.read(adminActivityLogProvider.notifier).logActivity('Approved review by "${r.customerName}" on ${r.vendorName}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Review approved and published.'), backgroundColor: Colors.green.shade700),
      );
    }
  }

  Future<void> _onReject(AdminReviewModel r) async {
    await ref.read(adminReviewsProvider.notifier).rejectReview(r.id);
    ref.read(adminActivityLogProvider.notifier).logActivity('Rejected review by "${r.customerName}" on ${r.vendorName}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Review rejected and hidden from public.'), backgroundColor: Colors.red.shade700),
      );
    }
  }

  Future<void> _onHide(AdminReviewModel r) async {
    await ref.read(adminReviewsProvider.notifier).hideReview(r.id);
    ref.read(adminActivityLogProvider.notifier).logActivity('Hidden review by "${r.customerName}" on ${r.vendorName}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Review hidden from public.'), backgroundColor: Colors.orange.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviews = ref.watch(adminReviewsProvider);

    final pending = reviews.where((r) => r.status == AdminStatus.pending).toList();
    final approved = reviews.where((r) => r.status == AdminStatus.approved).toList();
    final rejected = reviews.where((r) => r.status == AdminStatus.rejected || r.status == AdminStatus.suspended).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Moderation'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.read(adminReviewsProvider.notifier).loadLiveReviews(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Pending (${pending.length})'),
            Tab(text: 'Approved (${approved.length})'),
            Tab(text: 'Rejected (${rejected.length})'),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: TabBarView(
            controller: _tabController,
            children: [
              _ReviewList(
                reviews: pending,
                emptyTitle: 'No Pending Reviews',
                emptyDescription: 'All reviews have been moderated.',
                onApprove: _onApprove,
                onReject: _onReject,
                showApprove: true,
                showReject: true,
              ),
              _ReviewList(
                reviews: approved,
                emptyTitle: 'No Approved Reviews',
                emptyDescription: 'No reviews are currently published.',
                onHide: _onHide,
                onReject: _onReject,
                showHide: true,
                showReject: true,
              ),
              _ReviewList(
                reviews: rejected,
                emptyTitle: 'No Rejected Reviews',
                emptyDescription: 'No reviews have been rejected.',
                onApprove: _onApprove,
                showApprove: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewList extends StatelessWidget {
  final List<AdminReviewModel> reviews;
  final String emptyTitle;
  final String emptyDescription;
  final Future<void> Function(AdminReviewModel)? onApprove;
  final Future<void> Function(AdminReviewModel)? onReject;
  final Future<void> Function(AdminReviewModel)? onHide;
  final bool showApprove;
  final bool showReject;
  final bool showHide;

  const _ReviewList({
    required this.reviews,
    required this.emptyTitle,
    required this.emptyDescription,
    this.onApprove,
    this.onReject,
    this.onHide,
    this.showApprove = false,
    this.showReject = false,
    this.showHide = false,
  });

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.rate_review_outlined,
        title: emptyTitle,
        description: emptyDescription,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: reviews.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, index) {
        final r = reviews[index];
        return _ReviewCard(
          review: r,
          onApprove: showApprove ? () => onApprove?.call(r) : null,
          onReject: showReject ? () => onReject?.call(r) : null,
          onHide: showHide ? () => onHide?.call(r) : null,
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final AdminReviewModel review;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onHide;

  const _ReviewCard({
    required this.review,
    this.onApprove,
    this.onReject,
    this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    final r = review;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: r.status == AdminStatus.pending
              ? Colors.orange.withValues(alpha: 0.5)
              : r.status == AdminStatus.approved
                  ? Colors.green.withValues(alpha: 0.4)
                  : Colors.red.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primaryRuby,
                        child: Text(
                          r.customerName.isNotEmpty ? r.customerName[0].toUpperCase() : 'C',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Store: ${r.vendorName}', style: const TextStyle(color: AppColors.primaryRuby, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        '★ ${r.rating.toStringAsFixed(1)}',
                        style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AdminStatusChip(status: r.status),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Review comment
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
              child: Text(
                r.comment.isEmpty ? '(No comment)' : r.comment,
                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.neutralCharcoal, height: 1.4),
              ),
            ),
            // Action buttons
            if (onApprove != null || onReject != null || onHide != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onApprove != null)
                    _ActionButton(
                      label: 'Approve',
                      icon: Icons.check_circle_rounded,
                      color: Colors.green.shade600,
                      onTap: onApprove!,
                    ),
                  if (onHide != null) ...[
                    const SizedBox(width: 10),
                    _ActionButton(
                      label: 'Hide',
                      icon: Icons.visibility_off_rounded,
                      color: Colors.orange.shade600,
                      onTap: onHide!,
                    ),
                  ],
                  if (onReject != null) ...[
                    const SizedBox(width: 10),
                    _ActionButton(
                      label: 'Reject',
                      icon: Icons.cancel_rounded,
                      color: Colors.red.shade600,
                      onTap: onReject!,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 2,
      ),
    );
  }
}
