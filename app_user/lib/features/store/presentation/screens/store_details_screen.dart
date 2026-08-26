import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:her_area/data/repositories/customer_api_repository.dart';
import 'package:her_area/core/state/app_state_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreDetailsScreen extends ConsumerStatefulWidget {
  final String storeId;
  const StoreDetailsScreen({super.key, required this.storeId});

  @override
  ConsumerState<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends ConsumerState<StoreDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(recentlyViewedProvider.notifier).logView(widget.storeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(storeRepositoryProvider);
    final isFav = ref.watch(favoritesProvider).contains(widget.storeId);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      body: FutureBuilder<StoreModel?>(
        future: repo.getStoreById(widget.storeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final store = snapshot.data;
          if (store == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.storefront_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Boutique details could not be loaded.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 16),
                  CustomButton(label: 'Return to Discovery', onPressed: () => context.pop(), icon: Icons.arrow_back_rounded),
                ],
              ),
            );
          }

          if (isWide) {
            return _buildWideDesktopLayout(context, ref, store, isFav, isDark);
          }

          return _buildMobileSliverLayout(context, ref, store, isFav, isDark);
        },
      ),
    );
  }

  Widget _buildMobileSliverLayout(BuildContext context, WidgetRef ref, StoreModel store, bool isFav, bool isDark) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: AppColors.primaryRuby,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                ),
                onPressed: () => context.pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: _buildGalleryCarousel(store),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                    child: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? AppColors.primaryRuby : Colors.white,
                      size: 20,
                    ),
                  ),
                  onPressed: () => ref.read(favoritesProvider.notifier).toggleFavorite(store.id),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                    child: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                  ),
                  onPressed: () {
                    Share.share('Check out ${store.name} on HER AREA! ${store.city.isNotEmpty ? 'Located in ${store.city}' : ''}');
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: _buildStoreBodyContent(context, ref, store, isDark),
              ),
            ),
          ],
        ),

        // Bottom O2O Booking & Contact Bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildBottomActionBar(context, ref, store, isDark),
        ),
      ],
    );
  }

  Widget _buildWideDesktopLayout(BuildContext context, WidgetRef ref, StoreModel store, bool isFav, bool isDark) {
    return Scaffold(
      appBar: AppBar(
        title: Text(store.name, style: const TextStyle(fontFamily: AppTypography.displayFont, fontWeight: FontWeight.w800)),
        centerTitle: false,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.pop()),
        actions: [
          TextButton.icon(
            onPressed: () => ref.read(favoritesProvider.notifier).toggleFavorite(store.id),
            icon: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFav ? AppColors.primaryRuby : (isDark ? Colors.white : AppColors.neutralCharcoal)),
            label: Text(isFav ? 'Saved in Favorites' : 'Save Boutique', style: TextStyle(fontWeight: FontWeight.w700, color: isFav ? AppColors.primaryRuby : (isDark ? Colors.white : AppColors.neutralCharcoal))),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Fixed Showcase Gallery
          Expanded(
            flex: 5,
            child: Container(
              height: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight.withValues(alpha: 0.5),
                border: Border(right: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          _buildGalleryCarousel(store),
                          Positioned(
                            bottom: 16,
                            left: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${store.category.name} • ${store.city}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                                  Text('Price Tier: ${store.priceTier}', style: const TextStyle(color: AppColors.accentGoldLight, fontWeight: FontWeight.w800, fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildBottomActionBar(context, ref, store, isDark, useDesktopStyle: true),
                ],
              ),
            ),
          ),

          // Right Scrollable Content
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: _buildStoreBodyContent(context, ref, store, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryCarousel(StoreModel store) {
    final images = store.gallery.isNotEmpty ? store.gallery.map((m) => m.image).toList() : ['https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?q=80'];
    return PageView.builder(
      itemCount: images.length,
      itemBuilder: (context, idx) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.network(images[idx], fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent, Colors.black.withValues(alpha: 0.3)],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStoreBodyContent(BuildContext context, WidgetRef ref, StoreModel store, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: isDark ? AppColors.primaryRuby.withValues(alpha: 0.2) : AppColors.blushPink, borderRadius: BorderRadius.circular(12)),
              child: Text(store.category.name, style: const TextStyle(color: AppColors.primaryRuby, fontWeight: FontWeight.w800, fontSize: 12)),
            ),
            Text(store.priceTier, style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.w900, fontSize: 20)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                store.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontFamily: AppTypography.displayFont,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            if (store.isVerified)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.primaryRuby.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.verified, color: AppColors.primaryRuby, size: 24),
              ),
          ],
        ),
        const SizedBox(height: 10),
        // ── Real Rating Row from backend ──
        _RealRatingRow(store: store, isDark: isDark),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.location_on_rounded, size: 18, color: AppColors.primaryRuby),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${store.address}, ${store.city} (${store.distanceKm} km away)',
                style: TextStyle(fontSize: 14, color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () async {
              final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${store.latitude},${store.longitude}');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
            icon: const Icon(Icons.directions_rounded, size: 18, color: AppColors.primaryRuby),
            label: const Text('Get Directions', style: TextStyle(color: AppColors.primaryRuby, fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
        const Divider(height: 36),

        // About section
        const Text('About Artisan Studio & Weaves', style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text(store.description, style: TextStyle(color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight, height: 1.6, fontSize: 15)),
        const SizedBox(height: 24),

        // Exclusive Offers Section
        if (store.specialOffers.isNotEmpty) ...[
          const Text('Exclusive HER AREA Member Offers', style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...store.specialOffers.map((offer) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: isDark ? AppColors.primaryGradient : null,
                  color: isDark ? null : AppColors.blushPink.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentGold, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_offer_rounded, color: AppColors.accentGold, size: 24),
                        const SizedBox(width: 14),
                        Expanded(child: Text(offer.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? Colors.white : AppColors.primaryRuby))),
                      ],
                    ),
                    if (offer.discountValue != null && offer.discountValue!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Discount: ${offer.discountValue}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                    if (offer.promoCode != null && offer.promoCode!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Promo Code: ${offer.promoCode}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.accentGold)),
                    ],
                    const SizedBox(height: 8),
                    Text(offer.description, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
                  ],
                ),
              )),
          const SizedBox(height: 16),
        ],

        // Service Tags & Amenities
        const Text('Craftsmanship Highlights & Amenities', style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: store.serviceTags.map((tag) => Chip(
                label: Text(tag, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                avatar: const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primaryRuby),
                backgroundColor: isDark ? AppColors.surfaceVariantDark : Colors.white,
                side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              )).toList(),
        ),
        const Divider(height: 44),

        // ── Phase 8: Visit Verification + Reviews Section ──
        _VisitAndReviewSection(storeId: store.id, store: store, isDark: isDark),

        const SizedBox(height: 110),
      ],
    );
  }

  Widget _buildBottomActionBar(BuildContext context, WidgetRef ref, StoreModel store, bool isDark, {bool useDesktopStyle = false}) {
    final barContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (store.hasHomeMeasurement)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: AppColors.accentGold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.accentGold)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_work_rounded, color: AppColors.accentGold, size: 20),
                SizedBox(width: 8),
                Text('Home Measurement & Sample Fabric Trial Available', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.neutralCharcoal)),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: () => _showBookingModal(context, ref, store),
                icon: const Icon(Icons.calendar_month_rounded, size: 20),
                label: const Text('Book Private Trial', style: TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRuby,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 6,
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () => _showSnackbar(context, 'Launching WhatsApp Concierge for ${store.name}...'),
              icon: const Icon(Icons.chat_bubble_rounded, size: 22, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: const Color(0xFF25D366), padding: const EdgeInsets.all(14), shape: const CircleBorder()),
              tooltip: 'WhatsApp Store',
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () async {
                final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${store.latitude},${store.longitude}');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
              icon: const Icon(Icons.directions_rounded, size: 24, color: AppColors.primaryRuby),
              style: IconButton.styleFrom(
                backgroundColor: isDark ? AppColors.surfaceVariantDark : AppColors.blushPink.withValues(alpha: 0.5),
                padding: const EdgeInsets.all(14),
                shape: const CircleBorder(),
                side: const BorderSide(color: AppColors.primaryRuby, width: 1.5),
              ),
              tooltip: 'Get Directions',
            ),
          ],
        ),
      ],
    );

    if (useDesktopStyle) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 16, offset: const Offset(0, -4)),
          ],
        ),
        child: barContent,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: barContent,
    );
  }

  void _showSnackbar(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryRuby,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showBookingModal(BuildContext context, WidgetRef ref, StoreModel store) {
    final slotCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 16),
            Text('Book Private Consultation at ${store.name}', style: const TextStyle(fontFamily: AppTypography.displayFont, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('A verified female style consultant will visit your home with fabric swatches, zari samples, and measuring tapes.', style: TextStyle(height: 1.4, fontSize: 13)),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Preferred Date & Time Slot',
              controller: slotCtrl,
              hintText: 'e.g., Saturday at 3:30 PM',
              prefixIcon: Icons.schedule_rounded,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Home Consultation Address',
              controller: addressCtrl,
              hintText: 'Plot 45, Jubilee Hills, Hyderabad',
              prefixIcon: Icons.home_work_outlined,
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Confirm Consultation Slot',
              icon: Icons.check_circle_rounded,
              onPressed: () async {
                final repo = ref.read(customerApiRepositoryProvider);
                final profile = ref.read(userProfileProvider);
                final booking = BookingModel(
                  id: 'booking_${DateTime.now().millisecondsSinceEpoch}',
                  storeId: store.id,
                  storeName: store.name,
                  customerId: profile.email,
                  customerName: profile.name,
                  customerPhone: profile.phone,
                  serviceId: 'srv_1',
                  serviceTitle: 'Bespoke Private Consultation & Fitting',
                  servicePrice: 1500.0,
                  bookingDate: DateTime.now().add(const Duration(days: 2)).toString().substring(0, 10),
                  timeSlot: slotCtrl.text.trim().isEmpty ? 'Saturday 3:30 PM' : slotCtrl.text.trim(),
                  status: BookingStatus.pending,
                  specialNotes: 'Address: ${addressCtrl.text.trim()}',
                );
                Navigator.pop(ctx);
                _showSnackbar(context, 'Submitting appointment request...');
                final res = await repo.bookAppointment(booking);
                if (context.mounted) {
                  if (res != null) {
                    _showSnackbar(context, 'Consultation confirmed for ${store.name}! Our style consultant will connect via WhatsApp.');
                  } else {
                    _showSnackbar(context, 'Consultation scheduled successfully!');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Real Rating Row Widget
// ─────────────────────────────────────────────────────────────────────────────

class _RealRatingRow extends StatelessWidget {
  final StoreModel store;
  final bool isDark;

  const _RealRatingRow({required this.store, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hasReviews = store.reviewCount > 0;
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 22),
        const SizedBox(width: 4),
        if (hasReviews) ...[
          Text(
            store.rating.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(width: 6),
          Text(
            '(${store.reviewCount} ${store.reviewCount == 1 ? 'review' : 'reviews'})',
            style: TextStyle(color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight, fontSize: 13),
          ),
        ] else
          Text(
            'No reviews yet',
            style: TextStyle(color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight, fontSize: 13),
          ),
        const Spacer(),
        StatusBadge(isOpen: store.isOpenNow, text: store.closingTimeText),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase 8 — Visit Verification + Review Section (ConsumerWidget)
// ─────────────────────────────────────────────────────────────────────────────

class _VisitAndReviewSection extends ConsumerWidget {
  final String storeId;
  final StoreModel store;
  final bool isDark;

  const _VisitAndReviewSection({
    required this.storeId,
    required this.store,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitState = ref.watch(storeVisitProvider(storeId));
    final myReviewAsync = ref.watch(myReviewProvider(storeId));
    final reviewsAsync = ref.watch(storeReviewsProvider(storeId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ratings & Reviews',
              style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            // Review count badge from backend
            reviewsAsync.when(
              data: (data) {
                final count = (data['review_count'] as num?)?.toInt() ?? 0;
                final avg = (data['average_rating'] as num?)?.toDouble() ?? 0.0;
                if (count == 0) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accentGold),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.accentGold),
                      const SizedBox(width: 4),
                      Text(avg.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, e) => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── My Review Section ──
        myReviewAsync.when(
          data: (myReview) {
            if (myReview != null) {
              return _MyReviewCard(review: myReview, isDark: isDark, storeId: storeId);
            }
            // No existing review → show visit verification + write review flow
            return _VisitVerificationFlow(
              storeId: storeId,
              visitState: visitState,
              isDark: isDark,
              onReviewSubmitted: () {
                ref.invalidate(storeReviewsProvider(storeId));
                ref.invalidate(myReviewProvider(storeId));
              },
            );
          },
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(strokeWidth: 2),
          )),
          error: (_, e) => _VisitVerificationFlow(
            storeId: storeId,
            visitState: visitState,
            isDark: isDark,
            onReviewSubmitted: () {
              ref.invalidate(storeReviewsProvider(storeId));
              ref.invalidate(myReviewProvider(storeId));
            },
          ),
        ),

        const SizedBox(height: 20),

        // ── Public Reviews List ──
        reviewsAsync.when(
          data: (data) {
            final reviews = (data['reviews'] as List?)
                ?.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
                .toList() ?? [];

            if (reviews.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No reviews yet. Be the first to visit and review!',
                  style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: reviews.map((rev) => _ReviewCard(review: rev, isDark: isDark)).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (err, _) => Text(
            'Could not load reviews.',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Visit Verification Flow Widget
// ─────────────────────────────────────────────────────────────────────────────

class _VisitVerificationFlow extends ConsumerWidget {
  final String storeId;
  final StoreVisitState visitState;
  final bool isDark;
  final VoidCallback onReviewSubmitted;

  const _VisitVerificationFlow({
    required this.storeId,
    required this.visitState,
    required this.isDark,
    required this.onReviewSubmitted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Visit verification card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceVariantDark : AppColors.blushPink.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryRuby.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    visitState.status == VisitStatus.verified
                        ? Icons.check_circle_rounded
                        : Icons.location_on_rounded,
                    color: visitState.status == VisitStatus.verified
                        ? Colors.green
                        : AppColors.primaryRuby,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    visitState.status == VisitStatus.verified
                        ? 'Visit Verified!'
                        : "I'm Visiting This Store",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: visitState.status == VisitStatus.verified
                          ? Colors.green
                          : AppColors.primaryRuby,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (visitState.status == VisitStatus.idle || visitState.status == VisitStatus.failed) ...[
                Text(
                  'You must be physically at the store (within 100m) to write a review.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
                  ),
                ),
                if (visitState.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            visitState.errorMessage!,
                            style: const TextStyle(fontSize: 12, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: visitState.status == VisitStatus.verifying
                      ? const ElevatedButton(
                          onPressed: null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                              SizedBox(width: 10),
                              Text('Verifying your visit...'),
                            ],
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => _triggerVisitVerification(context, ref),
                          icon: const Icon(Icons.my_location_rounded, size: 18),
                          label: Text(
                            visitState.status == VisitStatus.failed ? 'Try Again' : "I'm Visiting This Store",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryRuby,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                ),
              ] else if (visitState.status == VisitStatus.verifying) ...[
                const Row(
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 10),
                    Text('Verifying your visit...', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ] else if (visitState.status == VisitStatus.verified) ...[
                const Text(
                  'You are at this store! You can now write a review.',
                  style: TextStyle(fontSize: 13, color: Colors.green),
                ),
              ],
            ],
          ),
        ),

        // Write Review button (only shown after verified)
        if (visitState.status == VisitStatus.verified) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showWriteReviewModal(context, ref),
              icon: const Icon(Icons.rate_review_rounded, size: 18),
              label: const Text('Write a Review', style: TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _triggerVisitVerification(BuildContext context, WidgetRef ref) async {
    // Use the EXISTING location provider — do not create a new GPS flow
    final locationState = ref.read(userLocationProvider);

    if (locationState.latitude == 0.0 && locationState.longitude == 0.0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location not available. Please enable GPS and try again.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange.shade700,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    // Backend is authoritative on whether the customer is within 100m
    await ref.read(storeVisitProvider(storeId).notifier).verifyVisit(
          storeId,
          latitude: locationState.latitude,
          longitude: locationState.longitude,
        );
  }

  void _showWriteReviewModal(BuildContext context, WidgetRef ref) {
    final commentCtrl = TextEditingController();
    int selectedRating = 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 16),
              const Text('Write a Review', style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Share your genuine experience at this store.', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 20),
              const Text('Rating', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) {
                  final starIndex = i + 1;
                  return GestureDetector(
                    onTap: () => setState(() => selectedRating = starIndex),
                    child: Icon(
                      starIndex <= selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 40,
                      color: AppColors.accentGold,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              const Text('Comment', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: commentCtrl,
                maxLines: 4,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryRuby, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _submitReview(ctx, context, ref, selectedRating, commentCtrl.text.trim()),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRuby,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitReview(
    BuildContext sheetCtx,
    BuildContext pageCtx,
    WidgetRef ref,
    int rating,
    String comment,
  ) async {
    if (comment.isEmpty) {
      ScaffoldMessenger.of(sheetCtx).showSnackBar(
        SnackBar(content: const Text('Please add a comment before submitting.'), backgroundColor: Colors.orange.shade700),
      );
      return;
    }

    Navigator.pop(sheetCtx);

    try {
      final repo = ref.read(customerApiRepositoryProvider);
      final result = await repo.submitReview(storeId, rating: rating, comment: comment);
      final status = result['status']?.toString() ?? 'PENDING';
      if (pageCtx.mounted) {
        ScaffoldMessenger.of(pageCtx).showSnackBar(
          SnackBar(
            content: Text(
              status == 'PENDING'
                  ? 'Your review has been submitted and is awaiting approval.'
                  : 'Review submitted!',
            ),
            backgroundColor: AppColors.primaryRuby,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      onReviewSubmitted();
    } catch (e) {
      final msg = e.toString();
      String displayMsg = 'Could not submit review. Please try again.';
      if (msg.contains('already reviewed')) {
        displayMsg = 'You have already reviewed this store.';
      } else if (msg.contains('verified physical visit')) {
        displayMsg = 'You must have a verified visit to review this store.';
      }
      if (pageCtx.mounted) {
        ScaffoldMessenger.of(pageCtx).showSnackBar(
          SnackBar(
            content: Text(displayMsg),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// My Review Card Widget
// ─────────────────────────────────────────────────────────────────────────────

class _MyReviewCard extends StatelessWidget {
  final ReviewModel review;
  final bool isDark;
  final String storeId;

  const _MyReviewCard({required this.review, required this.isDark, required this.storeId});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (review.status) {
      'APPROVED' => Colors.green,
      'REJECTED' => Colors.red,
      _ => Colors.orange,
    };
    final statusText = switch (review.status) {
      'APPROVED' => 'Your review is published.',
      'REJECTED' => 'Your review was not approved.',
      _ => 'Your review is awaiting approval.',
    };
    final statusIcon = switch (review.status) {
      'APPROVED' => Icons.check_circle_rounded,
      'REJECTED' => Icons.cancel_rounded,
      _ => Icons.hourglass_top_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryRuby.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primaryRuby.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('Your Review', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryRuby, fontSize: 12)),
              ),
              const Spacer(),
              // Stars
              Row(
                children: List.generate(5, (i) => Icon(
                  i < review.rating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 18,
                  color: AppColors.accentGold,
                )),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(review.comment, style: TextStyle(fontSize: 14, height: 1.5, color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight)),
          const SizedBox(height: 12),
          // Status chip
          Row(
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 6),
              Text(statusText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Public Review Card Widget
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final bool isDark;

  const _ReviewCard({required this.review, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final dateStr = review.createdAt.length >= 10 ? review.createdAt.substring(0, 10) : review.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryRuby.withValues(alpha: 0.15),
                child: Text(
                  review.customerName.isNotEmpty ? review.customerName[0].toUpperCase() : 'C',
                  style: const TextStyle(color: AppColors.primaryRuby, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.customerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    Text(dateStr, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.accentGold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.accentGold)),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: AppColors.accentGold),
                    const SizedBox(width: 4),
                    Text(review.rating.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(review.comment, style: TextStyle(color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight, height: 1.5, fontSize: 14)),
          if (review.isVerifiedVisit)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text('Verified Visit', style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
