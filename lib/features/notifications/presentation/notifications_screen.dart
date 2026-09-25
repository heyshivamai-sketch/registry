import 'package:flutter/material.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
import 'package:the_registry/features/reminders/domain/local_reminder_scheduler.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reminders = RegistryDependencies.of(context).reminders;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsTitle)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: reminders,
          builder: (context, _) {
            final report = reminders.report;
            final permission = reminders.permission;
            final summary = _summary(l10n, permission, report);
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                RegistrySurface(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary,
                        key: const ValueKey<String>('notifications-summary'),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (report.schedulingAvailable &&
                          permission == ReminderPermission.granted &&
                          report.omittedIds.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.notificationsOmittedCount(
                            report.omittedIds.length,
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.notificationsLimits,
                  key: const ValueKey<String>('notifications-limits'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (reminders.ready &&
                    report.schedulingAvailable &&
                    permission != ReminderPermission.granted) ...[
                  const SizedBox(height: AppSpacing.lg),
                  RegistryPrimaryButton(
                    key: const ValueKey<String>('notifications-allow'),
                    label: reminders.shouldOpenNotificationSettings
                        ? l10n.notificationsOpenSettings
                        : l10n.notificationsAllow,
                    onPressed: reminders.enableNotifications,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  String _summary(
    AppLocalizations l10n,
    ReminderPermission permission,
    ReminderSyncReport report,
  ) {
    if (!report.schedulingAvailable ||
        permission == ReminderPermission.unavailable) {
      return l10n.notificationsUnavailable;
    }
    if (permission != ReminderPermission.granted) {
      return l10n.notificationsPermissionOff;
    }
    return l10n.notificationsScheduledCount(report.scheduledIds.length);
  }
}
