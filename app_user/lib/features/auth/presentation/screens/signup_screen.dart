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
  final _dobController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _agreedToTerms = false;
  bool _agreedToPrivacyPolicy = false;
  
  String? _selectedGender;
  DateTime? _selectedDate;

  void _onSignup() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please accept the Terms & Conditions to create your member account.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (!_agreedToPrivacyPolicy) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please accept the Privacy Policy to create your member account.'),
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
      final dobStr = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
      final gender = _selectedGender == 'Female' ? 'FEMALE' : _selectedGender == 'Male' ? 'MALE' : 'PREFER_NOT_TO_SAY';
      
      final success = await ref.read(authApiRepositoryProvider).requestOtp(email, role: 'CUSTOMER', purpose: 'REGISTRATION', fullName: fullName);
      
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          ref.read(pendingRegistrationProvider.notifier).state = PendingRegistration(
            fullName: fullName,
            email: email,
            dateOfBirth: dobStr,
            gender: gender,
          );
          context.push(RoutePaths.otpVerification, extra: {'purpose': 'REGISTRATION'});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send verification email. Please check the address and try again.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 18 * 365)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: AppColors.primaryRuby,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
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

          // Date of Birth
          CustomTextField(
            label: 'Date of Birth',
            hintText: 'Select your date of birth',
            controller: _dobController,
            readOnly: true,
            prefixIcon: Icons.calendar_today_rounded,
            onTap: _selectDateOfBirth,
            validator: (value) {
              if (value == null || value.trim().isEmpty || _selectedDate == null) {
                return 'Please select your date of birth';
              }
              if (_selectedDate!.isAfter(DateTime.now())) {
                return 'Date of birth cannot be in the future';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Gender
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Gender',
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
                  ),
                ),
              ),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                hint: Text(
                  'Select gender',
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
                  ),
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryRuby, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.people_outline_rounded, color: AppColors.primaryRuby),
                ),
                items: ['Female', 'Male', 'Prefer not to say']
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedGender = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your gender';
                  }
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

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
                        TextSpan(text: 'I agree to the HER AREA '),
                        TextSpan(text: 'Terms & Conditions', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryRuby)),
                        TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Privacy Policy Checkbox
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _agreedToPrivacyPolicy,
                  activeColor: AppColors.primaryRuby,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (val) => setState(() => _agreedToPrivacyPolicy = val ?? false),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _agreedToPrivacyPolicy = !_agreedToPrivacyPolicy),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 13,
                        color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
                        height: 1.4,
                      ),
                      children: const [
                        TextSpan(text: 'I agree to the HER AREA '),
                        TextSpan(text: 'Privacy Policy', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryRuby)),
                        TextSpan(text: '.'),
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
