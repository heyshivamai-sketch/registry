import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';

/// Practical bounds for one portable backup.
///
/// Document photos are already reduced to 1280px before they are saved, so a
/// 32 MiB plaintext cap covers a large personal registry without holding an
/// unbounded file in memory. Argon2id uses its own 19 MiB working set.
abstract final class BackupLimits {
  static const int maxBackupFileBytes = 32 * 1024 * 1024 + 512;
  static const int maxPlaintextBytes = 32 * 1024 * 1024;
  static const int maxAttachmentBytes = 8 * 1024 * 1024;
  static const int maxDocuments = 2000;
  static const int maxSubscriptions = 2000;
  static const int maxFieldsPerDocument = 40;
  static const int maxHistoryPerDocument = 100;
  static const int maxStringBytes = 4000;
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 256;
}

/// Failure codes. Messages never include the password or record contents.
sealed class BackupException implements Exception {
  const BackupException(this.code);

  final String code;

  @override
  String toString() => 'BackupException($code)';
}

final class BackupCancelled extends BackupException {
  const BackupCancelled() : super('cancelled');
}

final class BackupWrongPassword extends BackupException {
  const BackupWrongPassword() : super('wrong-password');
}

final class BackupUnsupportedVersion extends BackupException {
  const BackupUnsupportedVersion() : super('unsupported-version');
}

final class BackupInvalid extends BackupException {
  const BackupInvalid([super.code = 'invalid']);
}

final class BackupTampered extends BackupException {
  const BackupTampered() : super('tampered');
}

final class BackupOversized extends BackupException {
  const BackupOversized() : super('oversized');
}

final class BackupInsufficientStorage extends BackupException {
  const BackupInsufficientStorage() : super('insufficient-storage');
}

final class BackupDestinationException extends BackupException {
  const BackupDestinationException() : super('destination');
}

final class BackupRestoreFailed extends BackupException {
  const BackupRestoreFailed() : super('restore-failed');
}

class BackupCancelToken {
  var _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    _cancelled = true;
  }

  void throwIfCancelled() {
    if (_cancelled) {
      throw const BackupCancelled();
    }
  }
}

enum BackupPhase { protecting, writing, checking, restoring }

class BackupSnapshot {
  const BackupSnapshot({required this.documents, required this.subscriptions});

  final List<RegistryDocument> documents;
  final List<RegistrySubscription> subscriptions;

  int get attachmentCount {
    var count = 0;
    for (final document in documents) {
      if (document.hasAttachment) {
        count += 1;
      }
    }
    return count;
  }
}

class BackupPreview {
  const BackupPreview({
    required this.documents,
    required this.subscriptions,
    required this.attachments,
  });

  final int documents;
  final int subscriptions;
  final int attachments;
}

class OpenedBackup {
  OpenedBackup(this.snapshot);

  final BackupSnapshot snapshot;
  var consumed = false;

  BackupPreview get preview => BackupPreview(
    documents: snapshot.documents.length,
    subscriptions: snapshot.subscriptions.length,
    attachments: snapshot.attachmentCount,
  );

  /// Clears decrypted images when this backup is not kept as the live registry.
  void wipeAttachments() {
    for (final document in snapshot.documents) {
      document.attachmentBytes?.fillRange(
        0,
        document.attachmentBytes!.length,
        0,
      );
    }
  }
}
