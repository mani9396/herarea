import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

class CategorySelectionScreen extends StatelessWidget {
  const CategorySelectionScreen({super.key});

  static const List<Map<String, dynamic>> _categories = [
    {'title': 'Saree Stores & Handlooms', 'desc': 'Kanjivaram, Banarasi, Organza & Pure Silks', 'icon': Icons.checkroom_rounded},
    {'title': 'Maggam & Zardosi Work', 'desc': 'Intricate French knot blouses & Aari embroidery', 'icon': Icons.brush_rounded},
    {'title': 'Designer Boutiques', 'desc': 'Custom evening wear, lehengas & draping silhouettes', 'icon': Icons.dry_cleaning_rounded},
    {'title': 'Antique & Temple Jewellery', 'desc': 'Uncut diamond Polki, Kundan & bridal gold sets', 'icon': Icons.diamond_rounded},
    {'title': 'Bridal Makeup Studios', 'desc': 'HD Airbrush makeup, hair styling & trial sessions', 'icon': Icons.auto_awesome_rounded},
    {'title': 'Custom Tailoring & Fits', 'desc': 'Express same-day alterations & blouse stitching', 'icon': Icons.content_cut_rounded},
    {'title': 'Bespoke Accessories', 'desc': 'Embroidered potlis, clutches & traditional footwear', 'icon': Icons.shopping_bag_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Store Category'), centerTitle: true, elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: _categories.length,
            separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return CustomCard(
                onTap: () => context.pop(cat['title'] as String),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryRuby.withValues(alpha: 0.1),
                      child: Icon(cat['icon'] as IconData, color: AppColors.primaryRuby),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(cat['desc'] as String, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle_outline_rounded, color: AppColors.accentGold),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
