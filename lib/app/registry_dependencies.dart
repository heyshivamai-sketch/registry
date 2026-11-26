import 'package:flutter/material.dart';

import '../core/time/clock.dart';
import '../features/ads/ads_controller.dart';
import '../features/app_lock/app_lock_controller.dart';
import '../features/backup/backup_service.dart';
import '../features/csv_import/csv_file_gateway.dart';
import '../features/documents/data/image_picker_image_service.dart';
import '../features/documents/data/in_memory_document_repository.dart';
import '../features/documents/domain/date_picker_service.dart';
import '../features/documents/domain/document_ocr.dart';
import '../features/documents/domain/document_repository.dart';
import '../features/documents/domain/image_picker_service.dart';
import '../features/entitlements/entitlement_service.dart';
import '../features/entitlements/local_pro_entitlement.dart';
import '../features/reminders/reminder_coordinator.dart';
import '../features/subscriptions/data/detected_subscription_repository.dart';
import '../features/subscriptions/data/in_memory_subscription_repository.dart';
import '../features/subscriptions/domain/subscription_discovery_service.dart';
import '../features/subscriptions/domain/subscription_repository.dart';

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
    required this.entitlements,
    required this.writes,
    required this.appLock,
    required this.localPro,
    required this.ads,
    required this.csvFiles,
    required this.discovery,
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
  final EntitlementService entitlements;
  final RegistryWrites writes;
  final AppLockController appLock;
  final LocalProEntitlement localPro;
  final AdsController ads;
  final CsvFileGateway csvFiles;
  final SubscriptionDiscoveryService discovery;

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
        backupFiles != oldWidget.backupFiles ||
        entitlements != oldWidget.entitlements ||
        writes != oldWidget.writes ||
        appLock != oldWidget.appLock ||
        localPro != oldWidget.localPro ||
        ads != oldWidget.ads ||
        csvFiles != oldWidget.csvFiles ||
        discovery != oldWidget.discovery;
  }
}

DetectedSubscriptionRepository createDefaultDetectedSubscriptionRepository() {
  return InMemoryDetectedSubscriptionRepository();
}

SubscriptionDiscoveryService createDefaultDiscoveryService(
  DetectedSubscriptionRepository detected,
  SubscriptionRepository subscriptions,
) {
  return SubscriptionDiscoveryService(
    detectedRepository: detected,
    subscriptionRepository: subscriptions,
  );
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
  return const DisabledDocumentOcrService();
}
