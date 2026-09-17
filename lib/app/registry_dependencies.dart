import 'package:flutter/material.dart';
import 'package:the_registry/features/documents/data/image_picker_image_service.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/documents/domain/date_picker_service.dart';
import 'package:the_registry/features/documents/domain/document_repository.dart';
import 'package:the_registry/features/documents/domain/image_picker_service.dart';

class RegistryDependencies extends InheritedWidget {
  const RegistryDependencies({
    super.key,
    required this.documents,
    required this.imagePicker,
    required this.datePicker,
    required super.child,
  });

  final DocumentRepository documents;
  final ImagePickerService imagePicker;
  final DatePickerService datePicker;

  static RegistryDependencies of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<RegistryDependencies>();
    assert(scope != null, 'RegistryDependencies not found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(RegistryDependencies oldWidget) {
    return documents != oldWidget.documents ||
        imagePicker != oldWidget.imagePicker ||
        datePicker != oldWidget.datePicker;
  }
}

DocumentRepository createDefaultDocumentRepository() {
  return InMemoryDocumentRepository();
}

ImagePickerService createDefaultImagePicker() {
  return ImagePickerImageService();
}

DatePickerService createDefaultDatePicker() {
  return const MaterialDatePickerService();
}
