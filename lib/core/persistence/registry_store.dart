import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:the_registry/core/persistence/document_attachment_store.dart';
import 'package:the_registry/core/persistence/registry_database.dart';
import 'package:the_registry/features/documents/data/sqlite_document_repository.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/subscriptions/data/sqlite_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';

/// Opens the on-device database and returns repositories that are already loaded.
///
/// A failure leaves the database file in place. Callers must not replace it
/// with an empty in-memory repository.
class RegistryStore {
  RegistryStore._({
    required this.documents,
    required this.subscriptions,
    required this._database,
  });

  final SqliteDocumentRepository documents;
  final SqliteSubscriptionRepository subscriptions;
  final Database _database;

  static Future<RegistryStore> open({
    required String databasePath,
    required Directory attachmentsDirectory,
    Future<Database> Function(String path)? openDatabase,
  }) async {
    final opener = openDatabase ?? RegistryDatabase.open;
    final database = await opener(databasePath);
    try {
      final attachments = DocumentAttachmentStore(attachmentsDirectory);
      await attachments.ensureExists();
      final documents = await SqliteDocumentRepository.load(
        database,
        attachments,
      );
      final subscriptions = await SqliteSubscriptionRepository.load(database);
      try {
        await attachments.deleteUnreferenced(documents.attachmentFileNames);
      } on IOException {
        // Saved rows are already loaded. Leftover files can wait.
      }
      return RegistryStore._(
        documents: documents,
        subscriptions: subscriptions,
        database: database,
      );
    } on Object {
      await database.close();
      rethrow;
    }
  }

  /// Replaces documents and subscriptions in one database transaction.
  ///
  /// New attachment files are written and flushed before that transaction.
  /// If staging, cancellation, or the transaction fails, those new files are
  /// deleted and the previous rows stay in place. There is no merge.
  ///
  /// A process kill after the transaction commits and before old attachment
  /// files are deleted leaves the restored registry in place. The next open
  /// drops attachment files that no row references. A kill after the new
  /// files are written and before the transaction commits leaves the previous
  /// registry; the next open drops the unreferenced new files. SQLite rolls
  /// back a kill during the transaction. The database file and the attachment
  /// directory cannot be committed as one filesystem operation.
  Future<void> replaceAll({
    required List<RegistryDocument> documents,
    required List<RegistrySubscription> subscriptions,
    bool Function()? isCancelled,
    Future<void> Function()? beforeCommit,
  }) async {
    if (isCancelled?.call() ?? false) {
      throw const RegistryReplaceCancelled();
    }
    final previousFiles = {...this.documents.attachmentFileNames};
    final staged = await this.documents.stageReplacementAttachments(documents);
    try {
      if (isCancelled?.call() ?? false) {
        throw const RegistryReplaceCancelled();
      }
      await _database.transaction((txn) async {
        if (beforeCommit != null) {
          await beforeCommit();
        }
        if (isCancelled?.call() ?? false) {
          throw const RegistryReplaceCancelled();
        }
        await this.documents.insertReplacement(txn, documents, staged);
        await this.subscriptions.insertReplacement(txn, subscriptions);
      });
    } catch (error) {
      await this.documents.discardStagedAttachments(staged);
      rethrow;
    }
    this.documents.adoptReplacement(documents, staged, notify: false);
    this.subscriptions.adoptReplacement(subscriptions, notify: false);
    this.documents.notifyReplacement();
    this.subscriptions.notifyReplacement();
    final kept = staged.whereType<String>().toSet();
    await this.documents.deleteAttachmentNames(previousFiles.difference(kept));
  }

  Future<void> close() => _database.close();
}

/// Thrown when a replacement stops before the database transaction commits.
class RegistryReplaceCancelled implements Exception {
  const RegistryReplaceCancelled();
}

Future<RegistryStore> openDefaultRegistryStore() async {
  final root = await getApplicationDocumentsDirectory();
  final storeId = _safeStoreId(
    const String.fromEnvironment('REGISTRY_STORE_ID'),
  );
  final suffix = storeId.isEmpty ? '' : '_$storeId';
  return RegistryStore.open(
    databasePath: p.join(root.path, 'registry$suffix.db'),
    attachmentsDirectory: Directory(
      p.join(root.path, 'registry_attachments$suffix'),
    ),
  );
}

String _safeStoreId(String value) {
  if (RegExp(r'^[A-Za-z0-9_-]{1,32}$').hasMatch(value)) {
    return value;
  }
  return '';
}
