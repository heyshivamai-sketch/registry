import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:the_registry/core/persistence/document_attachment_store.dart';
import 'package:the_registry/core/persistence/registry_database.dart';
import 'package:the_registry/features/documents/data/sqlite_document_repository.dart';
import 'package:the_registry/features/subscriptions/data/sqlite_subscription_repository.dart';

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

  Future<void> close() => _database.close();
}

Future<RegistryStore> openDefaultRegistryStore() async {
  final root = await getApplicationDocumentsDirectory();
  return RegistryStore.open(
    databasePath: p.join(root.path, 'registry.db'),
    attachmentsDirectory: Directory(p.join(root.path, 'registry_attachments')),
  );
}
