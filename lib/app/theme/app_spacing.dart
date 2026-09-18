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

  /// Extra ListView padding so the FAB does not cover the last item.
  static const double scrollFabClearance = minTapTarget + xl + md;
  static const double countdownSize = 76;
  static const double horizonDays = 90;

  /// Minimum width that can hold an extended FAB plus comfortable gutter.
  static const double extendedFabMinWidth = 360;

  /// Minimum height that keeps an extended FAB off mid-page content.
  static const double extendedFabMinHeight = 720;

  /// Use a labelled FAB only when width, height and text scale all allow it.
  static bool useExtendedFab(BuildContext context) {
    final media = MediaQuery.of(context);
    final textScale = media.textScaler.scale(14) / 14;
    final size = media.size;
    if (size.width < extendedFabMinWidth) {
      return false;
    }
    if (size.height < extendedFabMinHeight) {
      return false;
    }
    if (textScale >= 1.3) {
      return false;
    }
    return true;
  }
}
