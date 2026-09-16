import 'package:flutter/material.dart';

/// Semantic colour tokens for Registry.
///
/// Screens and widgets should consume [ThemeData] / [AppStatusColors] rather
/// than these values directly, so dark mode can be introduced later without
/// restyling call sites.
abstract final class AppColors {
  static const Color primary = Color(0xFF1B365D);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFD6E2F5);
  static const Color onPrimaryContainer = Color(0xFF0F2240);

  static const Color secondary = Color(0xFF1F8A80);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFCDECEA);
  static const Color onSecondaryContainer = Color(0xFF06332F);

  static const Color background = Color(0xFFF3F5F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFE8ECF1);
  static const Color onSurface = Color(0xFF1A1C1E);
  static const Color onSurfaceVariant = Color(0xFF4A5563);
  static const Color outline = Color(0xFFC5CDD6);
  static const Color outlineVariant = Color(0xFFDCE2E8);

  static const Color urgent = Color(0xFFC62828);
  static const Color urgentContainer = Color(0xFFFDECEC);
  static const Color onUrgentContainer = Color(0xFF7F1D1D);

  static const Color warning = Color(0xFFC47B00);
  static const Color warningContainer = Color(0xFFFFF4DC);
  static const Color onWarningContainer = Color(0xFF7A4A00);

  static const Color success = Color(0xFF2E7D32);
  static const Color successContainer = Color(0xFFE6F4EA);
  static const Color onSuccessContainer = Color(0xFF145218);

  static const Color expired = Color(0xFF5F6B7A);
  static const Color expiredContainer = Color(0xFFEEF1F4);
  static const Color onExpiredContainer = Color(0xFF2F3742);

  static const Color darkBackground = Color(0xFF111418);
  static const Color darkSurface = Color(0xFF1B2026);
  static const Color darkSurfaceContainer = Color(0xFF242A32);
  static const Color darkOnSurface = Color(0xFFE6E8EB);
  static const Color darkOnSurfaceVariant = Color(0xFFB3BCC6);
  static const Color darkOutline = Color(0xFF3E4752);
  static const Color darkOutlineVariant = Color(0xFF2E3640);
}

@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.urgent,
    required this.urgentContainer,
    required this.onUrgentContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.expired,
    required this.expiredContainer,
    required this.onExpiredContainer,
  });

  final Color urgent;
  final Color urgentContainer;
  final Color onUrgentContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color expired;
  final Color expiredContainer;
  final Color onExpiredContainer;

  static const AppStatusColors light = AppStatusColors(
    urgent: AppColors.urgent,
    urgentContainer: AppColors.urgentContainer,
    onUrgentContainer: AppColors.onUrgentContainer,
    warning: AppColors.warning,
    warningContainer: AppColors.warningContainer,
    onWarningContainer: AppColors.onWarningContainer,
    success: AppColors.success,
    successContainer: AppColors.successContainer,
    onSuccessContainer: AppColors.onSuccessContainer,
    expired: AppColors.expired,
    expiredContainer: AppColors.expiredContainer,
    onExpiredContainer: AppColors.onExpiredContainer,
  );

  static const AppStatusColors dark = AppStatusColors(
    urgent: Color(0xFFFF8A80),
    urgentContainer: Color(0xFF4E1C1C),
    onUrgentContainer: Color(0xFFFFDAD6),
    warning: Color(0xFFFFC46B),
    warningContainer: Color(0xFF4A3308),
    onWarningContainer: Color(0xFFFFE4B0),
    success: Color(0xFF81C784),
    successContainer: Color(0xFF1B3C22),
    onSuccessContainer: Color(0xFFC8E6C9),
    expired: Color(0xFFB0B8C1),
    expiredContainer: Color(0xFF2C333C),
    onExpiredContainer: Color(0xFFD5DBE1),
  );

  static AppStatusColors of(BuildContext context) {
    return Theme.of(context).extension<AppStatusColors>() ?? light;
  }

  @override
  AppStatusColors copyWith({
    Color? urgent,
    Color? urgentContainer,
    Color? onUrgentContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? expired,
    Color? expiredContainer,
    Color? onExpiredContainer,
  }) {
    return AppStatusColors(
      urgent: urgent ?? this.urgent,
      urgentContainer: urgentContainer ?? this.urgentContainer,
      onUrgentContainer: onUrgentContainer ?? this.onUrgentContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      expired: expired ?? this.expired,
      expiredContainer: expiredContainer ?? this.expiredContainer,
      onExpiredContainer: onExpiredContainer ?? this.onExpiredContainer,
    );
  }

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) {
      return this;
    }
    return AppStatusColors(
      urgent: Color.lerp(urgent, other.urgent, t)!,
      urgentContainer: Color.lerp(urgentContainer, other.urgentContainer, t)!,
      onUrgentContainer: Color.lerp(
        onUrgentContainer,
        other.onUrgentContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      expired: Color.lerp(expired, other.expired, t)!,
      expiredContainer: Color.lerp(
        expiredContainer,
        other.expiredContainer,
        t,
      )!,
      onExpiredContainer: Color.lerp(
        onExpiredContainer,
        other.onExpiredContainer,
        t,
      )!,
    );
  }
}
