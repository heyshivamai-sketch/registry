import 'package:flutter/material.dart';

/// Material 3 type scale with premium, readable hierarchy.
abstract final class AppTypography {
  static TextTheme textTheme(ColorScheme colorScheme) {
    final base = Typography.material2021(platform: TargetPlatform.android).black
        .apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        );

    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.15,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        height: 1.05,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.25,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.2,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
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
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
        height: 1.3,
      ),
    );
  }

  static TextStyle? eyebrow(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    return theme.textTheme.labelSmall?.copyWith(
      color: color ?? theme.colorScheme.tertiary,
    );
  }
}
