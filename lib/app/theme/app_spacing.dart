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
  static const double addButtonLift = 8;
  static const double headerButton = 42;
  static const double searchHeight = 48;
  static const double buttonHeight = 48;
  static const double pulseRadius = 27;
  static const double passRadius = 25;

  /// Dock chrome that overlays `extendBody` content, excluding system inset.
  static const double overlayDockExtent =
      dockHeight + addButtonLift + addButtonLift;

  /// Extra ListView padding so the floating dock does not cover the last item.
  /// Matches dock chrome plus a small gap; system inset is added at use sites.
  static const double scrollDockClearance = overlayDockExtent + sm;

  static const double scrollFabClearance = scrollDockClearance;

  /// Gesture-area plus dock chrome. Uses [viewPadding] because `extendBody`
  /// zeroes [MediaQuery.padding] at the bottom of tab bodies.
  static double dockSafeBottom(BuildContext context) {
    final viewBottom = MediaQuery.viewPaddingOf(context).bottom;
    return viewBottom > dockBottom ? viewBottom : dockBottom;
  }

  /// Space the shell keeps below tab bodies so the lifted add button stays clear.
  static double dockOverlayExtent(BuildContext context) {
    return dockSafeBottom(context) + overlayDockExtent;
  }

  /// Bottom inset so a floating snackbar sits above the dock and system gesture area.
  static double snackBarDockInset(BuildContext context) {
    return dockSafeBottom(context) + overlayDockExtent + xs;
  }

  /// Extra list padding so the last row can scroll fully above the dock pill.
  ///
  /// Tab bodies use [extendBody], so this is the only reserved space; the shell
  /// must not also inset the IndexedStack or the last rows clip above a blank band.
  static double scrollClearanceForDock(BuildContext context) {
    return dockOverlayExtent(context);
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
