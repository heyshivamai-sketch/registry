import 'dart:convert';
import 'dart:typed_data';

import 'package:the_registry/features/csv_import/csv_import_limits.dart';

enum CsvFileFailure {
  tooLarge,
  notUtf8,
  unreadable,
  tooManyColumns,
  tooManyRows,
}

class CsvRawRow {
  const CsvRawRow({required this.lineNumber, required this.cells});

  final int lineNumber;
  final List<String> cells;
}

class CsvRawTable {
  const CsvRawTable({
    required this.headers,
    required this.headerLine,
    required this.rows,
  });

  final List<String> headers;
  final int headerLine;
  final List<CsvRawRow> rows;
}

class CsvTableResult {
  const CsvTableResult.table(this.table) : failure = null;

  const CsvTableResult.failure(this.failure) : table = null;

  final CsvRawTable? table;
  final CsvFileFailure? failure;
}

abstract final class CsvTableParser {
  static CsvTableResult parse(Uint8List bytes) {
    if (bytes.length > CsvImportLimits.maxFileBytes) {
      return const CsvTableResult.failure(CsvFileFailure.tooLarge);
    }
    final String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      return const CsvTableResult.failure(CsvFileFailure.notUtf8);
    }
    final List<_ParsedRow> parsed;
    try {
      parsed = _parseRows(text);
    } on FormatException {
      return const CsvTableResult.failure(CsvFileFailure.unreadable);
    }
    final content = [
      for (final row in parsed)
        if (row.cells.any((cell) => cell.trim().isNotEmpty)) row,
    ];
    if (content.isEmpty) {
      return const CsvTableResult.failure(CsvFileFailure.unreadable);
    }
    final header = content.first;
    if (header.cells.length > CsvImportLimits.maxColumns) {
      return const CsvTableResult.failure(CsvFileFailure.tooManyColumns);
    }
    final data = content.skip(1).toList();
    if (data.length > CsvImportLimits.maxDataRows) {
      return const CsvTableResult.failure(CsvFileFailure.tooManyRows);
    }
    for (final row in data) {
      if (row.cells.length > CsvImportLimits.maxColumns) {
        return const CsvTableResult.failure(CsvFileFailure.tooManyColumns);
      }
    }
    return CsvTableResult.table(
      CsvRawTable(
        headers: header.cells,
        headerLine: header.lineNumber,
        rows: [
          for (final row in data)
            CsvRawRow(lineNumber: row.lineNumber, cells: row.cells),
        ],
      ),
    );
  }

  static List<_ParsedRow> _parseRows(String text) {
    final source = text.startsWith('\uFEFF') ? text.substring(1) : text;
    final rows = <_ParsedRow>[];
    final cells = <String>[];
    final cell = StringBuffer();
    var inQuotes = false;
    var line = 1;
    var rowLine = 1;
    var index = 0;
    while (index < source.length) {
      final char = source[index];
      if (inQuotes) {
        if (char == '"') {
          if (index + 1 < source.length && source[index + 1] == '"') {
            cell.write('"');
            index += 2;
            continue;
          }
          inQuotes = false;
          index += 1;
          continue;
        }
        if (char == '\n') {
          line += 1;
        }
        cell.write(char);
        index += 1;
        continue;
      }
      if (char == '"') {
        inQuotes = true;
        index += 1;
        continue;
      }
      if (char == ',') {
        cells.add(cell.toString());
        cell.clear();
        index += 1;
        continue;
      }
      if (char == '\n' || char == '\r') {
        if (char == '\r' &&
            index + 1 < source.length &&
            source[index + 1] == '\n') {
          index += 1;
        }
        cells.add(cell.toString());
        cell.clear();
        rows.add(_ParsedRow(rowLine, List<String>.from(cells)));
        cells.clear();
        index += 1;
        line += 1;
        rowLine = line;
        continue;
      }
      cell.write(char);
      index += 1;
    }
    if (inQuotes) {
      throw const FormatException('unclosed quote');
    }
    if (cell.isNotEmpty || cells.isNotEmpty) {
      cells.add(cell.toString());
      rows.add(_ParsedRow(rowLine, List<String>.from(cells)));
    }
    return rows;
  }
}

class _ParsedRow {
  const _ParsedRow(this.lineNumber, this.cells);

  final int lineNumber;
  final List<String> cells;
}
