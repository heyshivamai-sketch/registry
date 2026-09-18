import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_colors.dart';

/// Subtle elevation used sparingly on Aura surfaces.
abstract final class AppShadows {
  static List<BoxShadow> card(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: (isDark ? Colors.black : const Color(0xFF222B5B)).withValues(
          alpha: isDark ? 0.28 : 0.075,
        ),
        blurRadius: 34,
        offset: const Offset(0, 12),
      ),
    ];
  }

  static List<BoxShadow> pulse(BuildContext context) {
    return [
      BoxShadow(
        color: const Color(0xFF202B65).withValues(alpha: 0.25),
        blurRadius: 36,
        offset: const Offset(0, 18),
      ),
    ];
  }

  static List<BoxShadow> dock(BuildContext context) {
    return [
      BoxShadow(
        color: AppColors.midnight.withValues(alpha: 0.3),
        blurRadius: 30,
        offset: const Offset(0, 14),
      ),
    ];
  }
}
