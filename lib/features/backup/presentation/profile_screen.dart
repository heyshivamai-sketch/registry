import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/core/widgets/registry_section_header.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.embedded = false});

  final bool embedded;

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
                  onPressed: () => AppRoutes.openImportBackup(context),
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
