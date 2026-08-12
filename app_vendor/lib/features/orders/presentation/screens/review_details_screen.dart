import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/state/vendor_app_state.dart';
import 'package:shared/shared.dart';

class ReviewDetailsScreen extends ConsumerStatefulWidget {
  final String customerName;
  const ReviewDetailsScreen({super.key, required this.customerName});

  @override
  ConsumerState<ReviewDetailsScreen> createState() => _ReviewDetailsScreenState();
}

class _ReviewDetailsScreenState extends ConsumerState<ReviewDetailsScreen> {
  final _replyController = TextEditingController();
  bool _replied = false;
  String _savedReply = '';

  void _onSubmitReply(String reviewId) {
    if (_replyController.text.trim().isEmpty) return;
    final text = _replyController.text.trim();
    ref.read(vendorReviewsProvider.notifier).replyToReview(reviewId, text);
    setState(() {
      _replied = true;
      _savedReply = text;
      _replyController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reply published directly to customer and store profile badge!')));
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final reviews = ref.watch(vendorReviewsProvider);
    final review = reviews.where((r) => r.id == widget.customerName || r.customerName == widget.customerName).firstOrNull;

    final customerName = review?.customerName ?? widget.customerName;
    final avatar = review?.avatarUrl ?? 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?q=80&w=200&auto=format&fit=crop';
    final rating = review?.rating ?? 5.0;
    final comment = review?.comment ?? 'No additional comments provided by customer.';
    final existingReply = review?.vendorReply ?? _savedReply;
    final isReplied = _replied || (review?.vendorReply != null && review!.vendorReply!.isNotEmpty);

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Review & Reply UI'), centerTitle: true, elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(avatar),
                            backgroundColor: AppColors.primaryRuby.withValues(alpha: 0.1),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(customerName, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.verified_rounded, color: AppColors.accentGold, size: 16),
                                    const SizedBox(width: 4),
                                    Text('Verified Bride • ${review?.dateText ?? 'Recent'}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.accentGold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                Text('$rating', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.accentGoldDark, fontSize: 16)),
                                const SizedBox(width: 4),
                                const Icon(Icons.star_rounded, color: AppColors.accentGoldDark, size: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      Text(
                        '"$comment"',
                        style: textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, height: 1.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text('Vendor Public Response & Courtesy Reply', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryRuby)),
                const SizedBox(height: AppSpacing.xs),
                Text('Your public response builds future trust with upcoming autumn brides browsing your portfolio.', style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                const SizedBox(height: AppSpacing.lg),
                if (isReplied)
                  CustomCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.storefront_rounded, color: AppColors.primaryRuby),
                            SizedBox(width: 8),
                            Text('Your Studio (Replied):', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryRuby)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(existingReply, style: const TextStyle(height: 1.5, fontSize: 15)),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              _replyController.text = existingReply;
                              setState(() => _replied = false);
                            },
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Edit Reply'),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  CustomTextField(
                    label: 'Write Courtesy Reply',
                    hintText: 'Thank you for choosing Tejasi Atelier for your grand Shravanam occasion...',
                    controller: _replyController,
                    maxLines: 4,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CustomButton(
                    label: 'Post Response to Profile ⭐',
                    onPressed: () => _onSubmitReply(review?.id ?? widget.customerName),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back to Reviews Overview'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
