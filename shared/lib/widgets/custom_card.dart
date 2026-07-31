import 'package:flutter/material.dart';
import 'package:shared/theme/app_spacing.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double elevation;
  final BorderRadius? borderRadius;

  const CustomCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = AppSpacing.cardPadding,
    this.margin,
    this.backgroundColor,
    this.elevation = AppSpacing.elevationLow,
    this.borderRadius = AppSpacing.borderRadiusMd,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardTheme.color,
        borderRadius: borderRadius,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: elevation * 3,
                  offset: Offset(0, elevation),
                )
              ]
            : null,
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? AppSpacing.borderRadiusMd,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );

    return cardContent;
  }
}
