import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_bottom_sheet_action.dart';
import 'package:the_registry/l10n/app_localizations.dart';

abstract final class AddItemSheet {
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onDocumentSaved,
  }) {
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
              RegistryBottomSheetAction(
                key: const ValueKey<String>('add-document'),
                icon: Icons.description_outlined,
                title: l10n.addDocument,
                subtitle: l10n.addSheetDocumentSubtitle,
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final saved = await AppRoutes.openAddDocument(context);
                  if (saved) {
                    onDocumentSaved?.call();
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              RegistryBottomSheetAction(
                key: const ValueKey<String>('add-subscription'),
                icon: Icons.subscriptions_outlined,
                title: l10n.addSubscription,
                subtitle: l10n.addSheetSubscriptionSubtitle,
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
