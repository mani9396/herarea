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

class RecentlyViewedScreen extends ConsumerWidget {
  const RecentlyViewedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rvIds = ref.watch(recentlyViewedProvider);
    final allStores = ref.watch(allStoresProvider).value ?? [];
    
    // Sort recently viewed based on the order of rvIds
    final rvStores = <dynamic>[];
    for (final id in rvIds) {
      final store = allStores.where((s) => s.id == id).firstOrNull;
      if (store != null) {
        rvStores.add(store);
      }
    }
    
    final isWide = MediaQuery.sizeOf(context).width >= 750;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recently Viewed', style: TextStyle(fontFamily: AppTypography.displayFont, fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: rvStores.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: EmptyStateWidget(
                  icon: Icons.history_rounded,
                  title: 'No Recent History',
                  description: 'You haven\'t viewed any stores recently. Start exploring our curated boutiques and bridal studios!',
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
                        'Your Browsing History (${rvStores.length})',
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
                          final store = rvStores[index];
                          return StoreCard(
                            store: store,
                            onTap: () => context.push(RoutePaths.buildStoreDetailsPath(store.id)),
                          );
                        },
                        childCount: rvStores.length,
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final store = rvStores[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: StoreCard(
                              store: store,
                              onTap: () => context.push(RoutePaths.buildStoreDetailsPath(store.id)),
                            ),
                          );
                        },
                        childCount: rvStores.length,
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
