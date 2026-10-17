import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:her_area/core/routing/route_paths.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;
  final List<List<StoryModel>>? allGroups;
  final int initialGroupIndex;

  final void Function(StoryModel story)? onStoryViewed;
  final bool Function(String storyId)? isStoryViewed;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    this.allGroups,
    this.initialGroupIndex = 0,
    this.onStoryViewed,
    this.isStoryViewed,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> with SingleTickerProviderStateMixin {
  late List<List<StoryModel>> _groups;
  late int _currentGroupIndex;
  late int _currentIndex;
  late AnimationController _progressController;
  bool _isPaused = false;
  static const Duration _storyDuration = Duration(seconds: 6);

  List<StoryModel> get _currentStories {
    if (_groups.isNotEmpty && _currentGroupIndex < _groups.length) {
      return _groups[_currentGroupIndex];
    }
    return widget.stories;
  }

  @override
  void initState() {
    super.initState();
    if (widget.allGroups != null && widget.allGroups!.isNotEmpty) {
      _groups = widget.allGroups!;
      _currentGroupIndex = widget.initialGroupIndex.clamp(0, _groups.length - 1);
    } else {
      _groups = [widget.stories];
      _currentGroupIndex = 0;
    }
    _currentIndex = widget.initialIndex.clamp(
      0,
      _currentStories.isEmpty ? 0 : _currentStories.length - 1,
    );
    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _goToNextStory();
      }
    });

    _startCurrentStory();
  }

  void _startCurrentStory() {
    _progressController.stop();
    _progressController.reset();
    if (_currentStories.isNotEmpty && _currentIndex < _currentStories.length) {
      final story = _currentStories[_currentIndex];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onStoryViewed?.call(story);
        }
      });
    }
    if (!_isPaused) {
      _progressController.forward();
    }
  }

  void _goToNextStory() {
    if (_currentIndex < _currentStories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _startCurrentStory();
    } else if (_currentGroupIndex < _groups.length - 1) {
      setState(() {
        _currentGroupIndex++;
        final nextStories = _groups[_currentGroupIndex];
        final firstUnviewed = nextStories.indexWhere(
          (s) => widget.isStoryViewed != null && !widget.isStoryViewed!(s.id),
        );
        _currentIndex = firstUnviewed != -1 ? firstUnviewed : 0;
      });
      _startCurrentStory();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goToPreviousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _startCurrentStory();
    } else if (_currentGroupIndex > 0) {
      setState(() {
        _currentGroupIndex--;
        _currentIndex = _groups[_currentGroupIndex].isNotEmpty
            ? _groups[_currentGroupIndex].length - 1
            : 0;
      });
      _startCurrentStory();
    } else {
      _startCurrentStory();
    }
  }

  void _pauseStory() {
    setState(() => _isPaused = true);
    _progressController.stop();
  }

  void _resumeStory() {
    setState(() => _isPaused = false);
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes.clamp(1, 59)}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStories.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('No active stories', style: TextStyle(color: Colors.white))),
      );
    }

    final story = _currentStories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onLongPressStart: (_) => _pauseStory(),
          onLongPressEnd: (_) => _resumeStory(),
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! < -250) {
                // Swipe Left -> next vendor
                if (_currentGroupIndex < _groups.length - 1) {
                  setState(() {
                    _currentGroupIndex++;
                    final nextStories = _groups[_currentGroupIndex];
                    final firstUnviewed = nextStories.indexWhere(
                      (s) => widget.isStoryViewed != null && !widget.isStoryViewed!(s.id),
                    );
                    _currentIndex = firstUnviewed != -1 ? firstUnviewed : 0;
                  });
                  _startCurrentStory();
                } else {
                  Navigator.of(context).pop();
                }
              } else if (details.primaryVelocity! > 250) {
                // Swipe Right -> previous vendor
                if (_currentGroupIndex > 0) {
                  setState(() {
                    _currentGroupIndex--;
                    _currentIndex = 0;
                  });
                  _startCurrentStory();
                }
              }
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Story Media (Photo / Video presentation)
              Center(
                child: Image.network(
                  story.effectiveMediaUrl.isNotEmpty ? story.effectiveMediaUrl : story.mediaUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade900,
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
                    ),
                  ),
                ),
              ),

              // 2. Left / Right Navigation Tap Targets
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _goToPreviousStory,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _goToNextStory,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ],
              ),

              // 3. Top Gradient Overlay & Progress Bars + Header
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Segmented Progress Bars
                      Row(
                        children: List.generate(_currentStories.length, (idx) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.5),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: SizedBox(
                                  height: 3,
                                  child: idx < _currentIndex
                                      ? Container(color: Colors.white)
                                      : idx == _currentIndex
                                          ? AnimatedBuilder(
                                              animation: _progressController,
                                              builder: (context, child) {
                                                return LinearProgressIndicator(
                                                  value: _progressController.value,
                                                  backgroundColor: Colors.white24,
                                                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                                                );
                                              },
                                            )
                                          : Container(color: Colors.white24),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 12),

                      // Boutique Header
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.primaryRuby,
                            backgroundImage: story.storeLogo != null && story.storeLogo!.isNotEmpty
                                ? NetworkImage(story.storeLogo!)
                                : null,
                            child: story.storeLogo == null || story.storeLogo!.isEmpty
                                ? const Icon(Icons.storefront_rounded, color: Colors.white, size: 18)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        story.storeName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified_rounded, color: AppColors.accentGold, size: 14),
                                  ],
                                ),
                                Text(
                                  _formatTimeAgo(story.publishedAt),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Bottom Information & Action Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title (if provided or product-linked)
                      Builder(
                        builder: (context) {
                          final displayTitle = (story.title != null && story.title!.trim().isNotEmpty)
                              ? story.title!
                              : (story.productSummary?['name']?.toString() ?? '');
                          if (displayTitle.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              displayTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                              ),
                            ),
                          );
                        },
                      ),

                      // Caption (if provided)
                      if (story.caption != null && story.caption!.trim().isNotEmpty) ...[
                        Text(
                          story.caption!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            height: 1.4,
                            shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                      ],

                      // Price tags (if provided)
                      if (story.price != null || story.promotionalPrice != null) ...[
                        Row(
                          children: [
                            if (story.promotionalPrice != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryRuby,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  CurrencyFormatter.format(story.promotionalPrice!),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              if (story.price != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  CurrencyFormatter.format(story.price!),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ] else if (story.price != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.white30),
                                ),
                                child: Text(
                                  CurrencyFormatter.format(story.price!),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        const SizedBox(height: 8),
                      ],

                      // ── Explicit Story Action Button ──
                      _buildStoryActionButton(context, story),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryActionButton(BuildContext context, StoryModel story) {
    // ── Option A: Product Linked Story ──
    if (story.isProductLinked) {
      if (story.isProductAvailable && story.productId != null && story.productId!.isNotEmpty) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              _pauseStory();
              context.push(RoutePaths.buildProductDetailsPath(story.productId!)).then((_) {
                if (mounted) _resumeStory();
              });
            },
            icon: const Icon(Icons.shopping_bag_outlined, size: 18),
            label: const Text('See More About Product', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRuby,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );
      } else {
        // Linked product is deleted, unpublished, or unavailable
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: Colors.amber.shade300),
              const SizedBox(width: 8),
              Text(
                'Product Currently Unavailable',
                style: TextStyle(color: Colors.amber.shade200, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }
    }

    // ── Option B: Gallery Uploaded / External Story ──
    if (story.isGalleryUploaded) {
      if (story.hasAdditionalInfo) {
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              _pauseStory();
              _showGalleryStoryDetailsSheet(context, story).then((_) {
                if (mounted) _resumeStory();
              });
            },
            icon: const Icon(Icons.info_outline_rounded, size: 18),
            label: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white, width: 1.5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );
      } else {
        // If no additional information was provided, omit the button rather than showing a broken/meaningless action
        return const SizedBox.shrink();
      }
    }

    return const SizedBox.shrink();
  }

  Future<void> _showGalleryStoryDetailsSheet(BuildContext context, StoryModel story) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Studio Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primaryRuby,
                    child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.storeName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (story.storeCity != null && story.storeCity!.isNotEmpty)
                          Text(
                            story.storeCity!,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.blushPink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Showcase Story',
                      style: TextStyle(color: AppTheme.primaryRuby, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 12),

              // Title (Only if actually provided by vendor)
              if (story.title != null && story.title!.trim().isNotEmpty) ...[
                Text(
                  story.title!,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
              ],

              // Description / Caption (Only if actually provided by vendor)
              if (story.caption != null && story.caption!.trim().isNotEmpty) ...[
                Text(
                  story.caption!,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.5),
                ),
                const SizedBox(height: 12),
              ],

              // Price (Only if actually provided by vendor)
              if (story.price != null || story.promotionalPrice != null) ...[
                Row(
                  children: [
                    if (story.promotionalPrice != null) ...[
                      Text(
                        CurrencyFormatter.format(story.promotionalPrice!),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryRuby),
                      ),
                      if (story.price != null) ...[
                        const SizedBox(width: 10),
                        Text(
                          CurrencyFormatter.format(story.price!),
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough),
                        ),
                      ],
                    ] else if (story.price != null) ...[
                      Text(
                        CurrencyFormatter.format(story.price!),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryRuby),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Close Button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: 'Close Details',
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
