import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:her_area/core/routing/route_paths.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_typography.dart';
import 'package:shared/widgets/custom_button.dart';
import 'package:shared/widgets/empty_state_widget.dart';
import 'package:her_area/core/widgets/store_card.dart';
import 'package:shared/models/store_model.dart';
import 'package:her_area/data/repositories/customer_api_repository.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  // Active Filter States
  String _selectedCategory = 'All';
  double _maxDistance = 15.0;
  double _minRating = 0.0;
  bool _onlyOpenNow = false;

  final List<String> _categories = [
    'All',
    'Sarees & Handlooms',
    'Maggam Work',
    'Bridal Makeup',
    'Bespoke Tailoring',
    'Antique Jewellery',
    'Organic Spas',
  ];

  final List<String> _recentSearches = [
    'Kanjivaram Silk',
    'Maggam Work near me',
    'Bridal Makeup Studio',
    'Bespoke Blouse Tailoring'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedCategory != 'All') count++;
    if (_maxDistance < 25.0) count++;
    if (_minRating > 0.0) count++;
    if (_onlyOpenNow) count++;
    return count;
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'All';
      _maxDistance = 25.0;
      _minRating = 0.0;
      _onlyOpenNow = false;
      _query = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final allStores = ref.watch(allStoresProvider).value ?? [];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.sizeOf(context).width >= 800;

    // Filter Logic
    final results = allStores.where((s) {
      if (_onlyOpenNow && !s.isOpenNow) return false;
      if (s.distanceKm > _maxDistance) return false;
      if (_minRating > 0.0 && s.rating < _minRating) return false;
      if (_selectedCategory != 'All' && !s.category.name.toLowerCase().contains(_selectedCategory.toLowerCase())) {
        return false;
      }

      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final matchesName = s.name.toLowerCase().contains(q);
        final matchesCat = s.category.name.toLowerCase().contains(q);
        final matchesDesc = s.description.toLowerCase().contains(q);
        final matchesTags = s.serviceTags.any((tag) => tag.toLowerCase().contains(q));
        if (!matchesName && !matchesCat && !matchesDesc && !matchesTags) return false;
      }

      return true;
    }).toList();

    final isSearchOrFilterActive = _query.isNotEmpty || _activeFilterCount > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Local Couture', style: TextStyle(fontFamily: AppTypography.displayFont, fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded, size: 26, color: AppColors.primaryRuby),
                tooltip: 'Filter Boutiques',
                onPressed: () => _showFilterModal(context, allStores),
              ),
              if (_activeFilterCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(color: AppColors.primaryRuby, shape: BoxShape.circle),
                    child: Text(
                      '$_activeFilterCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Box
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                onChanged: (val) => setState(() => _query = val),
                decoration: InputDecoration(
                  hintText: 'Search Kanjivaram silk, Zardosi work, salons...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryRuby),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Horizontal Category Filter Bar
            SizedBox(
              height: 54,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (context, idx) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final cat = _categories[idx];
                  final isSelected = _selectedCategory == cat;
                  return FilterChip(
                    label: Text(cat, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? Colors.white : (isDark ? AppColors.textHighDark : AppColors.textHighLight))),
                    selected: isSelected,
                    selectedColor: AppColors.primaryRuby,
                    checkmarkColor: Colors.white,
                    backgroundColor: isDark ? AppColors.surfaceVariantDark : Colors.white,
                    side: BorderSide(color: isSelected ? AppColors.primaryRuby : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? cat : 'All';
                      });
                    },
                  );
                },
              ),
            ),

            // Main Display Area
            Expanded(
              child: !isSearchOrFilterActive
                  ? _buildRecentSearches(isDark)
                  : _buildResultsView(results, isWide, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Searches', style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _recentSearches.map((keyword) {
              return ActionChip(
                label: Text(keyword, style: const TextStyle(fontWeight: FontWeight.w600)),
                avatar: const Icon(Icons.history_rounded, size: 18, color: AppColors.primaryRuby),
                backgroundColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                onPressed: () {
                  _searchController.text = keyword;
                  setState(() => _query = keyword);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xxl),

          const Text('Trending Couture Discovery Tags', style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['#TempleGold', '#BridalKanjivaram', '#AirbrushMakeup', '#SameDayStitching', '#ZardosiWeaves', '#HomeTrial'].map((t) => ActionChip(
              label: Text(t, style: const TextStyle(color: AppColors.primaryRuby, fontWeight: FontWeight.w800)),
              backgroundColor: isDark ? AppColors.primaryRuby.withValues(alpha: 0.15) : AppColors.blushPink.withValues(alpha: 0.4),
              side: BorderSide(color: AppColors.primaryRuby.withValues(alpha: 0.3)),
              onPressed: () {
                _searchController.text = t.replaceAll('#', '');
                setState(() => _query = t.replaceAll('#', ''));
              },
            )).toList(),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Search Tip Box
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: isDark ? AppColors.primaryGradient : null,
              color: isDark ? null : AppColors.blushPink.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.accentGold, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('VIP Concierge Search Tip', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? Colors.white : AppColors.primaryRuby)),
                      const SizedBox(height: 4),
                      Text('Use filters to quickly narrow down boutiques that offer private "Home Measurement Trials" or are open right now in your neighborhood.', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : AppColors.neutralCharcoal)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView(List<StoreModel> results, bool isWide, bool isDark) {
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: EmptyStateWidget(
          icon: Icons.search_off_rounded,
          title: 'No Matching Stores Found',
          description: 'We could not find any neighborhood boutiques or bridal salons matching your current search and filter combination. Try expanding your distance slider or resetting category constraints.',
          actionLabel: 'Reset Filters & Search',
          actionIcon: Icons.refresh_rounded,
          onActionPressed: _resetFilters,
        ),
      );
    }

    return Column(
      children: [
        // Results count header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Found ${results.length} verified ${results.length == 1 ? 'boutique' : 'boutiques'}',
                style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? AppColors.accentGold : AppColors.primaryRuby),
              ),
              TextButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.restart_alt_rounded, size: 16),
                label: const Text('Reset All', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        Expanded(
          child: isWide
              ? GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.xl,
                    mainAxisSpacing: AppSpacing.xl,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final store = results[index];
                    return StoreCard(
                      store: store,
                      onTap: () => context.push(RoutePaths.buildStoreDetailsPath(store.id)),
                    );
                  },
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.lg, top: 4, bottom: 80),
                  itemCount: results.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final store = results[index];
                    return StoreCard(
                      store: store,
                      onTap: () => context.push(RoutePaths.buildStoreDetailsPath(store.id)),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showFilterModal(BuildContext context, List<StoreModel> allStores) {
    double tempMaxDistance = _maxDistance;
    double tempMinRating = _minRating;
    bool tempOpenNow = _onlyOpenNow;
    String tempCategory = _selectedCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final theme = Theme.of(ctx);
            final isDark = theme.brightness == Brightness.dark;

            return Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filter Boutique Discovery', style: theme.textTheme.headlineSmall?.copyWith(fontFamily: AppTypography.displayFont, fontWeight: FontWeight.w800)),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempMaxDistance = 25.0;
                            tempMinRating = 0.0;
                            tempOpenNow = false;
                            tempCategory = 'All';
                          });
                        },
                        child: const Text('Default', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryRuby)),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Distance Slider
                  Text('Max Neighborhood Distance (${tempMaxDistance.toStringAsFixed(1)} km)', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Slider(
                    value: tempMaxDistance,
                    min: 1.0,
                    max: 25.0,
                    divisions: 24,
                    activeColor: AppColors.primaryRuby,
                    label: '${tempMaxDistance.toStringAsFixed(1)} km',
                    onChanged: (v) => setModalState(() => tempMaxDistance = v),
                  ),

                  // Minimum Rating
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Minimum Customer Rating', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 10,
                    children: [
                      {'label': 'Any', 'val': 0.0},
                      {'label': '4.0+ ★', 'val': 4.0},
                      {'label': '4.5+ ★', 'val': 4.5},
                      {'label': '4.8+ ★', 'val': 4.8},
                    ].map((item) {
                      final val = item['val'] as double;
                      final selected = tempMinRating == val;
                      return ChoiceChip(
                        label: Text(item['label'] as String, style: TextStyle(fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? Colors.white : (isDark ? AppColors.textHighDark : AppColors.textHighLight))),
                        selected: selected,
                        selectedColor: AppColors.primaryRuby,
                        backgroundColor: isDark ? AppColors.surfaceVariantDark : Colors.white,
                        onSelected: (sel) {
                          if (sel) setModalState(() => tempMinRating = val);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Open Now Switch
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Open Now Only', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    subtitle: const Text('Hide studios that are currently closed for the day.'),
                    value: tempOpenNow,
                    activeThumbColor: AppColors.primaryRuby,
                    onChanged: (val) => setModalState(() => tempOpenNow = val),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: CustomButton(
                          label: 'Apply Filters',
                          icon: Icons.check_circle_rounded,
                          onPressed: () {
                            setState(() {
                              _maxDistance = tempMaxDistance;
                              _minRating = tempMinRating;
                              _onlyOpenNow = tempOpenNow;
                              _selectedCategory = tempCategory;
                            });
                            Navigator.pop(ctx);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
