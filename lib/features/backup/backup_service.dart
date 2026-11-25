import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import '../../core/time/clock.dart';
import 'backup_crypto.dart';
import 'backup_models.dart';
import 'backup_payload.dart';
import 'registry_archive.dart';

class IncomingBackup {
  const IncomingBackup({required this.bytes, required this.name});
  final Uint8List bytes;
  final String name;
}

abstract class BackupFileGateway {
  const BackupFileGateway();

  Future<Uint8List?> pickBackup();

  /// Writes [bytes] to a location the user chooses.
  ///
  /// Returns only after that write succeeds. A cancel throws [BackupCancelled]
  /// and must not leave the caller believing a file was saved.
  Future<void> saveBackup({
    required Uint8List bytes,
    required String suggestedName,
  });

  /// Returns an incoming backup if the app was launched by tapping a backup file.
  Future<IncomingBackup?> getInitialBackup() => Future.value(null);

  /// Emits incoming backups opened while the app is running.
  Stream<IncomingBackup> get onBackupOpened => const Stream.empty();
}

class RegistryBackupService {
  RegistryBackupService({
    required this.archive,
    required this.files,
    required this.clock,
    required this.tempDirectory,
  });

  final RegistryArchive archive;
  final BackupFileGateway files;
  final Clock clock;
  final Directory tempDirectory;

  static const _tempPrefix = '.registry-backup-';
  static const _tempSuffix = '.tmp';

  String suggestedName() {
    final local = clock.now().toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return 'registry-backup-$year-$month-$day.rgry';
  }

  Future<void> exportBackup({
    required String password,
    required BackupCancelToken cancel,
    void Function(BackupPhase phase)? onProgress,
  }) async {
    await _sweepTemps();
    cancel.throwIfCancelled();
    onProgress?.call(BackupPhase.protecting);
    final plaintext = RegistryBackupPayload.encode(
      BackupSnapshot(
        documents: archive.documents,
        subscriptions: archive.subscriptions,
      ),
    );
    Uint8List? encrypted;
    File? temp;
    try {
      cancel.throwIfCancelled();
      encrypted = await RegistryBackupCrypto.encrypt(
        plaintext: plaintext,
        password: password,
        cancel: cancel,
      );
      plaintext.fillRange(0, plaintext.length, 0);
      cancel.throwIfCancelled();
      temp = await _writeTemp(encrypted);
      cancel.throwIfCancelled();
      onProgress?.call(BackupPhase.writing);
      await files.saveBackup(bytes: encrypted, suggestedName: suggestedName());
    } on BackupException {
      rethrow;
    } on FileSystemException catch (error) {
      throw _classifyIo(error);
    } finally {
      plaintext.fillRange(0, plaintext.length, 0);
      if (encrypted != null) {
        encrypted.fillRange(0, encrypted.length, 0);
      }
      await _deleteTemp(temp);
    }
  }

  Future<OpenedBackup> openBackup({
    required Uint8List bytes,
    required String password,
    required BackupCancelToken cancel,
    void Function(BackupPhase phase)? onProgress,
  }) async {
    cancel.throwIfCancelled();
    onProgress?.call(BackupPhase.checking);
    final plaintext = await RegistryBackupCrypto.decrypt(
      file: bytes,
      password: password,
      cancel: cancel,
    );
    try {
      cancel.throwIfCancelled();
      final snapshot = RegistryBackupPayload.decode(plaintext);
      cancel.throwIfCancelled();
      return OpenedBackup(snapshot);
    } finally {
      plaintext.fillRange(0, plaintext.length, 0);
    }
  }

  /// Replaces the on-device registry with the opened backup.
  ///
  /// Commercial plan limits are not consulted. A restore keeps every record
  /// in the backup, including when a Free plan would block new records.
  Future<void> restoreBackup({
    required OpenedBackup opened,
    required BackupCancelToken cancel,
    void Function(BackupPhase phase)? onProgress,
  }) async {
    if (opened.consumed) {
      throw const BackupInvalid('consumed');
    }
    cancel.throwIfCancelled();
    onProgress?.call(BackupPhase.restoring);
    try {
      await archive.replaceAll(
        documents: opened.snapshot.documents,
        subscriptions: opened.snapshot.subscriptions,
        cancel: cancel,
      );
      opened.consumed = true;
    } on BackupException {
      rethrow;
    } on FileSystemException catch (error) {
      throw _classifyIo(error, restore: true);
    } catch (error) {
      if (error is BackupException) {
        rethrow;
      }
      throw const BackupRestoreFailed();
    }
  }

  Future<File> _writeTemp(Uint8List bytes) async {
    await tempDirectory.create(recursive: true);
    final name =
        '$_tempPrefix${DateTime.now().microsecondsSinceEpoch}$_tempSuffix';
    final file = File(p.join(tempDirectory.path, name));
    try {
      await file.writeAsBytes(bytes, flush: true);
    } on FileSystemException catch (error) {
      await _deleteTemp(file);
      throw _classifyIo(error);
    }
    return file;
  }

  Future<void> _deleteTemp(File? file) async {
    if (file == null) {
      return;
    }
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } on IOException {
      return;
    }
  }

  Future<void> _sweepTemps() async {
    if (!await tempDirectory.exists()) {
      return;
    }
    await for (final entity in tempDirectory.list(followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final name = p.basename(entity.path);
      if (!name.startsWith(_tempPrefix) || !name.endsWith(_tempSuffix)) {
        continue;
      }
      try {
        await entity.delete();
      } on IOException {
        continue;
      }
    }
  }

  BackupException _classifyIo(
    FileSystemException error, {
    bool restore = false,
  }) {
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
    if (restore) {
      return const BackupRestoreFailed();
    }
    return const BackupDestinationException();
  }
}
