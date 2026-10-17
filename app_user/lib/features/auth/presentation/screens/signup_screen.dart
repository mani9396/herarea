import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:her_area/core/routing/route_paths.dart';
import 'package:her_area/features/auth/presentation/widgets/auth_ui_components.dart';
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
      final dobStr =
          "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
      final gender = _selectedGender == 'Female'
          ? 'FEMALE'
          : _selectedGender == 'Male'
              ? 'MALE'
              : 'PREFER_NOT_TO_SAY';

      final success = await ref.read(authApiRepositoryProvider).requestOtp(
            email,
            role: 'CUSTOMER',
            purpose: 'REGISTRATION',
            fullName: fullName,
          );

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
              primary: AuthTokens.brandPink,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
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
                  child: _buildDesktopBrandPanel(),
                ),
                Expanded(
                  flex: 6,
                  child: Container(
                    color: isDark ? const Color(0xFF190F14) : const Color(0xFFFFF7F9),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
                          child: AuthFormCard(
                            child: _buildSignupForm(isDark),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Mobile-First Layout
          return Container(
            decoration: const BoxDecoration(
              gradient: AuthTokens.backgroundGradient,
            ),
            child: Stack(
              children: [
                const AuthBackgroundDecoration(),
                SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 8),
                            // Compact brand header with official logo
                            const AuthBrandHeader(
                              compact: true,
                              customHeadline: 'Join our exclusive women-first local community',
                            ),
                            const SizedBox(height: 20),

                            // White / Light-Pink Form Card
                            AuthFormCard(
                              child: _buildSignupForm(isDark),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Create Account',
                  style: TextStyle(
                    fontFamily: AppTypography.displayFont,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textHighDark : AuthTokens.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => context.pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  minimumSize: const Size(44, 40),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AuthTokens.brandMagenta),
                label: const Text(
                  'Sign In',
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontWeight: FontWeight.w700,
                    color: AuthTokens.brandMagenta,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Create your verified account to unlock direct appointments, home measurement bookings, and private trial suites.',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 13,
              color: isDark ? AppColors.textMediumDark : AuthTokens.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Full Name Input
          AuthTextField(
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
          AuthTextField(
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
          AuthTextField(
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

          // Gender Dropdown
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gender',
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: isDark ? AppColors.textHighDark : AuthTokens.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedGender,
                  hint: Text(
                    'Select gender',
                    style: TextStyle(
                      fontFamily: AppTypography.bodyFont,
                      fontSize: 14,
                      color: isDark ? AppColors.textDisabledDark : const Color(0xFFA69099),
                    ),
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2E1C24) : const Color(0xFFFCF7F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF4A2A38) : AuthTokens.inputBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF4A2A38) : AuthTokens.inputBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AuthTokens.brandPink,
                        width: 2.0,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                    ),
                    prefixIcon: const Icon(Icons.people_outline_rounded, color: AuthTokens.brandPink, size: 20),
                  ),
                  items: ['Female', 'Male', 'Prefer not to say']
                      .map((label) => DropdownMenuItem(
                            value: label,
                            child: Text(
                              label,
                              style: TextStyle(
                                fontFamily: AppTypography.bodyFont,
                                fontSize: 14.5,
                                color: isDark ? AppColors.textHighDark : AuthTokens.textDark,
                              ),
                            ),
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
          ),

          // Terms of Service Checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _agreedToTerms,
                  activeColor: AuthTokens.brandPink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 12.5,
                        color: isDark ? AppColors.textMediumDark : AuthTokens.textDark,
                        height: 1.4,
                      ),
                      children: const [
                        TextSpan(text: 'I agree to the HER AREA '),
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: TextStyle(fontWeight: FontWeight.w700, color: AuthTokens.brandMagenta),
                        ),
                        TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Privacy Policy Checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _agreedToPrivacyPolicy,
                  activeColor: AuthTokens.brandPink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  onChanged: (val) => setState(() => _agreedToPrivacyPolicy = val ?? false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _agreedToPrivacyPolicy = !_agreedToPrivacyPolicy),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontSize: 12.5,
                        color: isDark ? AppColors.textMediumDark : AuthTokens.textDark,
                        height: 1.4,
                      ),
                      children: const [
                        TextSpan(text: 'I agree to the HER AREA '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(fontWeight: FontWeight.w700, color: AuthTokens.brandMagenta),
                        ),
                        TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Prominent Magenta Submit Button
          AuthPrimaryButton(
            label: 'Send Verification OTP Token',
            icon: Icons.auto_awesome,
            isLoading: _isLoading,
            onPressed: _onSignup,
          ),
          const SizedBox(height: 20),

          // Already Registered / Sign In Link
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Already registered with HER AREA? ',
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 13,
                    color: isDark ? AppColors.textMediumDark : AuthTokens.textMuted,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      fontFamily: AppTypography.bodyFont,
                      fontSize: 13,
                      color: AuthTokens.brandMagenta,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDesktopBrandPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AuthTokens.backgroundGradient,
      ),
      child: Stack(
        children: [
          const AuthBackgroundDecoration(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    AuthBrandHeader(compact: false),
                    SizedBox(height: 36),
                    AuthFeatureBadgesRow(),
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
