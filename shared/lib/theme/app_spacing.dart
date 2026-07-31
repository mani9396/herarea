import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // Spacing Intervals (Atomic scale)
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
  static const double huge = 64.0;

  // Border Radii
  static const Radius radiusSm = Radius.circular(8.0);
  static const Radius radiusMd = Radius.circular(16.0);
  static const Radius radiusLg = Radius.circular(24.0);
  static const Radius radiusCircular = Radius.circular(999.0);

  static const BorderRadius borderRadiusSm = BorderRadius.all(radiusSm);
  static const BorderRadius borderRadiusMd = BorderRadius.all(radiusMd);
  static const BorderRadius borderRadiusLg = BorderRadius.all(radiusLg);
  static const BorderRadius borderRadiusCircular = BorderRadius.all(radiusCircular);

  // Standard Edge Insets / Paddings
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: lg, vertical: md);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: xl, vertical: 14.0);

  // Elevation Tokens
  static const double elevationNone = 0.0;
  static const double elevationLow = 2.0;
  static const double elevationMedium = 6.0;
  static const double elevationHigh = 12.0;
}
