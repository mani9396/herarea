import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:app_vendor/features/stories/state/vendor_stories_provider.dart';

class StoriesManagementScreen extends ConsumerStatefulWidget {
  const StoriesManagementScreen({super.key});

  @override
  ConsumerState<StoriesManagementScreen> createState() => _StoriesManagementScreenState();
}

class _StoriesManagementScreenState extends ConsumerState<StoriesManagementScreen> {
  String _selectedFilter = 'ALL'; // 'ALL', 'PRODUCT', 'GALLERY'

  String _formatTimeRemaining(DateTime expiresAt) {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) {
      return 'Expiring now';
    }
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) {
      return 'Expires in ${hours}h ${minutes}m';
    } else {
      return 'Expires in ${minutes}m';
    }
  }

  void _confirmDelete(BuildContext context, StoryModel story) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Story?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'This story will be removed immediately from customer view. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final success = await ref.read(vendorStoriesProvider.notifier).deleteStory(story.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Story removed successfully.' : 'Failed to delete story.'),
                    backgroundColor: success ? AppColors.success : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storiesAsync = ref.watch(vendorStoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stories Management 📸'),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.read(vendorStoriesProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryRuby, size: 28),
            tooltip: 'Add Story',
            onPressed: () => context.push(VendorRoutePaths.addStory),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryRuby,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_photo_alternate_rounded),
        label: const Text('Add Story'),
        onPressed: () => context.push(VendorRoutePaths.addStory),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: storiesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRuby),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load stories: $err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.read(vendorStoriesProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (stories) {
              final activeCount = stories.length;
              final productCount = stories.where((s) => s.isProductLinked).length;
              final galleryCount = stories.where((s) => s.isGalleryUploaded).length;
              final isAtCap = activeCount >= kMaxActiveStoriesPerVendor;

              final filteredStories = stories.where((s) {
                if (_selectedFilter == 'PRODUCT') return s.isProductLinked;
                if (_selectedFilter == 'GALLERY') return s.isGalleryUploaded;
                return true;
              }).toList();

              return RefreshIndicator(
                color: AppColors.primaryRuby,
                onRefresh: () => ref.read(vendorStoriesProvider.notifier).refresh(),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // Cap & Quota Monitor Card
                    CustomCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.timer_outlined, size: 20, color: AppColors.primaryRuby),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Active 24h Stories',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isAtCap
                                      ? Colors.red.withValues(alpha: 0.1)
                                      : AppColors.primaryRuby.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$activeCount / $kMaxActiveStoriesPerVendor Active',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isAtCap ? Colors.red.shade700 : AppColors.primaryRuby,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (activeCount / kMaxActiveStoriesPerVendor).clamp(0.0, 1.0),
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isAtCap ? Colors.red : AppColors.primaryRuby,
                              ),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Stories expire automatically after 24 hours. Expired stories do not count toward your 25-story limit.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Quick Option Toggle Buttons (Option A vs Option B)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create Story — Choose Type:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => context.push('${VendorRoutePaths.addStory}?tab=product'),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.indigo.withValues(alpha: 0.25)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.storefront_rounded, size: 18, color: Colors.indigo.shade700),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'Option A: My Products',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Colors.indigo.shade700,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: () => context.push('${VendorRoutePaths.addStory}?tab=gallery'),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryRuby.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.primaryRuby.withValues(alpha: 0.25)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.add_photo_alternate_rounded, size: 18, color: AppColors.primaryRuby),
                                        SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'Option B: Gallery Upload',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: AppColors.primaryRuby,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    if (stories.isEmpty)
                      EmptyStateWidget(
                        icon: Icons.amp_stories_outlined,
                        title: 'No Active Stories',
                        description:
                            'Showcase your finest store products or upload custom gallery highlights. Stories stay live for 24 hours.',
                        actionLabel: 'Publish First Story',
                        onActionPressed: () => context.push(VendorRoutePaths.addStory),
                      )
                    else ...[
                      // Story Filter Toggle Chips
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Live Stories ($activeCount)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: Text('All ($activeCount)'),
                              selected: _selectedFilter == 'ALL',
                              selectedColor: AppColors.primaryRuby.withValues(alpha: 0.15),
                              labelStyle: TextStyle(
                                fontWeight: _selectedFilter == 'ALL' ? FontWeight.bold : FontWeight.normal,
                                color: _selectedFilter == 'ALL' ? AppColors.primaryRuby : Colors.grey.shade700,
                              ),
                              onSelected: (_) => setState(() => _selectedFilter = 'ALL'),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: Text('Option A: Products ($productCount)'),
                              selected: _selectedFilter == 'PRODUCT',
                              selectedColor: Colors.indigo.withValues(alpha: 0.15),
                              labelStyle: TextStyle(
                                fontWeight: _selectedFilter == 'PRODUCT' ? FontWeight.bold : FontWeight.normal,
                                color: _selectedFilter == 'PRODUCT' ? Colors.indigo.shade700 : Colors.grey.shade700,
                              ),
                              onSelected: (_) => setState(() => _selectedFilter = 'PRODUCT'),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: Text('Option B: Gallery ($galleryCount)'),
                              selected: _selectedFilter == 'GALLERY',
                              selectedColor: AppColors.primaryRuby.withValues(alpha: 0.15),
                              labelStyle: TextStyle(
                                fontWeight: _selectedFilter == 'GALLERY' ? FontWeight.bold : FontWeight.normal,
                                color: _selectedFilter == 'GALLERY' ? AppColors.primaryRuby : Colors.grey.shade700,
                              ),
                              onSelected: (_) => setState(() => _selectedFilter = 'GALLERY'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (filteredStories.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Center(
                            child: Text(
                              'No ${_selectedFilter == 'PRODUCT' ? 'Store Product' : 'Gallery'} stories currently active.',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredStories.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final story = filteredStories[index];
                            final isProduct = story.isProductLinked;
                            final title = story.title ??
                                (story.productSummary?['name']?.toString() ??
                                    (isProduct ? 'Store Product Story' : 'Gallery Story'));

                            return CustomCard(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Thumbnail
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 76,
                                      height: 100,
                                      color: Colors.grey.shade100,
                                      child: story.effectiveMediaUrl.isNotEmpty
                                          ? Image.network(
                                              story.effectiveMediaUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Center(
                                                child: Icon(Icons.broken_image, color: Colors.grey),
                                              ),
                                            )
                                          : const Center(
                                              child: Icon(Icons.image, color: Colors.grey),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),

                                  // Story Meta
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Type Badge & Timer
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isProduct
                                                    ? Colors.indigo.withValues(alpha: 0.1)
                                                    : AppColors.primaryRuby.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isProduct
                                                        ? Icons.shopping_bag_outlined
                                                        : Icons.photo_library_outlined,
                                                    size: 12,
                                                    color: isProduct
                                                        ? Colors.indigo.shade700
                                                        : AppColors.primaryRuby,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    isProduct ? 'Store Product' : 'Gallery Upload',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: isProduct
                                                          ? Colors.indigo.shade700
                                                          : AppColors.primaryRuby,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              _formatTimeRemaining(story.expiresAt),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.orange.shade800,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),

                                        // Title
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),

                                        // Price info
                                        if (story.price != null ||
                                            story.productSummary?['price'] != null) ...[
                                          Builder(builder: (context) {
                                            final priceVal = story.price ??
                                                double.tryParse(
                                                    story.productSummary?['price']?.toString() ??
                                                        '');
                                            if (priceVal == null) return const SizedBox.shrink();
                                            return Text(
                                              '₹${priceVal.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                color: AppColors.primaryRuby,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            );
                                          }),
                                        ],

                                        // Caption
                                        if (story.caption != null && story.caption!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            story.caption!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Delete Action
                                  IconButton(
                                    icon: Icon(Icons.delete_outline_rounded,
                                        color: Colors.grey.shade400, size: 20),
                                    tooltip: 'Delete Story',
                                    onPressed: () => _confirmDelete(context, story),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
