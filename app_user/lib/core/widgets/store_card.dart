import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/models/store_model.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:shared/widgets/status_badge.dart';
import 'package:her_area/data/repositories/customer_api_repository.dart';

class StoreCard extends ConsumerWidget {
  final StoreModel store;
  final VoidCallback onTap;

  const StoreCard({super.key, required this.store, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(favoritesProvider).contains(store.id);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Cover & Overlays
            Stack(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: Image.network(
                    store.gallery.isNotEmpty ? store.gallery.first.image : 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?q=80',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.storefront, size: 50, color: Colors.grey)),
                  ),
                ),
                // Gradient Overlay for text visibility
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withValues(alpha: 0.3), Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                      ),
                    ),
                  ),
                ),
                // Sponsored Tag
                if (store.isSponsored)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'SPONSORED',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                // Favorite Heart Toggle Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? AppTheme.primaryRuby : Colors.white,
                      size: 26,
                    ),
                    onPressed: () => ref.read(favoritesProvider.notifier).toggleFavorite(store.id),
                  ),
                ),
                // Bottom Overlay: Category & Price Tier
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          store.category.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.neutralCharcoal),
                        ),
                      ),
                      Text(
                        store.priceTier,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.accentGold),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Store Info Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (store.isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, size: 20, color: AppTheme.primaryRuby),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (store.reviewCount > 0) ...[
                        const Icon(Icons.star_rounded, size: 18, color: AppTheme.accentGold),
                        const SizedBox(width: 4),
                        Text(
                          store.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          ' (${store.reviewCount} ${store.reviewCount == 1 ? 'review' : 'reviews'})',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ] else
                        Text(
                          'No reviews yet',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                        ),
                      const Spacer(),
                      Icon(Icons.location_on_rounded, size: 16, color: Colors.grey.shade600),
                      Text(
                        '${store.distanceKm} km',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      StatusBadge(isOpen: store.isOpenNow, text: store.closingTimeText),
                      const Spacer(),
                      if (store.hasHomeMeasurement)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.blushPink,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Home Trial Avail',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primaryRuby),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
