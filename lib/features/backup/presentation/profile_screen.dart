import 'dart:async';

import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/core/widgets/registry_section_header.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
import 'package:the_registry/features/app_lock/app_lock_controller.dart';
import 'package:the_registry/features/entitlements/registry_plan.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    this.embedded = false,
    this.onRegistryReplaced,
  });

  final bool embedded;

  /// Called after Import backup leaves the stack because a replace finished.
  final VoidCallback? onRegistryReplaced;

  Future<void> _openImport(BuildContext context) async {
    final replaced = await AppRoutes.openImportBackup(context);
    if (!replaced || !context.mounted) {
      return;
    }
    onRegistryReplaced?.call();
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.backupImportReplaced)));
  }

  Future<void> _openCharges(BuildContext context) async {
    final created = await AppRoutes.openImportCharges(context);
    if (created <= 0 || !context.mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.csvCreated(created))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final body = SafeArea(
      bottom: !embedded,
      child: ListView(
        padding: EdgeInsetsDirectional.fromSTEB(
          AppSpacing.screenPadding,
          embedded ? AppSpacing.pageTop : AppSpacing.screenPadding,
          AppSpacing.screenPadding,
          embedded
              ? AppSpacing.scrollClearanceForDock(context)
              : AppSpacing.screenPadding,
        ),
        children: [
          if (embedded)
            Text(l10n.profileTitle, style: theme.textTheme.headlineMedium),
          if (embedded) const SizedBox(height: AppSpacing.md),
          Text(l10n.profileMessage, style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.lg),
          RegistrySurface(
            key: const ValueKey<String>('backup-section'),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RegistrySectionHeader(
                  title: l10n.backupSectionTitle,
                  icon: Icons.lock_outline,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.backupSectionBody, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.md),
                RegistryPrimaryButton(
                  key: const ValueKey<String>('backup-export'),
                  label: l10n.backupExportAction,
                  onPressed: () => AppRoutes.openExportBackup(context),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  key: const ValueKey<String>('backup-import'),
                  onPressed: () => unawaited(_openImport(context)),
                  child: Text(
                    l10n.backupImportAction,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _AppLockSection(),
          const SizedBox(height: AppSpacing.md),
          RegistrySurface(
            key: const ValueKey<String>('local-pro-section'),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RegistrySectionHeader(
                  title: l10n.localProTitle,
                  icon: Icons.workspace_premium_outlined,
                ),
                const SizedBox(height: AppSpacing.sm),
                ListenableBuilder(
                  listenable: RegistryDependencies.of(context).entitlements,
                  builder: (context, _) {
                    final plan = RegistryDependencies.of(
                      context,
                    ).entitlements.plan;
                    return Text(
                      plan == RegistryPlan.localPro
                          ? l10n.localProCurrentPro
                          : l10n.profilePlanFree,
                      style: theme.textTheme.bodyMedium,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  key: const ValueKey<String>('local-pro-open'),
                  onPressed: () => AppRoutes.openLocalPro(context),
                  child: Text(l10n.localProAction, textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          RegistrySurface(
            key: const ValueKey<String>('csv-import-section'),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RegistrySectionHeader(
                  title: l10n.csvImportTitle,
                  icon: Icons.table_chart_outlined,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.csvImportIntro, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  key: const ValueKey<String>('csv-import-open'),
                  onPressed: () => unawaited(_openCharges(context)),
                  child: Text(
                    l10n.csvImportAction,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (embedded) {
      return body;
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: body,
    );
  }
}

class _AppLockSection extends StatelessWidget {
  const _AppLockSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lock = RegistryDependencies.of(context).appLock;
    return RegistrySurface(
      key: const ValueKey<String>('app-lock-section'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: ListenableBuilder(
        listenable: lock,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RegistrySectionHeader(
                title: l10n.appLockSectionTitle,
                icon: Icons.phonelink_lock_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.appLockSectionBody, style: theme.textTheme.bodyMedium),
              SwitchListTile(
                key: const ValueKey<String>('app-lock-switch'),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  lock.enabled ? l10n.appLockEnabled : l10n.appLockDisabled,
                ),
                value: lock.enabled,
                onChanged: lock.authenticating
                    ? null
                    : (value) => unawaited(_change(context, lock, value)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _change(
    BuildContext context,
    AppLockController lock,
    bool enabled,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (!enabled) {
      final result = await lock.disable(
        localizedReason: l10n.appLockDisableReason,
      );
      if (!context.mounted || result == AppLockDisableResult.disabled) {
        return;
      }
      _showLockMessage(context, _disableMessage(l10n, result));
      return;
    }
    final result = await lock.enable(localizedReason: l10n.appLockEnableReason);
    if (!context.mounted || result == AppLockEnableResult.enabled) {
      return;
    }
    _showLockMessage(context, _enableMessage(l10n, result));
  }

  void _showLockMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _enableMessage(AppLocalizations l10n, AppLockEnableResult result) {
    return switch (result) {
      AppLockEnableResult.unavailable => l10n.appLockUnavailable,
      AppLockEnableResult.cancelled => l10n.appLockCancelled,
      AppLockEnableResult.failed => l10n.appLockFailed,
      AppLockEnableResult.platformError => l10n.appLockPlatformError,
      AppLockEnableResult.enabled => l10n.appLockEnabled,
    };
  }

  String _disableMessage(AppLocalizations l10n, AppLockDisableResult result) {
    return switch (result) {
      AppLockDisableResult.cancelled => l10n.appLockDisableCancelled,
      AppLockDisableResult.failed => l10n.appLockDisableFailed,
      AppLockDisableResult.unavailable => l10n.appLockDisableUnavailable,
      AppLockDisableResult.platformError => l10n.appLockPlatformError,
      AppLockDisableResult.disabled => l10n.appLockDisabled,
    };
  }
}
