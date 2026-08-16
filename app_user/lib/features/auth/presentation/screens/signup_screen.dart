import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:her_area/core/routing/route_paths.dart';
import 'package:shared/shared.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _agreedToTerms = true;

  final List<String> _discoveryHubs = [
    'Jubilee Hills, Hyderabad',
    'Banjara Hills, Hyderabad',
    'Madhapur, Hitec City',
    'Inorbit Road, Cyberabad',
    'Begumpet & Somajiguda',
    'Gachibowli Financial District',
  ];

  void _onSignup() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please accept the Terms of Service to create your member account.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      
      final email = _emailController.text.trim();
      final fullName = _nameController.text.trim();
      final success = await ref.read(authApiRepositoryProvider).requestOtp(email, role: 'CUSTOMER', purpose: 'REGISTRATION', fullName: fullName);
      
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          ref.read(pendingRegistrationProvider.notifier).state = PendingRegistration(
            fullName: _nameController.text.trim(),
            email: email,
            locality: _cityController.text.trim(),
          );
          context.push(RoutePaths.otpVerification, extra: {'purpose': 'REGISTRATION'});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to send verification email. Please check the address and try again.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showLocalityPicker() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (bottomContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Discovery Locality',
                    style: theme.textTheme.headlineSmall?.copyWith(fontFamily: AppTypography.displayFont, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We use this as your default center when matching you with nearby boutiques.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _discoveryHubs.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final hub = _discoveryHubs[index];
                        final isSelected = _cityController.text == hub;

                        return ListTile(
                          leading: Icon(
                            Icons.location_on_rounded,
                            color: isSelected ? AppColors.primaryRuby : (isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight),
                          ),
                          title: Text(
                            hub,
                            style: TextStyle(
                              fontFamily: AppTypography.bodyFont,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isDark ? AppColors.textHighDark : AppColors.textHighLight,
                            ),
                          ),
                          trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryRuby) : null,
                          onTap: () {
                            setState(() => _cityController.text = hub);
                            Navigator.pop(bottomContext);
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
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          if (isWide) {
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _buildBrandShowcasePanel(isDark),
                ),
                Expanded(
                  flex: 6,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
                        child: _buildSignupForm(isDark),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
                  child: _buildSignupForm(isDark),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSignupForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.4), width: 1.2),
                ),
                child: const Icon(Icons.favorite_rounded, color: AppColors.primaryRuby, size: 30),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.primaryRuby),
                label: const Text(
                  'Sign In Instead',
                  style: TextStyle(fontFamily: AppTypography.bodyFont, fontWeight: FontWeight.w700, color: AppColors.primaryRuby),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Join Our Community',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontFamily: AppTypography.displayFont,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Create your verified account to unlock direct appointments, home measurement bookings, and private trial suites.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Full Name Input
          CustomTextField(
            label: 'Full Name',
            hintText: 'e.g. Priya Nambiar',
            controller: _nameController,
            prefixIcon: Icons.person_outline_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your full name';
              }
              return null;
            },
          ),

          // Email Input
          CustomTextField(
            label: 'Email Address',
            hintText: 'e.g. priya@gmail.com',
            helperText: 'A 6-digit verification code will be sent to confirm ownership.',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email address';
              }
              final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),

          // City Selection (Interactive picker with discovery centers)
          CustomTextField(
            label: 'Primary Discovery Locality',
            hintText: 'Select neighborhood',
            helperText: 'You can switch between neighborhoods anytime in Settings.',
            controller: _cityController,
            readOnly: true,
            prefixIcon: Icons.my_location_rounded,
            suffixWidget: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryRuby),
            onTap: _showLocalityPicker,
          ),

          // Terms of Service Checkbox
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _agreedToTerms,
                  activeColor: AppColors.primaryRuby,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 13,
                        color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
                        height: 1.4,
                      ),
                      children: const [
                        TextSpan(text: 'I agree to the '),
                        TextSpan(text: 'Terms of Service', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryRuby)),
                        TextSpan(text: ' & '),
                        TextSpan(text: 'Privacy Policy', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryRuby)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          CustomButton(
            label: 'Send Verification OTP Token',
            icon: Icons.auto_awesome,
            isLoading: _isLoading,
            onPressed: _onSignup,
          ),
          const SizedBox(height: AppSpacing.xxl),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already registered with HER AREA? ',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 14,
                  color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
                ),
              ),
              GestureDetector(
                onTap: () => context.pop(),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 14,
                    color: AppColors.primaryRuby,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildBrandShowcasePanel(bool isDark) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.accentGold, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.accentGoldLight, size: 16),
                const SizedBox(width: 8),
                Text(
                  'BESPOKE ARTISANAL COMMUNITY',
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentGoldLight,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'Empowering Women’s\nLocal Discovery.',
            style: TextStyle(
              fontFamily: AppTypography.displayFont,
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            "Join thousands of modern women discovering vetted tailoring masters, organic beauty spas, and heirloom jewelers without middleman commissions.",
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 16,
              color: AppColors.surfaceVariantLight.withValues(alpha: 0.9),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 48),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariantDark.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.35), width: 1),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 20, offset: Offset(0, 8)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 20),
                    const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 20),
                    const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 20),
                    const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 20),
                    const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'FEATURED MAGGAM MASTER',
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentGoldLight,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '"Master artisans delivered my customized Maggam embroidery exactly on schedule. The finishing is breathtaking!"',
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.accentGoldDark,
                      child: const Text(
                        'S',
                        style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Srinidhi Shetty',
                          style: TextStyle(
                            fontFamily: AppTypography.bodyFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Client at Tejasi Maggam & Zardosi Studio',
                          style: TextStyle(
                            fontFamily: AppTypography.bodyFont,
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
