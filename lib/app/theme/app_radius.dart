import 'package:flutter/material.dart';

/// Corner radius tokens. Premium surfaces sit between 20 and 28.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double card = 18;
  static const double lg = 24;
  static const double xl = 28;
  static const double chip = 100;
  static const double button = 14;
  static const double dock = 25;
  static const double iconTile = 14;
  static const double search = 17;
  static const double metric = 17;
  static const double sheetAction = 15;

  static const BorderRadius cardBorder = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius lgBorder = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlBorder = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius chipBorder = BorderRadius.all(
    Radius.circular(chip),
  );
  static const BorderRadius buttonBorder = BorderRadius.all(
    Radius.circular(button),
  );
  static const BorderRadius dockBorder = BorderRadius.all(
    Radius.circular(dock),
  );
}
