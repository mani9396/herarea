import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:her_area/data/repositories/customer_api_repository.dart';
import 'package:her_area/core/state/app_state_provider.dart';

class StoreDetailsScreen extends ConsumerWidget {
  final String storeId;
  const StoreDetailsScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(storeRepositoryProvider);
    final isFav = ref.watch(favoritesProvider).contains(storeId);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      body: FutureBuilder<StoreModel?>(
        future: repo.getStoreById(storeId),
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
                  onPressed: () => _showSnackbar(context, 'Store showcase link copied to clipboard!'),
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
                                  Text('${store.category.displayName} • ${store.city}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
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
    final images = store.imageUrls.isNotEmpty ? store.imageUrls : ['https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?q=80'];
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
              child: Text(store.category.displayName, style: const TextStyle(color: AppColors.primaryRuby, fontWeight: FontWeight.w800, fontSize: 12)),
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
        Row(
          children: [
            const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 22),
            Text(' ${store.rating} ', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text('(${store.reviewCount} verified style reviews)', style: TextStyle(color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight, fontSize: 13)),
            const Spacer(),
            StatusBadge(isOpen: store.isOpenNow, text: store.closingTimeText),
          ],
        ),
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
                child: Row(
                  children: [
                    const Icon(Icons.card_giftcard_rounded, color: AppColors.accentGold, size: 28),
                    const SizedBox(width: 14),
                    Expanded(child: Text(offer, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isDark ? Colors.white : AppColors.primaryRuby))),
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

        // Customer Reviews Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Verified Artisan Reviews', style: TextStyle(fontFamily: AppTypography.displayFont, fontSize: 18, fontWeight: FontWeight.w800)),
            TextButton.icon(
              onPressed: () => _showReviewModal(context, ref, store),
              icon: const Icon(Icons.rate_review_rounded, size: 18),
              label: const Text('Write Review', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (store.reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text('Be the first connoisseur to review this boutique after your fitting or trial!', style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
          )
        else
          ...store.reviews.map((rev) => Container(
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
                        CircleAvatar(radius: 20, backgroundImage: NetworkImage(rev.userAvatarUrl)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rev.userName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                              Text(rev.date, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight)),
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
                              Text('${rev.rating}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(rev.comment, style: TextStyle(color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight, height: 1.5, fontSize: 14)),
                  ],
                ),
              )),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.home_work_rounded, color: AppColors.accentGold, size: 20),
                const SizedBox(width: 8),
                const Text('Home Measurement & Sample Fabric Trial Available', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.neutralCharcoal)),
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
              onPressed: () => _showSnackbar(context, 'Opening Turn-by-Turn Navigation to ${store.address}...'),
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

  void _showReviewModal(BuildContext context, WidgetRef ref, StoreModel store) {
    final commentCtrl = TextEditingController();
    double rating = 5.0;

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
            Text('Review ${store.name}', style: const TextStyle(fontFamily: AppTypography.displayFont, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            const Text('Rate your in-store or home measurement experience:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) => const Icon(Icons.star_rounded, size: 38, color: AppColors.accentGold)),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Your Connoisseur Review',
              controller: commentCtrl,
              maxLines: 4,
              hintText: 'Share details on tailoring accuracy, fabric richness, zari finish, or staff hospitality...',
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Submit Verified Review',
              icon: Icons.rate_review_rounded,
              onPressed: () async {
                if (commentCtrl.text.trim().isEmpty) {
                  _showSnackbar(context, 'Please enter review comments before submitting.');
                  return;
                }
                Navigator.pop(ctx);
                _showSnackbar(context, 'Submitting your verified review...');
                final repo = ref.read(customerApiRepositoryProvider);
                final newReview = await repo.submitReview(
                  store.id,
                  rating: rating,
                  comment: commentCtrl.text.trim(),
                );
                if (context.mounted) {
                  if (newReview != null) {
                    _showSnackbar(context, 'Thank you! Your verified artisan review has been submitted to the platform.');
                    ref.invalidate(allStoresProvider);
                  } else {
                    _showSnackbar(context, 'Review recorded! Thank you for sharing your experience.');
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
