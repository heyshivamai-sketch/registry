/// Bounds for the one generic charge CSV this version can read.
///
/// These are technical limits. Local Pro does not raise them, and they are
/// not a claim that bank statements in general can be imported.
abstract final class CsvImportLimits {
  static const maxFileBytes = 1024 * 1024;
  static const maxDataRows = 2000;
  static const maxColumns = 32;
  static const maxFieldChars = 200;

  /// Documented header names. The person still chooses the columns.
  static const dateHeader = 'date';
  static const merchantHeader = 'merchant';
  static const amountHeader = 'amount_minor';
  static const currencyHeader = 'currency';
}
