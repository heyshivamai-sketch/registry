import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_empty_state.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
import 'package:the_registry/features/documents/domain/document_status.dart';
import 'package:the_registry/features/documents/widgets/document_list_card.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final documents = RegistryDependencies.of(context).documents;

    return SafeArea(
      child: ListenableBuilder(
        listenable: documents,
        builder: (context, _) {
          final items = documents.documents;
          final attentionCount = DocumentStatus.attentionCount(items);

          return ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.screenPadding,
              AppSpacing.screenPadding,
              AppSpacing.screenPadding,
              AppSpacing.scrollFabClearance,
            ),
            children: [
              Text(
                l10n.documentsTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              if (items.isEmpty)
                RegistryEmptyState(
                  title: l10n.documentsEmptyTitle,
                  message: l10n.documentsEmptyMessage,
                  illustration: const RegistryDocumentIllustration(),
                  action: SizedBox(
                    width: double.infinity,
                    child: RegistryPrimaryButton(
                      key: const ValueKey<String>('documents-add'),
                      label: l10n.addDocument,
                      onPressed: () => AppRoutes.openAddDocument(context),
                    ),
                  ),
                )
              else ...[
                RegistrySurface(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.xs,
                    children: [
                      Text(
                        l10n.documentsSummary(items.length),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        l10n.documentsAttentionSummary(attentionCount),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final document in items) ...[
                  DocumentListCard(
                    key: ValueKey<String>(document.id),
                    document: document,
                    onTap: () =>
                        AppRoutes.openDocumentDetail(context, document.id),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: RegistryPrimaryButton(
                    key: const ValueKey<String>('documents-add'),
                    label: l10n.addDocument,
                    onPressed: () => AppRoutes.openAddDocument(context),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
