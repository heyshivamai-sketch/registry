import 'package:flutter/material.dart';
import 'package:the_registry/features/documents/domain/date_picker_service.dart';

class FakeDatePickerService implements DatePickerService {
  final Map<String, DateTime?> results = {};

  @override
  Future<DateTime?> pickDate(
    BuildContext context, {
    required String fieldId,
    DateTime? initialDate,
  }) async {
    return results[fieldId];
  }
}
