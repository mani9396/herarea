import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:her_area/core/routing/route_paths.dart';
import 'package:her_area/features/auth/presentation/widgets/auth_ui_components.dart';
import 'package:shared/shared.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  void _onLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final success = await ref.read(authApiRepositoryProvider).loginWithPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          context.go(RoutePaths.home);
        } else {
          setState(() => _errorMessage = 'Invalid email or password. Please try again.');
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
            // Usable Desktop Flutter Web Layout
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
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                          child: AuthFormCard(
                            child: _buildLoginForm(isDark),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Mobile-First Pink Gradient Layout inspired by Reference Image 1
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
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 12),
                            // Prominent official HER AREA logo and header
                            const AuthBrandHeader(),
                            const SizedBox(height: 24),

                            // Mobile Feature Pills
                            const AuthFeatureBadgesRow(),
                            const SizedBox(height: 28),

                            // Clean White / Light-Pink Form Card
                            AuthFormCard(
                              child: _buildLoginForm(isDark),
                            ),
                            const SizedBox(height: 24),
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

  Widget _buildLoginForm(bool isDark) {
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
                  'Welcome Back',
                  style: TextStyle(
                    fontFamily: AppTypography.displayFont,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textHighDark : AuthTokens.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AuthTokens.brandPink.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Member',
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AuthTokens.brandMagenta,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Sign in to access your local boutiques, private trial suites, and artisan chat.',
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 13,
              color: isDark ? AppColors.textMediumDark : AuthTokens.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Email Input Field
          AuthTextField(
            label: 'Email Address',
            hintText: 'Enter your registered email',
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

          // Password Input Field with Visibility Toggle
          AuthTextField(
            label: 'Password',
            hintText: 'Enter your password',
            controller: _passwordController,
            isPassword: true,
            prefixIcon: Icons.lock_outline_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),

          // Forgot Password Link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push(RoutePaths.forgotPassword),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 44),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              ),
              child: const Text(
                'Forgot Password / Recovery?',
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  color: AuthTokens.brandMagenta,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          // Validation & API Error Message Display
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        color: AppColors.error,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Prominent Magenta Sign In Button
          AuthPrimaryButton(
            label: 'Sign In',
            icon: Icons.arrow_forward_rounded,
            isLoading: _isLoading,
            onPressed: _onLogin,
          ),
          const SizedBox(height: 24),

          // Divider Section
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: isDark ? const Color(0xFF452B35) : const Color(0xFFECD5DE),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'NEW TO HER AREA?',
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: isDark ? AppColors.textDisabledDark : const Color(0xFFA68D96),
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: isDark ? const Color(0xFF452B35) : const Color(0xFFECD5DE),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Create New Member Account Button
          AuthPrimaryButton(
            label: 'Create New Member Account',
            isSecondary: true,
            icon: Icons.person_add_outlined,
            onPressed: () => context.push(RoutePaths.signup),
          ),
          const SizedBox(height: 18),

          Center(
            child: Text(
              'By signing in, you agree to our Terms of Service & Privacy Policy.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 11,
                color: isDark ? AppColors.textDisabledDark : const Color(0xFF9E8790),
              ),
            ),
          ),
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
                    AuthBrandHeader(),
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
