import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/features/reminders/reminder_coordinator.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class ReminderStatusLine extends StatelessWidget {
  const ReminderStatusLine({super.key, required this.status});

  final ReminderUiStatus status;

  @override
  Widget build(BuildContext context) {
    final message = _message(AppLocalizations.of(context), status);
    if (message == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        message,
        key: const ValueKey<String>('reminder-status'),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  String? _message(AppLocalizations l10n, ReminderUiStatus status) {
    return switch (status) {
      ReminderUiStatus.none || ReminderUiStatus.pending => null,
      ReminderUiStatus.scheduled => l10n.reminderStatusScheduled,
      ReminderUiStatus.permissionOff => l10n.reminderStatusPermissionOff,
      ReminderUiStatus.past => l10n.reminderStatusPast,
      ReminderUiStatus.limited => l10n.reminderStatusLimited,
      ReminderUiStatus.cancelled => l10n.reminderStatusCancelled,
      ReminderUiStatus.unavailable => l10n.reminderStatusUnavailable,
    };
  }
}
