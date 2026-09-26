import 'dart:io';

import 'package:the_registry/core/persistence/registry_store.dart';
import 'package:the_registry/features/backup/backup_models.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';

abstract class RegistryArchive {
  List<RegistryDocument> get documents;

  List<RegistrySubscription> get subscriptions;

  Future<void> replaceAll({
    required List<RegistryDocument> documents,
    required List<RegistrySubscription> subscriptions,
    required BackupCancelToken cancel,
  });
}

class MemoryRegistryArchive implements RegistryArchive {
  MemoryRegistryArchive({
    required this.documentsRepository,
    required this.subscriptionsRepository,
  });

  final InMemoryDocumentRepository documentsRepository;
  final InMemorySubscriptionRepository subscriptionsRepository;

  @override
  List<RegistryDocument> get documents => documentsRepository.documents;

  @override
  List<RegistrySubscription> get subscriptions =>
      subscriptionsRepository.subscriptions;

  @override
  Future<void> replaceAll({
    required List<RegistryDocument> documents,
    required List<RegistrySubscription> subscriptions,
    required BackupCancelToken cancel,
  }) async {
    cancel.throwIfCancelled();
    documentsRepository.replaceContents(documents, notify: false);
    subscriptionsRepository.replaceContents(subscriptions, notify: false);
    documentsRepository.notifyReplacement();
    subscriptionsRepository.notifyReplacement();
  }
}

class SqliteRegistryArchive implements RegistryArchive {
  SqliteRegistryArchive(this.store);

  final RegistryStore store;

  /// Test hook. Runs inside the database transaction, before any row changes
  /// when it throws. The store then deletes staged files and leaves the
  /// previous registry in place.
  Future<void> Function()? beforeCommit;

  @override
  List<RegistryDocument> get documents => store.documents.documents;

  @override
  List<RegistrySubscription> get subscriptions =>
      store.subscriptions.subscriptions;

  @override
  Future<void> replaceAll({
    required List<RegistryDocument> documents,
    required List<RegistrySubscription> subscriptions,
    required BackupCancelToken cancel,
  }) async {
    try {
      await store.replaceAll(
        documents: documents,
        subscriptions: subscriptions,
        isCancelled: () => cancel.isCancelled,
        beforeCommit: beforeCommit,
      );
    } on RegistryReplaceCancelled {
      throw const BackupCancelled();
    } on FileSystemException catch (error) {
      throw _storageOrRestore(error);
    }
  }
}

BackupException _storageOrRestore(FileSystemException error) {
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
  return const BackupRestoreFailed();
}
