import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:her_area/core/routing/route_paths.dart';
import 'package:her_area/data/repositories/customer_api_repository.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _sequenceController;
  late AnimationController _pulseController;

  late Animation<double> _emblemScale;
  late Animation<double> _emblemOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleOpacity;
  late Animation<double> _lineExpansion;
  late Animation<double> _taglineOpacity;
  late Animation<double> _statusOpacity;
  late Animation<double> _progressValue;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Warm up discovery engine and restore persisted session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(allStoresProvider);
      ref.read(authApiRepositoryProvider).restoreSession();
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _sequenceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    _emblemScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _sequenceController, curve: const Interval(0.0, 0.3, curve: Curves.easeOutBack)),
    );
    _emblemOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sequenceController, curve: const Interval(0.0, 0.25, curve: Curves.easeIn)),
    );

    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _sequenceController, curve: const Interval(0.15, 0.45, curve: Curves.easeOutCubic)),
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sequenceController, curve: const Interval(0.15, 0.4, curve: Curves.easeIn)),
    );

    _lineExpansion = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sequenceController, curve: const Interval(0.3, 0.55, curve: Curves.easeInOut)),
    );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sequenceController, curve: const Interval(0.4, 0.65, curve: Curves.easeIn)),
    );

    _statusOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sequenceController, curve: const Interval(0.35, 0.6, curve: Curves.easeIn)),
    );

    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sequenceController, curve: const Interval(0.1, 0.95, curve: Curves.easeInOutCubic)),
    );

    _sequenceController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 300), _navigateToLogin);
    });
  }

  void _navigateToLogin() {
    if (mounted && !_navigated) {
      _navigated = true;
      if (ref.read(authSessionProvider).isAuthenticated) {
        context.go(RoutePaths.home);
      } else {
        context.go(RoutePaths.login);
      }
    }
  }

  String _getDynamicStatusMessage(double progress) {
    if (progress < 0.25) {
      return 'Initializing Live O2O Discovery Engine...';
    } else if (progress < 0.55) {
      return 'Curating 50+ Verified Boutiques & Bridal Studios...';
    } else if (progress < 0.85) {
      return 'Connecting Maggam & Saree Specialists in Hyderabad...';
    } else {
      return 'Ready for Luxury Local Discovery';
    }
  }

  @override
  void dispose() {
    _sequenceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Luxury Brand Background (Ruby to Obsidian Deep Gradient)
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),

          // 2. Ambient Decorative Glow Orbs
          Positioned(
            top: -size.width * 0.3,
            right: -size.width * 0.3,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentGold.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -size.width * 0.4,
            left: -size.width * 0.4,
            child: Container(
              width: size.width * 0.9,
              height: size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryRubyLight.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 3. Central Local Discovery Radar / Pulsing Ripple Rings
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: List.generate(3, (index) {
                    final delayedValue = (_pulseController.value + (index * 0.33)) % 1.0;
                    final ringSize = 140.0 + (delayedValue * 180.0);
                    final ringOpacity = (1.0 - delayedValue) * 0.25;

                    return Container(
                      width: ringSize,
                      height: ringSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accentGold.withValues(alpha: ringOpacity),
                          width: 1.5,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),

          // 4. Staged Main Content
          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _sequenceController,
                builder: (context, child) {
                  final currentStatus = _getDynamicStatusMessage(_progressValue.value);
                  final percent = (_progressValue.value * 100).clamp(0, 100).toInt();

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),

                        // Animated Luxury Emblem
                        Opacity(
                          opacity: _emblemOpacity.value,
                          child: Transform.scale(
                            scale: _emblemScale.value,
                            child: _buildLuxuryEmblem(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title Reveal
                        SlideTransition(
                          position: _titleSlide,
                          child: Opacity(
                            opacity: _titleOpacity.value,
                            child: Column(
                              children: [
                                const Text(
                                  AppConstants.appName,
                                  style: TextStyle(
                                    fontFamily: AppTypography.displayFont,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 6.0,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Expanding Gold Accent Divider
                                Container(
                                  width: 80 * _lineExpansion.value,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.goldGradient,
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accentGold.withValues(alpha: 0.5),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Tagline Reveal
                        Opacity(
                          opacity: _taglineOpacity.value,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32.0),
                            child: Text(
                              AppConstants.appTagline,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTypography.bodyFont,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.surfaceVariantLight,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // 5. Dynamic Discovery Engine Initialization Status
                        Opacity(
                          opacity: _statusOpacity.value,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariantDark.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.accentGold.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 16,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        AnimatedBuilder(
                                          animation: _pulseController,
                                          builder: (context, child) {
                                            return Transform.rotate(
                                              angle: _pulseController.value * 2 * math.pi,
                                              child: const Icon(
                                                Icons.auto_awesome,
                                                size: 16,
                                                color: AppColors.accentGold,
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'LIVE DISCOVERY ENGINE',
                                            style: TextStyle(
                                              fontFamily: AppTypography.bodyFont,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.accentGoldLight,
                                              letterSpacing: 1.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryRubyDark,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: AppColors.accentGold.withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: Text(
                                            'PRODUCTION MODE',
                                            style: TextStyle(
                                              fontFamily: AppTypography.bodyFont,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.surfaceVariantLight,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      child: Text(
                                        currentStatus,
                                        key: ValueKey<String>(currentStatus),
                                        style: const TextStyle(
                                          fontFamily: AppTypography.bodyFont,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: _progressValue.value,
                                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGold),
                                        minHeight: 5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '$percent% Complete',
                                          style: TextStyle(
                                            fontFamily: AppTypography.bodyFont,
                                            fontSize: 11,
                                            color: Colors.white.withValues(alpha: 0.6),
                                          ),
                                        ),
                                        Text(
                                          AppConstants.appVersion,
                                          style: TextStyle(
                                            fontFamily: AppTypography.bodyFont,
                                            fontSize: 11,
                                            color: Colors.white.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLuxuryEmblem() {
    return Container(
      width: 124,
      height: 124,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withValues(alpha: 0.35),
            blurRadius: 32,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shimmering Gold Border Ring
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.goldGradient,
              shape: BoxShape.circle,
            ),
          ),
          // Inner Deep Ruby Medallion
          Container(
            width: 116,
            height: 116,
            decoration: const BoxDecoration(
              color: AppColors.primaryRubyDark,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Inner Subtle Gold Accent Circle
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accentGold.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                // Crown / Diamond Iconography
                const Icon(
                  Icons.diamond_rounded,
                  size: 56,
                  color: AppColors.surfaceLight,
                ),
                Positioned(
                  top: 26,
                  right: 28,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: 0.5 + (_pulseController.value * 0.5),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: AppColors.accentGoldLight,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
