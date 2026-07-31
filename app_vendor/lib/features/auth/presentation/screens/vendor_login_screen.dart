import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_vendor/core/routing/vendor_route_paths.dart';
import 'package:shared/shared.dart';

class VendorLoginScreen extends StatefulWidget {
  const VendorLoginScreen({super.key});

  @override
  State<VendorLoginScreen> createState() => _VendorLoginScreenState();
}

class _VendorLoginScreenState extends State<VendorLoginScreen> {
  final _phoneController = TextEditingController(text: '9811122334');
  final _pinController = TextEditingController(text: '1234');
  bool _isLoading = false;
  String? _errorMessage;

  void _onLogin() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      context.go(VendorRoutePaths.dashboard);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ResponsiveLayout(
        mobile: _buildContent(context),
        tablet: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: CustomCard(padding: const EdgeInsets.all(AppSpacing.xxl), child: _buildContent(context)),
          ),
        ),
        desktop: Row(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                padding: const EdgeInsets.all(AppSpacing.xxxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.storefront_rounded, color: AppColors.accentGold, size: 64),
                    const SizedBox(height: AppSpacing.xl),
                    const Text(
                      'Grow Your Bridal Boutique & Artisan Business 🌟',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Connect directly with brides across Hyderabad for home measurement trials, custom Maggam works, and premium designer saree drapery.',
                      style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _buildTrustChip('Verified Gold Leads'),
                        _buildTrustChip('Zero Commission O2O'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Padding(padding: const EdgeInsets.all(AppSpacing.xl), child: _buildContent(context)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.accentGold, size: 16),
          const SizedBox(width: 8),
          Flexible(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: CircleAvatar(radius: 28, backgroundColor: AppColors.primaryRuby, child: Icon(Icons.storefront_rounded, color: Colors.white, size: 30)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Partner Portal Login', style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.xs),
          Text('Enter your business mobile number to access your O2O dashboard.', style: textTheme.bodyMedium?.copyWith(color: AppColors.neutralCharcoal.withValues(alpha: 0.6))),
          const SizedBox(height: AppSpacing.xl),
          if (_errorMessage != null) ...[
            ErrorView(title: 'Authentication Error', message: _errorMessage!, onRetry: null),
            const SizedBox(height: AppSpacing.md),
          ],
          CustomTextField(
            label: 'Business Mobile Number',
            hintText: 'Enter 10 digit mobile number',
            controller: _phoneController,
            prefixWidget: const Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14), child: Text('+91', style: TextStyle(fontWeight: FontWeight.bold))),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSpacing.md),
          CustomTextField(
            label: 'Security PIN / Password',
            hintText: 'Enter 4-digit partner PIN',
            controller: _pinController,
            isPassword: true,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push(VendorRoutePaths.forgotPassword),
              child: const Text('Forgot PIN?', style: TextStyle(color: AppColors.primaryRuby, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomButton(
            label: 'Enter Partner Dashboard 🚀',
            isLoading: _isLoading,
            onPressed: _onLogin,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              Text("New artisan or boutique? ", style: textTheme.bodyMedium),
              InkWell(
                onTap: () => context.push(VendorRoutePaths.signup),
                child: Text("Register Business", style: textTheme.bodyMedium?.copyWith(color: AppColors.primaryRuby, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Divider(color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: InkWell(
              onTap: () {
                CustomDialog.show(
                  context: context,
                  title: 'Switch to Customer App',
                  description: 'In a production deployment, app_user and app_vendor run as separate standalone applications on iOS/Android, and under separate web hostnames.',
                  confirmText: 'Got It',
                  onConfirm: () {},
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.accentGold),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(Icons.swap_horiz_rounded, color: AppColors.accentGold, size: 18),
                    const SizedBox(width: 8),
                    Text('Customer Mode Preview 👑', style: textTheme.labelMedium?.copyWith(color: AppColors.accentGoldDark, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
