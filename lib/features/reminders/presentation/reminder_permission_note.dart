import 'package:flutter/material.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/features/reminders/domain/local_reminder_scheduler.dart';
import 'package:the_registry/l10n/app_localizations.dart';

/// Shown when reminder choices are selected but notifications are not allowed.
/// Saving stays available.
class ReminderPermissionNote extends StatelessWidget {
  const ReminderPermissionNote({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }
    final reminders = RegistryDependencies.of(context).reminders;
    return ListenableBuilder(
      listenable: reminders,
      builder: (context, _) {
        final permission = reminders.permission;
        if (permission != ReminderPermission.denied &&
            permission != ReminderPermission.unavailable) {
          return const SizedBox.shrink();
        }
        final l10n = AppLocalizations.of(context);
        final theme = Theme.of(context);
        final unavailable = permission == ReminderPermission.unavailable;
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                unavailable
                    ? l10n.reminderStatusUnavailable
                    : l10n.reminderPermissionDenied,
                key: const ValueKey<String>('reminder-permission-note'),
                style: theme.textTheme.bodySmall,
              ),
              if (!unavailable)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    key: const ValueKey<String>('reminder-permission-request'),
                    onPressed: reminders.enableNotifications,
                    child: Text(
                      reminders.shouldOpenNotificationSettings
                          ? l10n.notificationsOpenSettings
                          : l10n.notificationsAllow,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
