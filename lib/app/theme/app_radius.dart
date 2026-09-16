import 'package:flutter/material.dart';

/// Corner radius tokens.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double card = 18;
  static const double chip = 100;
  static const double button = 12;

  static const BorderRadius cardBorder = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius chipBorder = BorderRadius.all(
    Radius.circular(chip),
  );
  static const BorderRadius buttonBorder = BorderRadius.all(
    Radius.circular(button),
  );
}
