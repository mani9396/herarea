import 'package:flutter/material.dart';
import 'package:shared/theme/app_colors.dart';
import 'package:shared/theme/app_spacing.dart';
import 'package:shared/theme/app_typography.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String? hintText;
  final String? helperText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool isPassword;
  final bool readOnly;
  final bool autofocus;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final Widget? suffixWidget;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final int maxLines;
  final int? maxLength;

  const CustomTextField({
    super.key,
    required this.label,
    this.hintText,
    this.helperText,
    this.controller,
    this.validator,
    this.isPassword = false,
    this.readOnly = false,
    this.autofocus = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.prefixWidget,
    this.suffixWidget,
    this.onChanged,
    this.onTap,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
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
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontFamily: AppTypography.bodyFont,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textHighDark : AppColors.textHighLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: widget.controller,
            validator: widget.validator,
            obscureText: _obscureText,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            onTap: widget.onTap,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            maxLength: widget.maxLength,
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textHighDark : AppColors.textHighLight,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText ?? 'Enter ${widget.label.toLowerCase()}',
              helperText: widget.helperText,
              helperStyle: TextStyle(
                fontFamily: AppTypography.bodyFont,
                fontSize: 12,
                color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
              ),
              counterText: '', // Hides character counter if maxLength is used
              filled: true,
              fillColor: widget.readOnly
                  ? (isDark ? AppColors.surfaceVariantDark.withValues(alpha: 0.5) : AppColors.surfaceVariantLight.withValues(alpha: 0.4))
                  : (isDark ? AppColors.surfaceDark : Colors.white),
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusMd,
                borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusMd,
                borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusMd,
                borderSide: const BorderSide(color: AppColors.primaryRuby, width: 2.0),
              ),
              errorBorder: const OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusMd,
                borderSide: BorderSide(color: AppColors.error, width: 1.5),
              ),
              prefixIcon: widget.prefixWidget ?? (widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, size: 20, color: AppColors.primaryRuby)
                  : null),
              suffixIcon: widget.suffixWidget ?? (widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: isDark ? AppColors.textMediumDark : AppColors.textMediumLight,
                      ),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
                    )
                  : null),
            ),
          ),
        ],
      ),
    );
  }
}
