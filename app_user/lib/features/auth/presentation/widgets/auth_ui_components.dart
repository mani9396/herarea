import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Centralized UI design tokens for HER AREA mobile-first authentication screens.
/// Inspired by the official pink & magenta branding.
class AuthTokens {
  AuthTokens._();

  // Vibrant Pink & Magenta Branding Palette
  static const Color brandPink = Color(0xFFEE337A); // Matches official logo background
  static const Color brandMagenta = Color(0xFFD81B60);
  static const Color deepMagenta = Color(0xFFAD1457);
  static const Color berry = Color(0xFF880E4F);

  // Soft Surface Tokens
  static const Color surfaceWhite = Colors.white;
  static const Color surfaceBlush = Color(0xFFFFF2F6);
  static const Color surfaceCard = Colors.white;

  // Form & Border Colors
  static const Color inputBorder = Color(0xFFF0CBD7);
  static const Color inputBorderFocused = Color(0xFFEE337A);
  static const Color inputFill = Color(0xFFFCF9FA);

  // Text Colors
  static const Color textDark = Color(0xFF2B1620);
  static const Color textMuted = Color(0xFF755E67);
  static const Color textLight = Colors.white;

  // Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFF337F),
      Color(0xFFEE337A),
      Color(0xFFD81B60),
      Color(0xFFAD1457),
      Color(0xFF880E4F),
    ],
    stops: [0.0, 0.22, 0.50, 0.80, 1.0],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFEE337A),
      Color(0xFFD81B60),
    ],
  );

  static const LinearGradient subtleGlassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x30FFFFFF),
      Color(0x10FFFFFF),
    ],
  );
}

/// Abstract ambient decorative shapes (translucent rings/circles)
/// Replaces city/monument skylines with modern abstract brand shapes.
class AuthBackgroundDecoration extends StatelessWidget {
  const AuthBackgroundDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // Top right subtle ambient glow ring
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 32),
              ),
            ),
          ),
          // Top left smaller glow circle
          Positioned(
            top: 120,
            left: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          // Center-right subtle soft glow
          Positioned(
            top: 280,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Official HER AREA Brand Header
/// Displays the exact attached logo asset, Brand Title, Tagline, and Headline.
class AuthBrandHeader extends StatelessWidget {
  final bool compact;
  final String? customHeadline;

  const AuthBrandHeader({
    super.key,
    this.compact = false,
    this.customHeadline,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 68.0 : 84.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Official HER AREA Logo
        Semantics(
          label: 'Her Area Official Logo',
          child: Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(compact ? 18 : 22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(compact ? 18 : 22),
              child: Image.asset(
                'assets/images/her_area_logo.png',
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to jpg variant if png fails to load
                  return Image.asset(
                    'assets/images/her_area_logo.jpg',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? 12 : 16),

        // Brand Name: Her Area™
        Text(
          'Her Area™',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.displayFont,
            fontSize: compact ? 26 : 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),

        // Tagline: DISCOVER · CONNECT · GROW
        Text(
          'DISCOVER · CONNECT · GROW',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.4,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
        SizedBox(height: compact ? 8 : 12),

        // Headline: A Safer, Brighter Everyday for Every Woman
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            customHeadline ?? 'A Safer, Brighter Everyday for Every Woman',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: compact ? 13 : 14.5,
              fontWeight: FontWeight.w500,
              height: 1.35,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ),
      ],
    );
  }
}

/// Feature pills for mobile-first brand showcase (Find, Connect, Work, Grow)
class AuthFeatureBadgesRow extends StatelessWidget {
  const AuthFeatureBadgesRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        Expanded(child: _FeaturePill(icon: Icons.search_rounded, title: 'Find', subtitle: 'Local Stores')),
        Expanded(child: _FeaturePill(icon: Icons.people_alt_rounded, title: 'Connect', subtitle: 'With Vendors')),
        Expanded(child: _FeaturePill(icon: Icons.work_outline_rounded, title: 'Work', subtitle: 'Opportunities')),
        Expanded(child: _FeaturePill(icon: Icons.favorite_rounded, title: 'Grow', subtitle: 'Together')),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeaturePill({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 9.0,
          ),
        ),
      ],
    );
  }
}

/// Reusable Card Container for the authentication form surface.
class AuthFormCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AuthFormCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF22161C) : AuthTokens.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF4A2536) : AuthTokens.surfaceBlush,
          width: 1.5,
        ),
      ),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: child,
    );
  }
}

/// Primary Prominent Magenta Button following Reference Image 1
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isSecondary;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isSecondary) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AuthTokens.brandMagenta, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            foregroundColor: AuthTokens.brandMagenta,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: AuthTokens.buttonGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AuthTokens.brandPink.withValues(alpha: 0.38),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppTypography.bodyFont,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        if (icon != null) ...[
                          const SizedBox(width: 8),
                          Icon(icon, color: Colors.white, size: 18),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom Styled Input Field matching HER AREA Pink Branding
class AuthTextField extends StatefulWidget {
  final String label;
  final String? hintText;
  final String? helperText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool isPassword;
  final bool readOnly;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final VoidCallback? onTap;

  const AuthTextField({
    super.key,
    required this.label,
    this.hintText,
    this.helperText,
    this.controller,
    this.validator,
    this.isPassword = false,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixWidget,
    this.onTap,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: isDark ? AppColors.textHighDark : AuthTokens.textDark,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: widget.controller,
            validator: widget.validator,
            obscureText: _obscureText,
            readOnly: widget.readOnly,
            keyboardType: widget.keyboardType,
            onTap: widget.onTap,
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textHighDark : AuthTokens.textDark,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText ?? 'Enter ${widget.label.toLowerCase()}',
              hintStyle: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 14,
                color: isDark ? AppColors.textDisabledDark : const Color(0xFFA69099),
              ),
              helperText: widget.helperText,
              helperStyle: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 11.5,
                color: isDark ? AppColors.textMediumDark : AuthTokens.textMuted,
              ),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF2E1C24)
                  : (widget.readOnly ? const Color(0xFFF9F1F4) : const Color(0xFFFCF7F9)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
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
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 2.0,
                ),
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, size: 20, color: AuthTokens.brandPink)
                  : null,
              suffixIcon: widget.suffixWidget ??
                  (widget.isPassword
                      ? IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: isDark
                                ? AppColors.textMediumDark
                                : const Color(0xFF9E848E),
                          ),
                          onPressed: () =>
                              setState(() => _obscureText = !_obscureText),
                        )
                      : null),
            ),
          ),
        ],
      ),
    );
  }
}

