import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/theme/app_theme.dart';
import 'package:her_area/core/widgets/store_card.dart';
import 'package:her_area/data/repositories/customer_api_repository.dart';

class NearbyStoresScreen extends ConsumerStatefulWidget {
  const NearbyStoresScreen({super.key});

  @override
  ConsumerState<NearbyStoresScreen> createState() => _NearbyStoresScreenState();
}

class _NearbyStoresScreenState extends ConsumerState<NearbyStoresScreen> {
  bool _isMapView = false;

  @override
  Widget build(BuildContext context) {
    final radius = ref.watch(nearbyRadiusProvider);
    final nearbyStoresAsync = ref.watch(nearbyStoresProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Discovery'),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.format_list_bulleted_rounded : Icons.map_rounded, color: AppTheme.primaryRuby),
            tooltip: _isMapView ? 'Switch to List' : 'Switch to Map',
            onPressed: () => setState(() => _isMapView = !_isMapView),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Proximity Slider Controller Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.radar_rounded, color: AppTheme.primaryRuby, size: 20),
                          SizedBox(width: 8),
                          Text('Search Radius:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.primaryRuby, borderRadius: BorderRadius.circular(12)),
                        child: Text('${radius.toStringAsFixed(1)} km', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                  Slider(
                    value: radius,
                    min: 1.0,
                    max: 25.0,
                    divisions: 48,
                    activeColor: AppTheme.primaryRuby,
                    inactiveColor: Colors.grey.shade300,
                    onChanged: (newRadius) => ref.read(nearbyRadiusProvider.notifier).state = newRadius,
                  ),
                ],
              ),
            ),

            // Content View (List vs Simulated Map)
            Expanded(
              child: _isMapView
                  ? _buildSimulatedMapView(context)
                  : nearbyStoresAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error: $err')),
                      data: (stores) {
                        if (stores.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.wrong_location_outlined, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text('No stores found within ${radius.toStringAsFixed(1)} km.', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () => ref.read(nearbyRadiusProvider.notifier).state = 25.0,
                                  child: const Text('Expand Radius to 25 km'),
                                )
                              ],
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 80),
                          itemCount: stores.length,
                          itemBuilder: (context, index) {
                            final store = stores[index];
                            return StoreCard(
                              store: store,
                              onTap: () => context.push('/store-details/${store.id}'),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulatedMapView(BuildContext context) {
    final stores = ref.watch(nearbyStoresProvider).value ?? [];

    return Stack(
      children: [
        // Map Grid Wallpaper Simulator
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=1200&auto=format&fit=crop'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Overlay Tint
        Container(color: Colors.white.withValues(alpha: 0.15)),
        // Simulated Markers
        ...List.generate(stores.length, (index) {
          final s = stores[index];
          // Map live latitude and longitude coordinates to view coordinates
          final centerLat = 17.4326;
          final centerLon = 78.4071;
          final latDiff = s.latitude - centerLat;
          final lonDiff = s.longitude - centerLon;
          final top = (180.0 - (latDiff * 8000.0)).clamp(20.0, 380.0);
          final left = (150.0 + (lonDiff * 8000.0)).clamp(20.0, 300.0);

          return Positioned(
            top: top,
            left: left,
            child: GestureDetector(
              onTap: () => context.push('/store-details/${s.id}'),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRuby,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 3))],
                    ),
                    child: Icon(s.category.iconData, size: 20, color: Colors.white),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]),
                    child: Text(s.name.split(' ')[0], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        }),

        // Current Location Indicator in center
        Center(
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: AppTheme.primaryRuby.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Center(
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(color: Colors.blue.shade600, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
              ),
            ),
          ),
        ),

        // Bottom Map Info Card
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.explore_rounded, color: AppTheme.primaryRuby, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Showing ${stores.length} nearby verified places', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const Text('Tap any map icon to view store portfolio', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
