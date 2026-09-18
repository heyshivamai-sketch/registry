import 'package:flutter/material.dart';

/// Semantic colour tokens for Registry Aura.
///
/// Screens and widgets should consume [ThemeData] / [AppStatusColors] /
/// [AppBrandColors] rather than these values directly.
abstract final class AppColors {
  static const Color midnight = Color(0xFF111936);
  static const Color deepNavy = Color(0xFF23366C);
  static const Color violet = Color(0xFF6558F5);
  static const Color aqua = Color(0xFF42D8B7);
  static const Color coral = Color(0xFFFF675D);
  static const Color amber = Color(0xFFE9AA27);

  static const Color primary = midnight;
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFE8E6FF);
  static const Color onPrimaryContainer = Color(0xFF1B1658);

  static const Color indigo = violet;
  static const Color indigoContainer = Color(0xFFE8E6FF);

  static const Color secondary = Color(0xFF1AA392);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFD8F8F1);
  static const Color onSecondaryContainer = Color(0xFF053830);

  static const Color background = Color(0xFFF7F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFEEF0F7);
  static const Color onSurface = midnight;
  static const Color onSurfaceVariant = Color(0xFF66718B);
  static const Color outline = Color(0xFFE7E9F2);
  static const Color outlineVariant = Color(0xFFE7E9F2);

  static const Color heroStart = midnight;
  static const Color heroEnd = deepNavy;

  static const Color urgent = coral;
  static const Color urgentContainer = Color(0xFFFFE8E5);
  static const Color onUrgentContainer = Color(0xFF9F302B);

  static const Color warning = amber;
  static const Color warningContainer = Color(0xFFFFF3D4);
  static const Color onWarningContainer = Color(0xFF8A5A00);

  static const Color success = Color(0xFF086B59);
  static const Color successContainer = Color(0xFFDFF8F2);
  static const Color onSuccessContainer = Color(0xFF086B59);

  static const Color expired = Color(0xFF5F6B7A);
  static const Color expiredContainer = Color(0xFFEEF1F4);
  static const Color onExpiredContainer = Color(0xFF2F3742);

  static const Color darkBackground = Color(0xFF0C1024);
  static const Color darkSurface = Color(0xFF171C36);
  static const Color darkSurfaceContainer = Color(0xFF22284A);
  static const Color darkOnSurface = Color(0xFFE8EAF4);
  static const Color darkOnSurfaceVariant = Color(0xFF9AA3B8);
  static const Color darkOutline = Color(0xFF2C3454);
  static const Color darkOutlineVariant = Color(0xFF2C3454);
}

@immutable
class AppBrandColors extends ThemeExtension<AppBrandColors> {
  const AppBrandColors({
    required this.heroStart,
    required this.heroEnd,
    required this.indigo,
    required this.violet,
    required this.aqua,
    required this.dock,
    required this.dockForeground,
  });

  final Color heroStart;
  final Color heroEnd;
  final Color indigo;
  final Color violet;
  final Color aqua;
  final Color dock;
  final Color dockForeground;

  static const AppBrandColors light = AppBrandColors(
    heroStart: AppColors.heroStart,
    heroEnd: AppColors.heroEnd,
    indigo: AppColors.indigo,
    violet: AppColors.violet,
    aqua: AppColors.aqua,
    dock: Color(0xEB11162E),
    dockForeground: Color(0xFF8790AD),
  );

  static const AppBrandColors dark = AppBrandColors(
    heroStart: Color(0xFF101633),
    heroEnd: Color(0xFF2A3A72),
    indigo: Color(0xFF9AABFF),
    violet: Color(0xFF9A8CFF),
    aqua: Color(0xFF6EE7CB),
    dock: Color(0xF211162E),
    dockForeground: Color(0xFFAEB5CF),
  );

  static AppBrandColors of(BuildContext context) {
    return Theme.of(context).extension<AppBrandColors>() ?? light;
  }

  @override
  AppBrandColors copyWith({
    Color? heroStart,
    Color? heroEnd,
    Color? indigo,
    Color? violet,
    Color? aqua,
    Color? dock,
    Color? dockForeground,
  }) {
    return AppBrandColors(
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
      indigo: indigo ?? this.indigo,
      violet: violet ?? this.violet,
      aqua: aqua ?? this.aqua,
      dock: dock ?? this.dock,
      dockForeground: dockForeground ?? this.dockForeground,
    );
  }

  @override
  AppBrandColors lerp(ThemeExtension<AppBrandColors>? other, double t) {
    if (other is! AppBrandColors) {
      return this;
    }
    return AppBrandColors(
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
      indigo: Color.lerp(indigo, other.indigo, t)!,
      violet: Color.lerp(violet, other.violet, t)!,
      aqua: Color.lerp(aqua, other.aqua, t)!,
      dock: Color.lerp(dock, other.dock, t)!,
      dockForeground: Color.lerp(dockForeground, other.dockForeground, t)!,
    );
  }
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
    success: Color(0xFF6EE7CB),
    successContainer: Color(0xFF0F3D34),
    onSuccessContainer: Color(0xFFC8F6EA),
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
