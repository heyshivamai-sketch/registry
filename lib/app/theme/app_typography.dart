import 'package:flutter/material.dart';

/// Material 3 type scale for Regiday Paper Wallet:
/// editorial serif (`Lora`) for major page titles and signature passes,
/// clean system sans-serif for form fields, dates, amounts, tabs, and body copy.
abstract final class AppTypography {
  static const String serifFamily = 'Lora';

  static TextTheme textTheme(ColorScheme colorScheme) {
    final base = Typography.material2021().black.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        fontFamily: serifFamily,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.15,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontFamily: serifFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.12,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.25,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.25,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      bodyLarge: base.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: base.bodyMedium?.copyWith(
        height: 1.45,
        color: colorScheme.onSurfaceVariant,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.35,
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        height: 1.3,
      ),
    );
  }

  /// Editorial serif style for signature pass titles and hero headings.
  /// Automatically removes negative letter-spacing in RTL/Arabic layouts so
  /// connected Arabic glyphs render cleanly via the platform fallback font.
  static TextStyle serif(
    BuildContext context, {
    double? fontSize,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? height,
  }) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final base = Theme.of(context).textTheme.headlineMedium;
    return (base ?? const TextStyle()).copyWith(
      fontFamily: serifFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      height: height ?? 1.15,
      letterSpacing: isRtl ? 0 : -0.35,
    );
  }

  static TextStyle? eyebrow(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return theme.textTheme.labelSmall?.copyWith(
      color: color ?? theme.colorScheme.tertiary,
      letterSpacing: isRtl ? 0 : 1.1,
    );
  }
}
