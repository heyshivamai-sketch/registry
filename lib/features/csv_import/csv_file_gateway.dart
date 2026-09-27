import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// A file the person explicitly chose. Null means they cancelled.
abstract class CsvFileGateway {
  Future<Uint8List?> pickCsv();
}

class PlatformCsvFileGateway implements CsvFileGateway {
  const PlatformCsvFileGateway();

  @override
  Future<Uint8List?> pickCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    return result.files.single.bytes;
  }
}
