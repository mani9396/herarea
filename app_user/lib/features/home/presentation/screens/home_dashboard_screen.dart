import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:her_area/core/widgets/store_card.dart';
import 'package:shared/models/store_model.dart';
import 'package:her_area/data/mock/mock_data.dart';
import 'package:her_area/data/mock/mock_store_repository.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(allStoresProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(allStoresProvider),
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
                            onTap: () => _showLocationChangeDialog(context),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.primaryRuby),
                                const SizedBox(width: 2),
                                Text(
                                  'Jubilee Hills, Hyderabad',
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
                    child: PageView.builder(
                      itemCount: MockData.promoBanners.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(
                              image: NetworkImage(MockData.promoBanners[index]),
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

  void _showLocationChangeDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GPS Accuracy: 99.8% • Locked to Jubilee Hills & Banjara Hills radius.')),
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
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppTheme.blushPink, child: Icon(Icons.auto_awesome, color: AppTheme.primaryRuby)),
              title: const Text('New Maggam Specialist Added!'),
              subtitle: const Text('Tejasi Studio just offered 10% discount for HER AREA visitors.'),
              trailing: const Text('2h ago', style: TextStyle(fontSize: 12, color: Colors.grey)),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppTheme.blushPink, child: Icon(Icons.favorite, color: AppTheme.primaryRuby)),
              title: const Text('Vanya Sarees updated their catalog'),
              subtitle: const Text('Explore 15 new Banarasi bridal arrivals.'),
              trailing: const Text('1d ago', style: TextStyle(fontSize: 12, color: Colors.grey)),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
