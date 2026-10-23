import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final bool showHeadline;

  const AuthBrandHeader({
    super.key,
    this.compact = false,
    this.customHeadline,
    this.showHeadline = true,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 52.0 : 84.0;

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
              color: Colors.white,
              borderRadius: BorderRadius.circular(compact ? 14 : 22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: compact ? 12 : 18,
                  offset: Offset(0, compact ? 4 : 8),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.25),
                  blurRadius: compact ? 8 : 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(compact ? 14 : 22),
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
        SizedBox(height: compact ? 6 : 16),

        // Brand Name: Her Area™
        Text(
          'Her Area™',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.displayFont,
            fontSize: compact ? 22 : 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        // Headline: Everything You Need, All in One Place.
        if (showHeadline && (customHeadline == null || customHeadline!.isNotEmpty)) ...[
          SizedBox(height: compact ? 6 : 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 16),
            child: Text(
              customHeadline ?? 'Everything You Need, All in One Place.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: compact ? 11.5 : 14.5,
                fontWeight: FontWeight.w500,
                height: 1.3,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Feature pills for mobile-first brand showcase (Find, Explore, Connect)
class AuthFeatureBadgesRow extends StatelessWidget {
  final bool compact;
  const AuthFeatureBadgesRow({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(child: _FeaturePill(icon: Icons.search_rounded, title: 'Find', subtitle: 'Local Stores', compact: compact)),
        Expanded(child: _FeaturePill(icon: Icons.explore_rounded, title: 'Explore', subtitle: 'Curated Styles', compact: compact)),
        Expanded(child: _FeaturePill(icon: Icons.people_alt_rounded, title: 'Connect', subtitle: 'With Vendors', compact: compact)),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;

  const _FeaturePill({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final circleSize = compact ? 32.0 : 42.0;
    final iconSize = compact ? 15.0 : 20.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
        SizedBox(height: compact ? 2 : 5),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 10.0 : 11.5,
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
            fontSize: compact ? 8.0 : 9.0,
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
  final bool compact;

  const AuthFormCard({
    super.key,
    required this.child,
    this.padding,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF22161C) : AuthTokens.surfaceCard,
        borderRadius: BorderRadius.circular(compact ? 20 : 24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
            blurRadius: compact ? 20 : 30,
            spreadRadius: compact ? 1 : 2,
            offset: Offset(0, compact ? 6 : 10),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF4A2536) : AuthTokens.surfaceBlush,
          width: 1.5,
        ),
      ),
      padding: padding ?? EdgeInsets.symmetric(horizontal: compact ? 16 : 18, vertical: compact ? 12 : 24),
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
  final bool compact;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isSecondary = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = compact ? 42.0 : 52.0;
    final borderRadius = BorderRadius.circular(compact ? 21 : 26);
    final fontSize = compact ? 13.5 : (isSecondary ? 14.5 : 15.0);

    if (isSecondary) {
      return SizedBox(
        width: double.infinity,
        height: buttonHeight,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AuthTokens.brandMagenta, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            foregroundColor: AuthTokens.brandMagenta,
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: compact ? 16 : 18),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: fontSize,
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
      height: buttonHeight,
      decoration: BoxDecoration(
        gradient: AuthTokens.buttonGradient,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: AuthTokens.brandPink.withValues(alpha: 0.38),
            blurRadius: compact ? 12 : 16,
            offset: Offset(0, compact ? 4 : 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: compact ? 18 : 22,
                      height: compact ? 18 : 22,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.2,
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
                            style: TextStyle(
                              fontFamily: AppTypography.bodyFont,
                              fontSize: fontSize,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        if (icon != null) ...[
                          const SizedBox(width: 8),
                          Icon(icon, color: Colors.white, size: compact ? 16 : 18),
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
  final bool compact;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final AutovalidateMode? autovalidateMode;

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
    this.compact = false,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.autovalidateMode,
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
      padding: EdgeInsets.only(bottom: widget.compact ? 8 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontWeight: FontWeight.w700,
              fontSize: widget.compact ? 12.0 : 13.5,
              color: isDark ? AppColors.textHighDark : AuthTokens.textDark,
            ),
          ),
          SizedBox(height: widget.compact ? 3 : 6),
          TextFormField(
            controller: widget.controller,
            validator: widget.validator,
            obscureText: _obscureText,
            readOnly: widget.readOnly,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            textCapitalization: widget.textCapitalization,
            autovalidateMode: widget.autovalidateMode,
            onTap: widget.onTap,
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: widget.compact ? 13.5 : 15,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textHighDark : AuthTokens.textDark,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText ?? 'Enter ${widget.label.toLowerCase()}',
              hintStyle: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: widget.compact ? 12.5 : 14,
                color: isDark ? AppColors.textDisabledDark : const Color(0xFFA69099),
              ),
              helperText: widget.helperText,
              helperStyle: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 11.0,
                color: isDark ? AppColors.textMediumDark : AuthTokens.textMuted,
              ),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF2E1C24)
                  : (widget.readOnly ? const Color(0xFFF9F1F4) : const Color(0xFFFCF7F9)),
              contentPadding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 14 : 18,
                vertical: widget.compact ? 10 : 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.compact ? 12 : 16),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF4A2A38) : AuthTokens.inputBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.compact ? 12 : 16),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF4A2A38) : AuthTokens.inputBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.compact ? 12 : 16),
                borderSide: const BorderSide(
                  color: AuthTokens.brandPink,
                  width: 2.0,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.compact ? 12 : 16),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.compact ? 12 : 16),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 2.0,
                ),
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      size: widget.compact ? 18 : 20,
                      color: AuthTokens.brandPink,
                    )
                  : null,
              suffixIcon: widget.suffixWidget ??
                  (widget.isPassword
                      ? IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: widget.compact ? 18 : 20,
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

/// Formatter for email that strictly allows only small letters (a-z), numbers (0-9),
/// and standard email special characters, completely blocking capital letters and spaces.
class LowerCaseEmailInputFormatter extends TextInputFormatter {
  const LowerCaseEmailInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    // Disallow capital letters (A-Z) and spaces
    if (RegExp(r'[A-Z\s]').hasMatch(text)) {
      return oldValue;
    }

    // Allow only small letters, numbers, and standard email special characters
    if (!RegExp(r'''^[a-z0-9@._+\-!#$%&'*+/=?^_`{|}~]*$''').hasMatch(text)) {
      return oldValue;
    }

    return newValue;
  }
}

/// Formatter for 10-digit Indian mobile numbers:
/// - First digit MUST be 6, 7, 8, or 9 (rejects 0, 1, 2, 3, 4, 5).
/// - Only digits (0-9) allowed.
/// - Maximum 10 digits allowed.
class IndianMobileInputFormatter extends TextInputFormatter {
  const IndianMobileInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }

    // Only digits allowed
    if (!RegExp(r'^\d+$').hasMatch(text)) {
      return oldValue;
    }

    // First digit must be 6, 7, 8, or 9
    if (!RegExp(r'^[6-9]').hasMatch(text)) {
      return oldValue;
    }

    // Maximum 10 digits
    if (text.length > 10) {
      return oldValue;
    }

    return newValue;
  }
}

