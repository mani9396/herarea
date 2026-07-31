import 'package:flutter/material.dart';
import 'package:shared/responsive/responsive_layout.dart';

extension ResponsiveExtensions on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isMobile => screenWidth < ResponsiveLayout.tabletBreakpoint;
  bool get isTablet => screenWidth >= ResponsiveLayout.tabletBreakpoint && screenWidth < ResponsiveLayout.desktopBreakpoint;
  bool get isDesktop => screenWidth >= ResponsiveLayout.desktopBreakpoint;

  ResponsiveScreenType get screenType => ResponsiveLayout.getScreenType(this);

  /// Convenient helper to resolve values adaptively based on current screen breakpoint
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop) return desktop ?? tablet ?? mobile;
    if (isTablet) return tablet ?? mobile;
    return mobile;
  }

  /// Calculates grid column count dynamically for responsive layouts
  int responsiveGridColumns({int mobile = 1, int tablet = 2, int desktop = 4}) {
    return responsiveValue<int>(mobile: mobile, tablet: tablet, desktop: desktop);
  }
}
