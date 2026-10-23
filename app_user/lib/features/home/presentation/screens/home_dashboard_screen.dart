import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared/shared.dart';
import 'package:her_area/core/widgets/store_card.dart';
import 'package:her_area/data/repositories/customer_api_repository.dart';
import 'package:her_area/core/state/app_state_provider.dart';
import 'package:shared/widgets/category_icon_widget.dart';
import 'package:her_area/features/home/presentation/screens/story_viewer_screen.dart';
import 'package:her_area/core/state/viewed_stories_provider.dart';
import 'package:her_area/core/constants/avatar_constants.dart';
import 'package:her_area/core/routing/route_paths.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(nearbyStoresProvider);
    final bannersAsync = ref.watch(promoBannersProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final storiesAsync = ref.watch(customerStoriesProvider);
    final userLocation = ref.watch(userLocationProvider);
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.refresh(nearbyStoresProvider);
            ref.refresh(customerStoriesProvider);
          },
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
                    Builder(
                      builder: (context) {
                        final profile = ref.watch(userProfileProvider);
                        final avatarUrl = profile.avatarUrl.trim();
                        return InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () => context.go(RoutePaths.profile),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.accentGold,
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 19,
                              backgroundColor: AppColors.primaryRuby.withValues(alpha: 0.12),
                              backgroundImage: avatarUrl.isNotEmpty ? UserAvatars.getImageProvider(avatarUrl) : null,
                              child: avatarUrl.isEmpty
                                  ? const Icon(Icons.person_rounded, size: 22, color: AppColors.primaryRuby)
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () => context.go(RoutePaths.profile),
                            child: Builder(
                              builder: (context) {
                                final profileName = ref.watch(userProfileProvider).name;
                                final sessionUser = ref.watch(authSessionProvider).currentUser?.fullName;
                                String greetingName = 'Welcome';
                                if (profileName.isNotEmpty && profileName != 'Guest') {
                                  greetingName = profileName.split(' ').first;
                                } else if (sessionUser != null && sessionUser.isNotEmpty && sessionUser != 'HER AREA User') {
                                  greetingName = sessionUser.split(' ').first;
                                }

                                if (greetingName == 'Welcome') {
                                  return FutureBuilder<String?>(
                                    future: AuthTokenStorage().getUserName(),
                                    builder: (context, snapshot) {
                                      final cached = snapshot.data;
                                      final name = (cached != null && cached.isNotEmpty && cached != 'Guest' && cached != 'HER AREA User')
                                          ? cached.split(' ').first
                                          : 'Welcome';
                                      return Text(
                                        'Hi, $name ✨',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      );
                                    },
                                  );
                                }

                                return Text(
                                  'Hi, $greetingName ✨',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                );
                              },
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showLocationChangeDialog(context, ref),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.primaryRuby),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    userLocation.cityName,
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_outlined, size: 26),
                          if (unreadCount > 0)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: const BoxDecoration(color: AppTheme.primaryRuby, shape: BoxShape.circle),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  unreadCount > 9 ? '9+' : '$unreadCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      tooltip: 'Notifications',
                      onPressed: () => context.push(RoutePaths.notifications),
                    ),
                  ],
                ),
              ),

              // Global Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search for stores, services, categories...',
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryRuby, size: 22),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryRuby),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),

              // Stories Tray
              if (_searchQuery.isEmpty)
                SliverToBoxAdapter(
                  child: storiesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (stories) {
                      if (stories.isEmpty) return const SizedBox.shrink();
                      final groups = stories.groupByStore();
                      if (groups.isEmpty) return const SizedBox.shrink();

                      final viewedStoryIds = ref.watch(viewedStoriesProvider);

                      // Sort groups: unviewed stories first, followed by fully viewed stores
                      final unviewedGroups = <StoreStoryGroup>[];
                      final viewedGroups = <StoreStoryGroup>[];
                      for (final group in groups) {
                        final isAllViewed = group.stories.isNotEmpty &&
                            (group.stories.every((s) => viewedStoryIds.contains(s.id)) ||
                             (group.storeId.isNotEmpty && viewedStoryIds.contains(group.storeId)));
                        if (isAllViewed) {
                          viewedGroups.add(group);
                        } else {
                          unviewedGroups.add(group);
                        }
                      }
                      final displayGroups = [...unviewedGroups, ...viewedGroups];

                      return Container(
                        height: 104,
                        margin: const EdgeInsets.only(top: 4, bottom: 8),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: displayGroups.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 14),
                          itemBuilder: (context, groupIndex) {
                            final group = displayGroups[groupIndex];
                            final mediaUrl = group.effectiveAvatarUrl;
                            final storeName = group.storeName;
                            final isAllViewed = group.stories.isNotEmpty &&
                                (group.stories.every((s) => viewedStoryIds.contains(s.id)) ||
                                 (group.storeId.isNotEmpty && viewedStoryIds.contains(group.storeId)));

                            // Start from the first unviewed story in this store's group
                            final firstUnviewedIdx = group.stories.indexWhere(
                              (s) => !viewedStoryIds.contains(s.id),
                            );
                            final initialStoryIndex = firstUnviewedIdx != -1 ? firstUnviewedIdx : 0;

                            return GestureDetector(
                              key: ValueKey('story_group_${group.storeId}'),
                              onTap: () {
                                // Mark all stories in this group as viewed immediately
                                ref.read(viewedStoriesProvider.notifier).markMultipleViewed([
                                  ...group.stories.map((s) => s.id),
                                  if (group.storeId.isNotEmpty) group.storeId,
                                ]);

                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    opaque: false,
                                    pageBuilder: (_, __, ___) => StoryViewerScreen(
                                      stories: group.stories,
                                      initialIndex: initialStoryIndex,
                                      allGroups: displayGroups.map((g) => g.stories).toList(),
                                      initialGroupIndex: groupIndex,
                                      onStoryViewed: (story) {
                                        ref.read(viewedStoriesProvider.notifier).markStoryViewed(story.id);
                                      },
                                      isStoryViewed: (id) => ref.read(viewedStoriesProvider).contains(id),
                                    ),
                                    transitionsBuilder: (_, animation, __, child) {
                                      return FadeTransition(opacity: animation, child: child);
                                    },
                                  ),
                                );
                              },
                              child: SizedBox(
                                width: 72,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2.5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        border: isAllViewed
                                            ? Border.all(
                                                color: Colors.grey.shade400,
                                                width: 1.8,
                                              )
                                            : null,
                                        gradient: isAllViewed
                                            ? null
                                            : const LinearGradient(
                                                colors: [
                                                  AppTheme.primaryRuby,
                                                  Color(0xFFFF8DA1),
                                                  Color(0xFFFFB300),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                        boxShadow: isAllViewed
                                            ? null
                                            : [
                                                BoxShadow(
                                                  color: AppTheme.primaryRuby.withValues(alpha: 0.25),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: CircleAvatar(
                                          radius: 28,
                                          backgroundColor: Colors.grey.shade100,
                                          backgroundImage: mediaUrl.isNotEmpty
                                              ? NetworkImage(mediaUrl)
                                              : null,
                                          child: mediaUrl.isEmpty
                                              ? Icon(
                                                  Icons.auto_awesome_rounded,
                                                  color: isAllViewed ? Colors.grey : AppTheme.primaryRuby,
                                                  size: 24,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      storeName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isAllViewed ? FontWeight.w500 : FontWeight.w600,
                                        color: isAllViewed ? Colors.grey.shade600 : Colors.black87,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),

              // Promotional Carousel Banner (Renders only when promotion cards actually exist)
              if (_searchQuery.isEmpty)
                bannersAsync.maybeWhen(
                  data: (banners) {
                    if (banners.isEmpty) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 16),
                        child: PromotionalBannerCarousel(banners: banners),
                      ),
                    );
                  },
                  orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                ),

              // Explore by Category Header
              if (_searchQuery.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('Discover Specialties', style: Theme.of(context).textTheme.titleLarge),
                      ),
                      TextButton(
                        onPressed: () => context.go('/categories'),
                        child: const Text('View All', style: TextStyle(color: AppTheme.primaryRuby, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),

              // Horizontal Category Pills / Icons
              if (_searchQuery.isEmpty)
              categoriesAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                ),
                error: (err, stack) => const SliverToBoxAdapter(child: SizedBox(height: 100)),
                data: (categories) {
                  if (categories.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                  return SliverToBoxAdapter(
                    child: SizedBox(
                      height: 100,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (context, idx) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final cat = categories[index];
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
                                  child: CategoryIconWidget(
                                    iconUrl: cat.iconUrl,
                                    color: AppTheme.primaryRuby,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(cat.name.length > 12 ? '${cat.name.substring(0, 10)}..' : cat.name, 
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),

              // Verified Neighborhood Stores Header
              if (_searchQuery.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Trusted & Verified Near You', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 2),
                            Text('Hand-curated local stores within your neighborhood', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
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
                data: (stores) {
                  final filteredStores = _searchQuery.isEmpty
                      ? stores
                      : stores.where((s) {
                          final q = _searchQuery.toLowerCase();
                          return s.name.toLowerCase().contains(q) ||
                              s.category.name.toLowerCase().contains(q) ||
                              s.description.toLowerCase().contains(q) ||
                              s.serviceTags.any((t) => t.toLowerCase().contains(q));
                        }).toList();

                  if (filteredStores.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Text('No results found for "$_searchQuery"'),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final store = filteredStores[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          child: StoreCard(
                            store: store,
                            onTap: () => context.push('/store-details/${store.id}'),
                          ),
                        );
                      },
                      childCount: filteredStores.length,
                    ),
                  );
                },
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
                    max: 25.0,
                    divisions: 24,
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
}

/// Auto-advancing promotional carousel banner that moves smoothly every 5 seconds
class PromotionalBannerCarousel extends StatefulWidget {
  final List<PromotionPublicModel> banners;

  const PromotionalBannerCarousel({super.key, required this.banners});

  @override
  State<PromotionalBannerCarousel> createState() => _PromotionalBannerCarouselState();
}

class _PromotionalBannerCarouselState extends State<PromotionalBannerCarousel> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (widget.banners.length <= 1) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pageController.hasClients) return;
      final nextIndex = (_currentIndex + 1) % widget.banners.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void didUpdateWidget(covariant PromotionalBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.banners.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              _startAutoScroll();
            },
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return GestureDetector(
                onTap: () async {
                  if (banner.promotionType == 'APP' && banner.destination != null) {
                    final type = banner.destination!['type'];
                    final id = banner.destination!['id'];
                    if (type == 'STORE') {
                      context.push('/store-details/$id');
                    } else if (type == 'CATEGORY') {
                      context.push('/categories');
                    }
                  } else if (banner.promotionType == 'EXTERNAL' && banner.destination != null) {
                    final url = banner.destination!['url'];
                    if (url != null) {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    }
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          banner.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade900,
                            child: const Center(
                              child: Icon(Icons.image_not_supported_outlined, color: Colors.white54, size: 36),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.85),
                                Colors.transparent,
                                Colors.transparent,
                              ],
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
                            if (banner.subtitle != null && banner.subtitle!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryRuby,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  banner.subtitle!.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              banner.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
            },
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.banners.length, (idx) {
              final isSelected = idx == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 5,
                width: isSelected ? 18 : 6,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryRuby : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
