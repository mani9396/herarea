import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class ReviewDetailsScreen extends StatefulWidget {
  final String customerName;
  const ReviewDetailsScreen({super.key, required this.customerName});

  @override
  State<ReviewDetailsScreen> createState() => _ReviewDetailsScreenState();
}

class _ReviewDetailsScreenState extends State<ReviewDetailsScreen> {
  final _replyController = TextEditingController();
  bool _replied = false;
  String _savedReply = '';

  void _onSubmitReply() {
    if (_replyController.text.trim().isEmpty) return;
    setState(() {
      _replied = true;
      _savedReply = _replyController.text.trim();
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
                            backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1524504388940-b1c1722653e1?q=80&w=200&auto=format&fit=crop'),
                            backgroundColor: AppColors.primaryRuby.withValues(alpha: 0.1),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.customerName, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.verified_rounded, color: AppColors.accentGold, size: 16),
                                    const SizedBox(width: 4),
                                    Text('Verified Bride • Jubilee Hills Checkpost', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.accentGold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                            child: const Row(
                              children: [
                                Text('5.0', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.accentGoldDark, fontSize: 16)),
                                SizedBox(width: 4),
                                Icon(Icons.star_rounded, color: AppColors.accentGoldDark, size: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      Text(
                        '"Their precision with French knot beads is unmatched! Customized my engagement blouse exactly to my diamond necklace contour. Home measurement trial was super professional and saved me two trips in traffic!"',
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
                if (_replied)
                  CustomCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.storefront_rounded, color: AppColors.primaryRuby),
                            SizedBox(width: 8),
                            Text('Tejasi Maggam Studio (You replied):', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryRuby)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(_savedReply, style: const TextStyle(height: 1.5, fontSize: 15)),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => setState(() => _replied = false),
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
                    onPressed: _onSubmitReply,
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
