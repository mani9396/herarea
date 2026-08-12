import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:her_area/core/routing/route_paths.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_typography.dart';
import 'package:shared/widgets/custom_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:her_area/data/repositories/customer_api_repository.dart';

class InterestSelectionScreen extends ConsumerStatefulWidget {
  const InterestSelectionScreen({super.key});

  @override
  ConsumerState<InterestSelectionScreen> createState() => _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends ConsumerState<InterestSelectionScreen> {
  final Set<String> _selected = {
    'Sarees & Handlooms',
    'Maggam & Zardosi Work',
    'Designer Boutiques',
  };

  void _toggle(String item) {
    setState(() {
      if (_selected.contains(item)) {
        if (_selected.length > 1) {
          _selected.remove(item);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please maintain at least one preference for your custom discovery feed.'),
              backgroundColor: AppColors.primaryRuby,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(milliseconds: 1800),
            ),
          );
        }
      } else {
        _selected.add(item);
      }
    });
  }

  IconData _getIconForInterest(String interest) {
    switch (interest) {
      case 'Sarees & Handlooms':
        return Icons.style_rounded;
      case 'Maggam & Zardosi Work':
        return Icons.brush_rounded;
      case 'Bridal Makeup Studios':
        return Icons.auto_awesome_rounded;
      case 'Designer Boutiques':
        return Icons.diamond_rounded;
      case 'Custom Tailoring':
        return Icons.content_cut_rounded;
      case 'Antique Jewellery':
        return Icons.workspace_premium_rounded;
      case 'Organic Beauty Spas':
        return Icons.spa_rounded;
      default:
        return Icons.favorite_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isWide = MediaQuery.sizeOf(context).width >= 750;
    final categoriesAsync = ref.watch(categoriesProvider);
    final storesAsync = ref.watch(allStoresProvider);
    final storeCount = storesAsync.valueOrNull?.length ?? 6;
    final defaultCategories = const [
      'Sarees & Handlooms',
      'Maggam & Zardosi Work',
      'Designer Boutiques',
      'Bridal Jewelry',
      'Custom Tailoring',
      'Luxury Pret & Western',
      'Lehengas & Anarkalis',
      'Footwear & Accessories',
    ];
    final categoriesList = categoriesAsync.valueOrNull ?? defaultCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalize Discovery', style: TextStyle(fontFamily: AppTypography.displayFont, fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'Back to Location Setup',
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selected.clear();
                _selected.addAll(categoriesList);
              });
            },
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: const Text(
              'Select All',
              style: TextStyle(
                fontFamily: AppTypography.bodyFont,
                color: AppColors.primaryRuby,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                    child: Container(
                      padding: EdgeInsets.all(isWide ? 36 : 0),
                      decoration: isWide
                          ? BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            )
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What are your curated style preferences?',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontFamily: AppTypography.displayFont,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Select your preferred fashion, bridal, and craftsmanship specialties. Your local O2O discovery dashboard will instantly prioritize top-rated master artisans matching these selections.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Live Customization Banner
                          Semantics(
                            label: 'Curating $storeCount neighborhood boutiques across ${_selected.length} active style categories.',
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              decoration: BoxDecoration(
                                gradient: isDark ? AppColors.primaryGradient : null,
                                color: isDark ? null : AppColors.surfaceVariantLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.accentGold.withValues(alpha: 0.6),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentGold.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.auto_awesome, color: AppColors.accentGold, size: 24),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Text(
                                      'Curating $storeCount neighborhood boutiques across ${_selected.length} active style categories.',
                                      style: TextStyle(
                                        fontFamily: AppTypography.bodyFont,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.textHighDark : AppColors.primaryRuby,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),

                          // Interest Tiles Grid / Wrap
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              final isTwoCol = width >= 480;

                              if (isTwoCol) {
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 2.8,
                                  ),
                                  itemCount: categoriesList.length,
                                  itemBuilder: (context, index) {
                                    final interest = categoriesList[index];
                                    return _buildInterestCard(interest, isDark);
                                  },
                                );
                              }

                              return Wrap(
                                spacing: 12,
                                runSpacing: 14,
                                children: categoriesList.map((interest) {
                                  return _buildInterestChip(interest, isDark);
                                }).toList(),
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  ),
                ),

                // Sticky Accessible Bottom Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomButton(
                        label: 'Explore HER AREA (${_selected.length})',
                        icon: Icons.explore_rounded,
                        onPressed: () => context.go(RoutePaths.home),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInterestChip(String interest, bool isDark) {
    final isSelected = _selected.contains(interest);
    final icon = _getIconForInterest(interest);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$interest style category, ${isSelected ? 'selected' : 'unselected'}',
      child: GestureDetector(
        onTap: () => _toggle(interest),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryRuby : (isDark ? AppColors.surfaceVariantDark : Colors.white),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? AppColors.accentGold : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryRuby.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.accentGoldLight : AppColors.primaryRuby,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                interest,
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  color: isSelected ? Colors.white : (isDark ? AppColors.textHighDark : AppColors.textHighLight),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                color: isSelected ? AppColors.accentGoldLight : (isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInterestCard(String interest, bool isDark) {
    final isSelected = _selected.contains(interest);
    final icon = _getIconForInterest(interest);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$interest category card, ${isSelected ? 'selected' : 'unselected'}',
      child: GestureDetector(
        onTap: () => _toggle(interest),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryRuby : (isDark ? AppColors.surfaceVariantDark : Colors.white),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppColors.accentGold : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryRuby.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.15) : AppColors.primaryRuby.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.accentGoldLight : AppColors.primaryRuby,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  interest,
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    color: isSelected ? Colors.white : (isDark ? AppColors.textHighDark : AppColors.textHighLight),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? AppColors.accentGoldLight : (isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
