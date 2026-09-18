import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
import 'package:the_registry/features/documents/domain/document_icons.dart';
import 'package:the_registry/features/documents/domain/document_status.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/presentation/document_copy.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class DocumentListCard extends StatelessWidget {
  const DocumentListCard({super.key, required this.document, this.onTap});

  final RegistryDocument document;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColors = AppStatusColors.of(context);
    final locale = l10n.localeName;
    final actionDate = RegistryDateFormatter.dayMonthYear(
      document.displayActionDate,
      locale,
    );
    final expiryDate = RegistryDateFormatter.dayMonthYear(
      document.expiryDate,
      locale,
    );
    final registryStatus = DocumentStatus.resolve(document);
    final accent = switch (registryStatus) {
      RegistryStatus.urgent => statusColors.urgent,
      RegistryStatus.upcoming => statusColors.warning,
      RegistryStatus.active => statusColors.success,
      RegistryStatus.expired => statusColors.expired,
    };

    return RegistrySurface(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardBorder,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: AppRadius.cardBorder,
              border: BorderDirectional(
                start: BorderSide(color: accent, width: 3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RegistryIconBadge(
                    icon: DocumentIcons.forCategory(document.category),
                    background: colorScheme.primaryContainer,
                    foreground: colorScheme.onPrimaryContainer,
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
                        if (document.ownerName != null &&
                            document.ownerName!.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            document.ownerName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
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
                          Semantics(
                            label: l10n.maskedDocumentNumberLabel(
                              document.maskedDocumentNumber,
                            ),
                            child: Text(
                              document.maskedDocumentNumber,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            RegistryStatusChip(
                              status: registryStatus,
                              label: DocumentStatus.label(l10n, registryStatus),
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
          ),
        ),
      ),
    );
  }
}
