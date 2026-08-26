import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:her_area/core/routing/route_paths.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_typography.dart';
import 'package:shared/widgets/empty_state_widget.dart';
import 'package:her_area/core/widgets/store_card.dart';
import 'package:her_area/data/repositories/customer_api_repository.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favIds = ref.watch(favoritesProvider);
    final allStores = ref.watch(allStoresProvider).value ?? [];
    final favStores = allStores.where((s) => favIds.contains(s.id)).toList();
    final isWide = MediaQuery.sizeOf(context).width >= 750;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Favorites', style: TextStyle(fontFamily: AppTypography.displayFont, fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        actions: [
          if (favStores.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.primaryRuby),
              tooltip: 'Clear All Favorites',
              onPressed: () {
                for (final s in favStores) {
                  ref.read(favoritesProvider.notifier).toggleFavorite(s.id);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cleared all bookmarked stores.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: favStores.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: EmptyStateWidget(
                  icon: Icons.favorite_border_rounded,
                  title: 'No Saved Favorites Yet',
                  description: 'Explore our curated neighborhood boutiques and bridal studios. Tap the heart icon on any store to save them to your personal shortlist for quick booking.',
                  actionLabel: 'Explore Discovery Feed',
                  onActionPressed: () => context.go(RoutePaths.home),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: CustomScrollView(
                  slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        'Your Curated Shortlist (${favStores.length})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontFamily: AppTypography.displayFont,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
                  if (isWide)
                    SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.xl,
                        mainAxisSpacing: AppSpacing.xl,
                        childAspectRatio: 1.15,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final store = favStores[index];
                          return StoreCard(
                            store: store,
                            onTap: () => context.push(RoutePaths.buildStoreDetailsPath(store.id)),
                          );
                        },
                        childCount: favStores.length,
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final store = favStores[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: StoreCard(
                              store: store,
                              onTap: () => context.push(RoutePaths.buildStoreDetailsPath(store.id)),
                            ),
                          );
                        },
                        childCount: favStores.length,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 60)),
                ],
              ),
            ),
      ),
    );
  }
}
