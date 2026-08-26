import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class SystemStatesShowcaseScreen extends StatefulWidget {
  const SystemStatesShowcaseScreen({super.key});

  @override
  State<SystemStatesShowcaseScreen> createState() => _SystemStatesShowcaseScreenState();
}

class _SystemStatesShowcaseScreenState extends State<SystemStatesShowcaseScreen> {
  int _selectedTab = 0; // 0: Empty States, 1: Loading States, 2: Error States
  int _selectedEmptyIndex = 0; // 0: Products, 1: Gallery, 2: Enquiries, 3: Reviews, 4: Notifications

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('System States & UI Diagnostics 🛡️'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.lg),
            color: Theme.of(context).cardColor,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(value: 0, label: Text('Empty States'), icon: Icon(Icons.inbox_rounded)),
                ButtonSegment<int>(value: 1, label: Text('Loading / Skeletons'), icon: Icon(Icons.hourglass_empty_rounded)),
                ButtonSegment<int>(value: 2, label: Text('Error / Retry UI'), icon: Icon(Icons.error_outline_rounded)),
              ],
              selected: {_selectedTab},
              onSelectionChanged: (val) => setState(() => _selectedTab = val.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primaryRuby.withValues(alpha: 0.15);
                  }
                  return Colors.transparent;
                }),
                foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primaryRuby;
                  }
                  return Colors.grey;
                }),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _selectedTab == 0
                      ? _buildEmptyStatesTab(textTheme)
                      : _selectedTab == 1
                          ? _buildLoadingStatesTab(textTheme)
                          : _buildErrorStatesTab(textTheme),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStatesTab(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Select Empty State Scenario:', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('No Products (0)', 0),
              const SizedBox(width: 8),
              _buildFilterChip('No Gallery (1)', 1),
              const SizedBox(width: 8),
              _buildFilterChip('No Enquiries (2)', 2),
              const SizedBox(width: 8),
              _buildFilterChip('No Reviews (3)', 3),
              const SizedBox(width: 8),
              _buildFilterChip('No Notifications (4)', 4),
            ],
          ),
        ),
        const Divider(height: 32),
        Expanded(
          child: CustomCard(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Center(
              child: _selectedEmptyIndex == 0
                  ? EmptyStateWidget(
                      icon: Icons.inventory_2_outlined,
                      title: 'No Bridal Products in Catalog',
                      description: 'Your inventory is currently bare. Add Maggam blouses, silk sarees, or embroidery bundles to begin receiving fitting inquiries.',
                      actionLabel: 'Add Product to Catalog',
                      onActionPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Triggered Add Product Action!'))),
                    )
                  : _selectedEmptyIndex == 1
                      ? EmptyStateWidget(
                          icon: Icons.photo_library_outlined,
                          title: 'No Showcase Imagery Uploaded',
                          description: 'High-resolution craft photos increase bridal conversion by 3.4x. Upload your first studio showcase lookbook now.',
                          actionLabel: 'Upload Studio Photos',
                          onActionPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Triggered Gallery Upload Action!'))),
                        )
                  : _selectedEmptyIndex == 2
                          ? EmptyStateWidget(
                              icon: Icons.calendar_today_outlined,
                              title: 'No Consultation Enquiries Yet',
                              description: 'When brides around Jubilee Hills request Measurement Trials or book appointments, they will appear right here in real-time.',
                              actionLabel: 'Share Studio Link on WhatsApp',
                              onActionPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Triggered Share Store action!'))),
                            )
                          : _selectedEmptyIndex == 3
                              ? EmptyStateWidget(
                                  icon: Icons.star_outline_rounded,
                                  title: 'No Customer Testimonials',
                                  description: 'Once you mark consultation bookings as completed, verified brides will be prompted to leave 5-star reviews and badges.',
                                )
                              : EmptyStateWidget(
                                  icon: Icons.notifications_off_outlined,
                                  title: 'All Caught Up!',
                                  description: 'There are no pending lead alerts, KYC advisories, or system notices in your queue.',
                                ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final selected = _selectedEmptyIndex == index;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.neutralCharcoal, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      selected: selected,
      selectedColor: AppColors.primaryRuby,
      onSelected: (val) {
        if (val) setState(() => _selectedEmptyIndex = index);
      },
    );
  }

  Widget _buildLoadingStatesTab(TextTheme textTheme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('1. Shimmer Skeleton Card Loaders (Catalog & Orders)', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryRuby)),
          const SizedBox(height: AppSpacing.sm),
          const Text('Simulates content loading smoothly from Django REST Framework endpoints during network requests without layout jank.', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: AppSpacing.lg),
          _buildSkeletonCard(context),
          const SizedBox(height: AppSpacing.md),
          _buildSkeletonCard(context),
          const SizedBox(height: AppSpacing.xxl),
          Text('2. Standard Progress Indicators', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryRuby)),
          const SizedBox(height: AppSpacing.md),
          CustomCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                const LoadingIndicator(message: 'Syncing O2O inventory with cloud server...'),
                const SizedBox(height: AppSpacing.xl),
                LinearProgressIndicator(backgroundColor: AppColors.primaryRuby.withValues(alpha: 0.1), color: AppColors.accentGold),
                const SizedBox(height: 8),
                const Text('Uploading high-res silk cover imagery: 74%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 240, height: 18, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 10),
                Container(width: 160, height: 14, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 10),
                Container(width: 100, height: 12, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorStatesTab(TextTheme textTheme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('1. No Internet Cellular/Wi-Fi Connection Error State', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.errorRed)),
          const SizedBox(height: AppSpacing.sm),
          CustomCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ErrorView(
              message: 'No active Internet connection detected. Your O2O partner studio data cannot synchronize with the bridal lead server.',
              onRetry: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checking network status... Internet restored successfully!')));
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text('2. API Endpoint / Server Exception Retry Screen', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.errorRed)),
          const SizedBox(height: AppSpacing.sm),
          CustomCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ErrorView(
              message: 'HTTP 503 Service Unavailable: Django database cluster experienced temporary timeout during query calculation.',
              onRetry: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Retrying request... Backend connected successfully!')));
              },
            ),
          ),
        ],
      ),
    );
  }
}
