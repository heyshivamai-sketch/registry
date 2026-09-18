import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/theme/app_radius.dart';
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.screenPadding,
              AppSpacing.sm,
              AppSpacing.screenPadding,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.addSheetTitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.addSheetSubtitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                RegistryAuraBottomSheetAction(
                  key: const ValueKey<String>('add-document'),
                  icon: Icons.description_outlined,
                  title: l10n.typeDocument,
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
                RegistryAuraBottomSheetAction(
                  key: const ValueKey<String>('add-subscription'),
                  icon: Icons.subscriptions_outlined,
                  title: l10n.typeSubscription,
                  subtitle: l10n.addSheetSubscriptionSubtitle,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    AppRoutes.openAddSubscription(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
