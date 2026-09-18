import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_colors.dart';

/// Subtle elevation used sparingly on Aura surfaces.
abstract final class AppShadows {
  static List<BoxShadow> card(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: (isDark ? Colors.black : AppColors.deepNavy).withValues(
          alpha: isDark ? 0.28 : 0.07,
        ),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static List<BoxShadow> dock(BuildContext context) {
    return [
      BoxShadow(
        color: AppColors.midnight.withValues(alpha: 0.28),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ];
  }
}
