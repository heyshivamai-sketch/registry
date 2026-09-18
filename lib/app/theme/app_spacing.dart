import 'package:flutter/material.dart';

/// Spacing and sizing tokens on an 8-point grid.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;

  static const double screenPadding = md;
  static const double sectionGap = lg;
  static const double itemGap = md;
  static const double minTapTarget = 48;
  static const double iconMd = 24;
  static const double iconLg = 40;
  static const double iconTile = 48;
  static const double dockHeight = 68;
  static const double dockInset = md;
  static const double addButtonSize = 52;

  /// Extra ListView padding so the floating dock does not cover the last item.
  static const double scrollDockClearance = dockHeight + xl + md;
  static const double scrollFabClearance = scrollDockClearance;
  static const double countdownSize = 76;
  static const double horizonDays = 90;

  static bool compactNavigation(BuildContext context) {
    final media = MediaQuery.of(context);
    final textScale = media.textScaler.scale(14) / 14;
    return media.size.width < 360 || textScale >= 1.3;
  }
}
