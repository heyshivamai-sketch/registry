import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/presentation/document_copy.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class DocumentListCard extends StatelessWidget {
  const DocumentListCard({super.key, required this.document});

  final RegistryDocument document;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locale = l10n.localeName;
    final actionDate = RegistryDateFormatter.dayMonthYear(
      document.displayActionDate,
      locale,
    );
    final expiryDate = RegistryDateFormatter.dayMonthYear(
      document.expiryDate,
      locale,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: SizedBox(
                width: AppSpacing.minTapTarget,
                height: AppSpacing.minTapTarget,
                child: Icon(
                  Icons.description_outlined,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DocumentCopy.category(l10n, document.category),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    document.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.startByDate(actionDate),
                    style: theme.textTheme.titleSmall,
                  ),
                  if (document.hasDistinctActionDate)
                    Text(
                      l10n.expiresDate(expiryDate),
                      style: theme.textTheme.bodySmall,
                    ),
                  if (document.maskedDocumentNumber.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      document.maskedDocumentNumber,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      RegistryStatusChip(
                        status: _statusFor(document.impact),
                        label: DocumentCopy.impact(l10n, document.impact),
                      ),
                      if (document.hasAttachment)
                        Semantics(
                          label: l10n.hasAttachment,
                          child: Icon(
                            Icons.attach_file_rounded,
                            size: AppSpacing.iconMd,
                            color: colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  RegistryStatus _statusFor(DocumentImpact impact) {
    return switch (impact) {
      DocumentImpact.critical || DocumentImpact.high => RegistryStatus.urgent,
      DocumentImpact.medium => RegistryStatus.upcoming,
      DocumentImpact.low => RegistryStatus.active,
    };
  }
}
