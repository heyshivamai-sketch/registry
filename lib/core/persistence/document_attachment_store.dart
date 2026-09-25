import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// Private on-device files for document images.
///
/// Names are generated inside [root]. Reads never follow a path outside that
/// directory. Writes land in a temporary file and then replace the destination.
class DocumentAttachmentStore {
  DocumentAttachmentStore(this.root);

  final Directory root;
  int _sequence = 0;

  Future<void> ensureExists() {
    return root.create(recursive: true);
  }

  Future<String> writeAtomically({
    required String documentId,
    required Uint8List bytes,
  }) async {
    await ensureExists();
    final name = _nextFileName(documentId);
    final temp = File(p.join(root.path, '.$name.tmp'));
    final destination = File(p.join(root.path, name));
    try {
      await temp.writeAsBytes(bytes, flush: true);
      await temp.rename(destination.path);
    } catch (error) {
      await _deleteQuietly(temp);
      rethrow;
    }
    return name;
  }

  /// Returns null when the file is missing, unsafe, or unreadable.
  Future<Uint8List?> read(String fileName) async {
    final file = _fileIfSafe(fileName);
    if (file == null) {
      return null;
    }
    try {
      final type = await FileSystemEntity.type(file.path, followLinks: false);
      if (type != FileSystemEntityType.file) {
        return null;
      }
      return await file.readAsBytes();
    } on IOException {
      return null;
    }
  }

  Future<void> deleteIfPresent(String? fileName) async {
    final file = _fileIfSafe(fileName);
    if (file == null) {
      return;
    }
    try {
      final type = await FileSystemEntity.type(file.path, followLinks: false);
      if (type != FileSystemEntityType.file) {
        return;
      }
      await file.delete();
    } on PathNotFoundException {
      return;
    }
  }

  /// Removes incomplete writes and files that no document references.
  Future<void> deleteUnreferenced(Set<String> referenced) async {
    if (!await root.exists()) {
      return;
    }
    await for (final entity in root.list(followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final name = p.basename(entity.path);
      final incomplete = name.startsWith('.') || name.endsWith('.tmp');
      if (!incomplete && referenced.contains(name)) {
        continue;
      }
      try {
        await entity.delete();
      } on IOException {
        // A leftover file must not block opening saved records.
      }
    }
  }

  String _nextFileName(String documentId) {
    _sequence += 1;
    final token = _safeToken(documentId);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return '${token}_${stamp}_$_sequence.bin';
  }

  File? _fileIfSafe(String? fileName) {
    if (fileName == null || !_isSafeFileName(fileName)) {
      return null;
    }
    final path = p.join(root.path, fileName);
    if (p.basename(path) != fileName) {
      return null;
    }
    return File(path);
  }

  static String _safeToken(String documentId) {
    final cleaned = documentId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    if (cleaned.isEmpty) {
      return 'document';
    }
    return cleaned;
  }

  static bool _isSafeFileName(String fileName) {
    return RegExp(r'^[A-Za-z0-9_-]+\.bin$').hasMatch(fileName);
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } on IOException {
      return;
    }
  }
}
