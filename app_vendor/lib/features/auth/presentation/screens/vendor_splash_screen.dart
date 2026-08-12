import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:shared/shared.dart';

class VendorSplashScreen extends ConsumerStatefulWidget {
  const VendorSplashScreen({super.key});

  @override
  ConsumerState<VendorSplashScreen> createState() => _VendorSplashScreenState();
}

class _VendorSplashScreenState extends ConsumerState<VendorSplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authApiRepositoryProvider).restoreSession();
    });
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      if (ref.read(authSessionProvider).isAuthenticated) {
        context.go(VendorRoutePaths.dashboard);
      } else {
        context.go(VendorRoutePaths.welcome);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Opacity(
              opacity: _opacity.value,
              child: Transform.scale(scale: _scale.value, child: child),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accentGold, width: 2),
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  child: const Icon(Icons.storefront_rounded, size: 72, color: AppColors.accentGold),
                ),
                const SizedBox(height: AppSpacing.xl),
                const Text(
                  'HER AREA',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.accentGold, borderRadius: BorderRadius.circular(20)),
                  child: const Text('PARTNER PORTAL', style: TextStyle(fontSize: 12, color: AppColors.neutralCharcoal, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
