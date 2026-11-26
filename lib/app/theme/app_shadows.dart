import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Restrained Paper Wallet shadows: subtle paper lift without heavy glow.
abstract final class AppShadows {
  static List<BoxShadow> card(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: (isDark ? Colors.black : AppColors.midnight).withValues(
          alpha: isDark ? 0.24 : 0.045,
        ),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> pulse(BuildContext context) {
    return [
      BoxShadow(
        color: AppColors.deepNavy.withValues(alpha: 0.20),
        blurRadius: 22,
        offset: const Offset(0, 10),
      ),
    ];
  }

  static List<BoxShadow> dock(BuildContext context) {
    return [
      BoxShadow(
        color: AppColors.midnight.withValues(alpha: 0.08),
        blurRadius: 18,
        offset: const Offset(0, 4),
      ),
    ];
  }
}
