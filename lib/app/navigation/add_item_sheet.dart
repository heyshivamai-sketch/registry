import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/l10n/app_localizations.dart';

abstract final class AddItemSheet {
  static Future<void> show(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.screenPadding,
            0,
            AppSpacing.screenPadding,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.addSheetTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                l10n.addSheetSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                key: const ValueKey<String>('add-document'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: Text(l10n.addDocument),
                minVerticalPadding: AppSpacing.md,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  AppRoutes.openAddDocument(context);
                },
              ),
              ListTile(
                key: const ValueKey<String>('add-subscription'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.subscriptions_outlined),
                title: Text(l10n.addSubscription),
                minVerticalPadding: AppSpacing.md,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  AppRoutes.openAddSubscription(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
