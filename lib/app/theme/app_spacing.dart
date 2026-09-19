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

  static const double screenPadding = 18;
  static const double pageTop = sm;
  static const double sectionGap = lg;
  static const double itemGap = md;
  static const double minTapTarget = 48;
  static const double iconMd = 24;
  static const double iconLg = 40;
  static const double iconTile = 48;
  static const double dockHeight = 68;
  static const double dockInset = md;
  static const double dockBottom = 15;
  static const double addButtonSize = 52;
  static const double addButtonLift = 11;
  static const double headerButton = 42;
  static const double searchHeight = 48;
  static const double buttonHeight = 48;
  static const double pulseRadius = 27;
  static const double passRadius = 25;

  /// Dock chrome that overlays `extendBody` content, excluding system inset.
  static const double overlayDockExtent =
      dockHeight + addButtonLift + addButtonLift;

  /// Extra ListView padding so the floating dock does not cover the last item.
  static const double scrollDockClearance = overlayDockExtent + minTapTarget;

  static const double scrollFabClearance = scrollDockClearance;

  /// Space the shell keeps below tab bodies so the lifted add button stays clear.
  static double dockOverlayExtent(BuildContext context) {
    return overlayDockExtent + minTapTarget;
  }

  /// Bottom inset so a floating snackbar sits above the dock and system gesture area.
  static double snackBarDockInset(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final dockSafeBottom = safeBottom > dockBottom ? safeBottom : dockBottom;
    return dockSafeBottom + overlayDockExtent + xs;
  }

  /// Compact list padding; the shell already offsets tab bodies by [dockOverlayExtent].
  static double scrollClearanceForDock(BuildContext context) {
    return md;
  }

  /// Extra scroll padding so a focused field stays clear of the pinned wizard bar.
  static const EdgeInsets wizardFieldScrollPadding = EdgeInsets.fromLTRB(
    md,
    md,
    md,
    minTapTarget + xl,
  );

  static const double countdownSize = 54;
  static const double horizonDays = 90;

  static bool compactNavigation(BuildContext context) {
    final media = MediaQuery.of(context);
    final textScale = media.textScaler.scale(14) / 14;
    return media.size.width < 360 || textScale >= 1.3;
  }
}
