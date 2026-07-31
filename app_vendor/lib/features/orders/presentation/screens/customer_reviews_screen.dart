import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:shared/shared.dart';

class CustomerReviewsScreen extends StatelessWidget {
  const CustomerReviewsScreen({super.key});

  static const List<Map<String, dynamic>> _reviews = [
    {
      'name': 'Dr. Keerthi Reddy',
      'avatar': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?q=80&w=200&auto=format&fit=crop',
      'rating': 5.0,
      'date': 'Yesterday',
      'comment': 'Their precision with French knot beads is unmatched! Customized my engagement blouse exactly to my diamond necklace contour.',
      'verified': true,
    },
    {
      'name': 'Srinidhi Shetty',
      'avatar': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=200&auto=format&fit=crop',
      'rating': 5.0,
      'date': 'July 22, 2026',
      'comment': 'Home measurement trial was super professional. Saved me two trips in Banjara Hills traffic!',
      'verified': true,
    },
    {
      'name': 'Ananya Rao Varma',
      'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200&auto=format&fit=crop',
      'rating': 4.8,
      'date': 'July 14, 2026',
      'comment': 'Loved the custom zari finish on my Muhurtam drape! Truly exquisite craftmanship.',
      'verified': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Verified Customer Reviews ⭐'), centerTitle: true, elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: _reviews.length,
            separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final r = _reviews[index];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push(VendorRoutePaths.buildReviewDetailsPath(r['name'] as String)),
                child: CustomCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(radius: 24, backgroundImage: NetworkImage(r['avatar'] as String)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(r['name'] as String, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 6),
                                    if (r['verified'] == true)
                                      const Icon(Icons.verified_rounded, color: AppColors.accentGold, size: 16),
                                  ],
                                ),
                                Text(r['date'] as String, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text('${r['rating']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 20),
                            ],
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(r['comment'] as String, style: textTheme.bodyMedium?.copyWith(height: 1.5)),
                      const SizedBox(height: AppSpacing.md),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => context.push(VendorRoutePaths.buildReviewDetailsPath(r['name'] as String)),
                          icon: const Icon(Icons.reply_rounded, size: 16, color: AppColors.primaryRuby),
                          label: const Text('Reply to Customer', style: TextStyle(color: AppColors.primaryRuby, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
