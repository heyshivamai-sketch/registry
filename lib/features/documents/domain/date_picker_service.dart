import 'package:flutter/material.dart';

abstract class DatePickerService {
  Future<DateTime?> pickDate(
    BuildContext context, {
    required String fieldId,
    DateTime? initialDate,
  });
}

class MaterialDatePickerService implements DatePickerService {
  const MaterialDatePickerService();

  @override
  Future<DateTime?> pickDate(
    BuildContext context, {
    required String fieldId,
    DateTime? initialDate,
  }) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(now.year - 40),
      lastDate: DateTime(now.year + 40),
    );
  }
}
