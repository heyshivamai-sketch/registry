import 'package:flutter/material.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/backup/backup_service.dart';
import 'package:the_registry/features/documents/data/image_picker_image_service.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/documents/data/ml_kit_document_ocr_service.dart';
import 'package:the_registry/features/documents/domain/date_picker_service.dart';
import 'package:the_registry/features/documents/domain/document_ocr.dart';
import 'package:the_registry/features/documents/domain/document_repository.dart';
import 'package:the_registry/features/documents/domain/image_picker_service.dart';
import 'package:the_registry/features/reminders/reminder_coordinator.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_repository.dart';

class RegistryDependencies extends InheritedWidget {
  const RegistryDependencies({
    super.key,
    required this.documents,
    required this.subscriptions,
    required this.imagePicker,
    required this.datePicker,
    required this.documentOcr,
    required this.clock,
    required this.reminders,
    required this.backups,
    required this.backupFiles,
    required super.child,
  });

  final DocumentRepository documents;
  final SubscriptionRepository subscriptions;
  final ImagePickerService imagePicker;
  final DatePickerService datePicker;
  final DocumentOcrService documentOcr;
  final Clock clock;
  final ReminderCoordinator reminders;
  final RegistryBackupService backups;
  final BackupFileGateway backupFiles;

  static RegistryDependencies of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'RegistryDependencies not found in context');
    return scope!;
  }

  static RegistryDependencies? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RegistryDependencies>();
  }

  @override
  bool updateShouldNotify(RegistryDependencies oldWidget) {
    return documents != oldWidget.documents ||
        subscriptions != oldWidget.subscriptions ||
        imagePicker != oldWidget.imagePicker ||
        datePicker != oldWidget.datePicker ||
        documentOcr != oldWidget.documentOcr ||
        clock != oldWidget.clock ||
        reminders != oldWidget.reminders ||
        backups != oldWidget.backups ||
        backupFiles != oldWidget.backupFiles;
  }
}

/// In-memory default used when a test or preview constructs RegistryApp
/// without repositories. Production startup injects the SQLite repositories
/// and must not fall back to these after a storage error.
DocumentRepository createDefaultDocumentRepository() {
  return InMemoryDocumentRepository();
}

/// In-memory default used when a test or preview constructs RegistryApp
/// without repositories. Production startup injects the SQLite repositories.
SubscriptionRepository createDefaultSubscriptionRepository() {
  return InMemorySubscriptionRepository();
}

ImagePickerService createDefaultImagePicker() {
  return ImagePickerImageService();
}

DatePickerService createDefaultDatePicker() {
  return const MaterialDatePickerService();
}

DocumentOcrService createDefaultDocumentOcr() {
  return MlKitDocumentOcrService();
}
