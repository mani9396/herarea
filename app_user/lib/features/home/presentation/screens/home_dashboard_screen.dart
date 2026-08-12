import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:her_area/core/widgets/store_card.dart';
import 'package:shared/models/store_model.dart';
import 'package:her_area/data/repositories/customer_api_repository.dart';
import 'package:her_area/core/state/app_state_provider.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(nearbyStoresProvider);
    final bannersAsync = ref.watch(promoBannersProvider);
    final userLocation = ref.watch(userLocationProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(nearbyStoresProvider),
          color: AppTheme.primaryRuby,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // High-end Custom App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                elevation: 0,
                toolbarHeight: 70,
                title: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hi, Priya ✨',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: () => _showLocationChangeDialog(context, ref),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.primaryRuby),
                                const SizedBox(width: 2),
                                Text(
                                  userLocation.cityName,
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                ),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppTheme.primaryRuby),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Stack(
                        children: [
                          const Icon(Icons.notifications_outlined, size: 26),
                          Positioned(
                            right: 2,
                            top: 2,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(color: AppTheme.primaryRuby, shape: BoxShape.circle),
                            ),
                          ),
                        ],
                      ),
                      onPressed: () => _showNotificationSheet(context),
                    ),
                  ],
                ),
              ),

              // Promotional Carousel Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    height: 160,
                    child: bannersAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryRuby)),
                      error: (err, stack) => const SizedBox.shrink(),
                      data: (banners) {
                        if (banners.isEmpty) return const SizedBox.shrink();
                        return PageView.builder(
                          itemCount: banners.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                image: DecorationImage(
                                  image: NetworkImage(banners[index]),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 16,
                                    left: 16,
                                    right: 16,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: AppTheme.primaryRuby, borderRadius: BorderRadius.circular(6)),
                                          child: const Text('FESTIVE SPECIAL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text('Top Handloom Silks & Zardosi Masters Near You', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Explore by Category Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Discover Specialties', style: Theme.of(context).textTheme.titleLarge),
                      TextButton(
                        onPressed: () => context.go('/categories'),
                        child: const Text('View All', style: TextStyle(color: AppTheme.primaryRuby, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),

              // Horizontal Category Pills / Icons
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 100,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: BusinessCategory.values.length,
                    separatorBuilder: (context, idx) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final cat = BusinessCategory.values[index];
                      return GestureDetector(
                        onTap: () => context.go('/categories'),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.blushPink,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.primaryRuby.withValues(alpha: 0.15)),
                              ),
                              child: Icon(cat.iconData, color: AppTheme.primaryRuby, size: 28),
                            ),
                            const SizedBox(height: 6),
                            Text(cat.displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Verified Neighborhood Stores Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Trusted & Verified Near You', style: Theme.of(context).textTheme.titleLarge),
                          Text('Hand-curated local stores within your neighborhood', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune_rounded, color: AppTheme.primaryRuby),
                        onPressed: () => context.go('/nearby'),
                      ),
                    ],
                  ),
                ),
              ),

              // Stores List View
              storesAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator())),
                ),
                error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text('Error loading stores: $err'))),
                data: (stores) => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final store = stores[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: StoreCard(
                          store: store,
                          onTap: () => context.push('/store-details/${store.id}'),
                        ),
                      );
                    },
                    childCount: stores.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  void _showLocationChangeDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final radius = ref.watch(nearbyRadiusProvider);
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Discovery Radius', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('${radius.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 18, color: AppTheme.primaryRuby, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Adjust how far you want to search for verified stores around your current location.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  Slider(
                    value: radius,
                    min: 1.0,
                    max: 50.0,
                    divisions: 49,
                    activeColor: AppTheme.primaryRuby,
                    onChanged: (val) {
                      ref.read(nearbyRadiusProvider.notifier).state = val;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRuby,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Apply Filter'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showNotificationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Discoveries & Offers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text('No recent discoveries or live offers available at the moment.', style: TextStyle(fontSize: 15, color: Colors.grey)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
