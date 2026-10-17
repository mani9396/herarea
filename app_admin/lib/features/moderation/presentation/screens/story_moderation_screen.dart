import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import 'package:app_admin/core/state/admin_providers.dart';

class StoryModerationScreen extends ConsumerStatefulWidget {
  const StoryModerationScreen({super.key});

  @override
  ConsumerState<StoryModerationScreen> createState() => _StoryModerationScreenState();
}

class _StoryModerationScreenState extends ConsumerState<StoryModerationScreen> {
  String _selectedFilter = 'ALL'; // 'ALL', 'PRODUCT', 'GALLERY'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTimeRemaining(DateTime expiresAt) {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) {
      return 'Expired';
    }
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) {
      return 'Expires in ${hours}h ${minutes}m';
    } else {
      return 'Expires in ${minutes}m';
    }
  }

  void _confirmTakeDown(BuildContext context, StoryModel story) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Revoke & Take Down Story?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'This story by "${story.storeName}" will be removed immediately from customer discovery. This action is logged for audit compliance.',
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
              final success = await ref.read(adminStoriesProvider.notifier).takeDownStory(story.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Story revoked and taken down.' : 'Failed to take down story.'),
                    backgroundColor: success ? AppColors.success : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Take Down Story'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storiesAsync = ref.watch(adminStoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Stories Moderation & Governance 📸'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Queue',
            onPressed: () => ref.read(adminStoriesProvider.notifier).loadStories(),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              // Search & Filter Header
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText: 'Search by boutique name, city, or story title...',
                              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryRuby),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('ALL', 'All Live Stories'),
                          const SizedBox(width: AppSpacing.sm),
                          _buildFilterChip('PRODUCT', 'Option A: Store Products'),
                          const SizedBox(width: AppSpacing.sm),
                          _buildFilterChip('GALLERY', 'Option B: Gallery Uploads'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: storiesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryRuby)),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          Text('Failed to load stories: $err', style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref.read(adminStoriesProvider.notifier).loadStories(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (stories) {
                    final filtered = stories.where((s) {
                      if (_selectedFilter == 'PRODUCT' && !s.isProductLinked) return false;
                      if (_selectedFilter == 'GALLERY' && !s.isGalleryUploaded) return false;
                      if (_searchQuery.isNotEmpty) {
                        final q = _searchQuery.toLowerCase();
                        final matchesStore = s.storeName.toLowerCase().contains(q) ||
                            (s.storeCity?.toLowerCase().contains(q) ?? false) ||
                            (s.storeArea?.toLowerCase().contains(q) ?? false);
                        final matchesTitle = (s.title?.toLowerCase().contains(q) ?? false) ||
                            (s.caption?.toLowerCase().contains(q) ?? false);
                        return matchesStore || matchesTitle;
                      }
                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.amp_stories_outlined, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'No Live Stories Matching Filter',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Active vendor stories automatically expire in 24 hours.',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final story = filtered[index];
                        final isProduct = story.isProductLinked;
                        final title = story.title ??
                            (story.productSummary?['name']?.toString() ??
                                (isProduct ? 'Store Product Story' : 'Gallery Story'));

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail / Media Preview
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 100,
                                    height: 130,
                                    color: Colors.grey.shade100,
                                    child: story.effectiveMediaUrl.isNotEmpty
                                        ? Image.network(
                                            story.effectiveMediaUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Center(
                                              child: Icon(Icons.broken_image, color: Colors.grey),
                                            ),
                                          )
                                        : const Center(child: Icon(Icons.image, color: Colors.grey)),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.lg),

                                // Details & Store Meta
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Type Badge & Expiration
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                                                  isProduct ? Icons.shopping_bag_outlined : Icons.photo_library_outlined,
                                                  size: 13,
                                                  color: isProduct ? Colors.indigo.shade700 : AppColors.primaryRuby,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isProduct ? 'Option A: Store Product' : 'Option B: Gallery Upload',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: isProduct ? Colors.indigo.shade700 : AppColors.primaryRuby,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _formatTimeRemaining(story.expiresAt),
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Boutique Info
                                      Row(
                                        children: [
                                          const Icon(Icons.storefront_rounded, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            story.storeName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          if (story.storeCity != null) ...[
                                            const SizedBox(width: 6),
                                            Text(
                                              '• ${story.storeCity}',
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 6),

                                      // Story Title & Caption
                                      Text(
                                        title,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                      if (story.caption != null && story.caption!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          story.caption!,
                                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],

                                      // Price if provided
                                      if (story.price != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          '₹${(story.promotionalPrice ?? story.price)!.toStringAsFixed(0)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryRuby, fontSize: 14),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Moderation Action
                                Column(
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade50,
                                        foregroundColor: Colors.red.shade700,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          side: BorderSide(color: Colors.red.shade300),
                                        ),
                                      ),
                                      icon: const Icon(Icons.delete_forever_rounded, size: 18),
                                      label: const Text('Take Down'),
                                      onPressed: () => _confirmTakeDown(context, story),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = key),
      selectedColor: AppColors.primaryRuby.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryRuby : Colors.grey.shade800,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: AppColors.primaryRuby,
    );
  }
}
