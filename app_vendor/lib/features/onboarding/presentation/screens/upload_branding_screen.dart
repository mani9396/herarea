import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:shared/shared.dart';

class UploadBrandingScreen extends StatefulWidget {
  const UploadBrandingScreen({super.key});

  @override
  State<UploadBrandingScreen> createState() => _UploadBrandingScreenState();
}

class _UploadBrandingScreenState extends State<UploadBrandingScreen> {
  String _logoUrl = 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?q=80&w=300&auto=format&fit=crop';
  String _coverUrl = 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?q=80&w=1200&auto=format&fit=crop';
  bool _isLoading = false;

  void _onUploadLogo() {
    setState(() {
      _logoUrl = 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?q=80&w=300&auto=format&fit=crop';
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Studio logo updated cleanly!')));
  }

  void _onUploadCover() {
    setState(() {
      _coverUrl = 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?q=80&w=1200&auto=format&fit=crop';
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Widescreen cover banner updated!')));
  }

  void _onContinue() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      context.push(VendorRoutePaths.storeTiming);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Step 2: Studio Branding'), centerTitle: true, elevation: 0),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Upload Store Logo & Cover Banner', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryRuby)),
                const SizedBox(height: AppSpacing.xs),
                Text('These images define your boutique presentation across bridal category listings and search results in Jubilee Hills & Banjara Hills.', style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600], height: 1.4)),
                const SizedBox(height: AppSpacing.xl),
                Text('Widescreen Cover Banner (16:9)', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.sm),
                GestureDetector(
                  onTap: _onUploadCover,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryRuby.withValues(alpha: 0.4), width: 2),
                      image: DecorationImage(image: NetworkImage(_coverUrl), fit: BoxFit.cover),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded, color: Colors.white, size: 40),
                            SizedBox(height: 8),
                            Text('Tap to Replace Cover Image', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('Recommended: 1920 x 1080px resolution', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text('Boutique Profile Logo / Emblem (1:1)', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accentGold, width: 3),
                        image: DecorationImage(image: NetworkImage(_logoUrl), fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Circular Brand Logo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          const Text('Displayed inside circular badges next to customer reviews & quotes.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: AppSpacing.sm),
                          OutlinedButton.icon(
                            onPressed: _onUploadLogo,
                            icon: const Icon(Icons.upload_rounded, size: 18, color: AppColors.primaryRuby),
                            label: const Text('Change Logo', style: TextStyle(color: AppColors.primaryRuby)),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primaryRuby)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
                CustomCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: AppColors.accentGold, size: 26),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Pro Tip: Studios featuring high-resolution Maggam silk imagery receive 3.4x higher WhatsApp fitting inquiries.',
                          style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                CustomButton(
                  label: 'Save Branding & Continue ➡️',
                  isLoading: _isLoading,
                  onPressed: _onContinue,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => context.push(VendorRoutePaths.storeTiming),
                  child: const Text('Skip for now (Use defaults)', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
