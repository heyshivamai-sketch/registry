import 'package:flutter/material.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/documents/data/image_picker_image_service.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/documents/data/ml_kit_document_ocr_service.dart';
import 'package:the_registry/features/documents/domain/date_picker_service.dart';
import 'package:the_registry/features/documents/domain/document_ocr.dart';
import 'package:the_registry/features/documents/domain/document_repository.dart';
import 'package:the_registry/features/documents/domain/image_picker_service.dart';
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
    required super.child,
  });

  final DocumentRepository documents;
  final SubscriptionRepository subscriptions;
  final ImagePickerService imagePicker;
  final DatePickerService datePicker;
  final DocumentOcrService documentOcr;
  final Clock clock;

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
        clock != oldWidget.clock;
  }
}

DocumentRepository createDefaultDocumentRepository() {
  return InMemoryDocumentRepository();
}

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
