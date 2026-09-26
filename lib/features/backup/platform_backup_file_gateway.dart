import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:the_registry/features/backup/backup_models.dart';
import 'package:the_registry/features/backup/backup_service.dart';

/// Android document-picker operations that do not trust a plugin success flag.
abstract class AndroidBackupBridge {
  /// True only after the chosen document contains [bytes] exactly.
  ///
  /// Null means the user cancelled. A missing stream or a short, partial, or
  /// longer-than-expected destination throws [PlatformException].
  Future<bool?> save({required Uint8List bytes, required String name});

  /// The selected bytes, or null when the user cancels.
  ///
  /// Reads at most [maxBytes] + 1 from the provider. A longer file throws
  /// [PlatformException] with code `oversized` and is not returned.
  Future<Uint8List?> pick({required int maxBytes});
}

class MethodChannelAndroidBackupBridge implements AndroidBackupBridge {
  const MethodChannelAndroidBackupBridge();

  static const channel = MethodChannel('com.registry.app/backup_file');

  @override
  Future<bool?> save({required Uint8List bytes, required String name}) {
    return channel.invokeMethod<bool>('save', <String, Object>{
      'name': name,
      'bytes': bytes,
    });
  }

  @override
  Future<Uint8List?> pick({required int maxBytes}) {
    return channel.invokeMethod<Uint8List>('pick', <String, Object>{
      'maxBytes': maxBytes,
    });
  }
}

/// Opens and saves one backup with the dialog that works on this platform.
///
/// Android uses [AndroidBackupBridge]. file_picker can report a save as
/// successful when the destination stream is missing, and file_selector copies
/// a content URI into cache before Dart can reject its size. Desktop save uses
/// file_selector. iOS save still uses file_picker and checks the written length.
class PlatformBackupFileGateway implements BackupFileGateway {
  const PlatformBackupFileGateway({this._androidBridge});

  final AndroidBackupBridge? _androidBridge;

  static const _typeGroup = XTypeGroup(
    label: 'Registry backup',
    extensions: <String>['rgry'],
    mimeTypes: <String>['application/octet-stream'],
    uniformTypeIdentifiers: <String>['public.data'],
  );

  AndroidBackupBridge? get _android {
    if (_androidBridge != null) {
      return _androidBridge;
    }
    if (Platform.isAndroid) {
      return const MethodChannelAndroidBackupBridge();
    }
    return null;
  }

  @override
  Future<Uint8List?> pickBackup() async {
    final android = _android;
    if (android != null) {
      return _pickOnAndroid(android);
    }
    final file = await openFile(acceptedTypeGroups: const [_typeGroup]);
    if (file == null) {
      return null;
    }
    final path = file.path;
    if (path.isNotEmpty && !path.startsWith('content:')) {
      final source = File(path);
      if (await source.exists()) {
        final length = await source.length();
        if (length > BackupLimits.maxBackupFileBytes) {
          throw const BackupOversized();
        }
        return _readCapped(source, length);
      }
    }
    final length = await file.length();
    if (length > BackupLimits.maxBackupFileBytes) {
      throw const BackupOversized();
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > BackupLimits.maxBackupFileBytes) {
      throw const BackupOversized();
    }
    return bytes;
  }

  Future<Uint8List?> _pickOnAndroid(AndroidBackupBridge android) async {
    try {
      final bytes = await android.pick(
        maxBytes: BackupLimits.maxBackupFileBytes,
      );
      if (bytes == null) {
        return null;
      }
      if (bytes.length > BackupLimits.maxBackupFileBytes) {
        bytes.fillRange(0, bytes.length, 0);
        throw const BackupOversized();
      }
      return bytes;
    } on PlatformException catch (error) {
      throw _fromPlatform(error);
    }
  }

  @override
  Future<void> saveBackup({
    required Uint8List bytes,
    required String suggestedName,
  }) async {
    if (bytes.isEmpty || bytes.length > BackupLimits.maxBackupFileBytes) {
      throw const BackupOversized();
    }
    final android = _android;
    if (android != null) {
      await _saveOnAndroid(android, bytes, suggestedName);
      return;
    }
    if (Platform.isIOS) {
      await _saveOnIos(bytes, suggestedName);
      return;
    }
    await _saveWithSelector(bytes, suggestedName);
  }

  Future<void> _saveOnAndroid(
    AndroidBackupBridge android,
    Uint8List bytes,
    String suggestedName,
  ) async {
    try {
      final saved = await android.save(bytes: bytes, name: suggestedName);
      if (saved != true) {
        throw const BackupCancelled();
      }
    } on PlatformException catch (error) {
      throw _fromPlatform(error);
    }
  }

  Future<void> _saveOnIos(Uint8List bytes, String suggestedName) async {
    final documents = await getApplicationDocumentsDirectory();
    final iosCopy = File(p.join(documents.path, suggestedName));
    String? savedPath;
    try {
      savedPath = await FilePicker.platform.saveFile(
        dialogTitle: suggestedName,
        fileName: suggestedName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: const ['rgry'],
      );
      if (savedPath == null) {
        throw const BackupCancelled();
      }
      final destination = File(savedPath);
      if (!await destination.exists() ||
          await destination.length() != bytes.length) {
        throw const BackupDestinationException();
      }
    } on BackupException {
      rethrow;
    } on PlatformException catch (error) {
      throw _fromPlatform(error);
    } on FileSystemException catch (error) {
      throw _fromFileSystem(error);
    } finally {
      if (savedPath == null ||
          p.normalize(savedPath) != p.normalize(iosCopy.path)) {
        await _deleteQuietly(iosCopy);
      }
    }
  }

  Future<void> _saveWithSelector(Uint8List bytes, String suggestedName) async {
    final location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: const [_typeGroup],
    );
    if (location == null) {
      throw const BackupCancelled();
    }
    final destination = File(location.path);
    final partial = File('${location.path}.partial');
    try {
      await partial.writeAsBytes(bytes, flush: true);
      if (await destination.exists()) {
        await destination.delete();
      }
      await partial.rename(destination.path);
      if (!await destination.exists() ||
          await destination.length() != bytes.length) {
        throw const BackupDestinationException();
      }
    } on BackupException {
      await _deleteQuietly(partial);
      rethrow;
    } on FileSystemException catch (error) {
      await _deleteQuietly(partial);
      throw _fromFileSystem(error);
    }
  }

  Future<Uint8List> _readCapped(File source, int length) async {
    if (length > BackupLimits.maxBackupFileBytes) {
      throw const BackupOversized();
    }
    final bytes = await source.readAsBytes();
    if (bytes.length > BackupLimits.maxBackupFileBytes) {
      throw const BackupOversized();
    }
    return bytes;
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } on IOException {
      return;
    }
  }

  BackupException _fromPlatform(PlatformException error) {
    switch (error.code) {
      case 'missing_stream':
      case 'write_failed':
      case 'partial':
        return const BackupDestinationException();
      case 'oversized':
        return const BackupOversized();
      case 'no_space':
        return const BackupInsufficientStorage();
    }
    final message = '${error.code} ${error.message ?? ''}'.toLowerCase();
    if (message.contains('no space') ||
        message.contains('enospc') ||
        message.contains('disk full') ||
        message.contains('out of space')) {
      return const BackupInsufficientStorage();
    }
    return const BackupDestinationException();
  }

  BackupException _fromFileSystem(FileSystemException error) {
    final code = error.osError?.errorCode;
    final message = '${error.message} ${error.osError?.message ?? ''}'
        .toLowerCase();
    if (code == 28 ||
        code == 112 ||
        message.contains('no space') ||
        message.contains('enospc') ||
        message.contains('disk full')) {
      return const BackupInsufficientStorage();
    }
    return const BackupDestinationException();
  }
}
