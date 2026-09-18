import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_shadows.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
import 'package:the_registry/features/documents/domain/document_icons.dart';
import 'package:the_registry/features/documents/domain/document_status.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
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
    final accent = registryStatus.accent(statusColors);
    final fill = registryStatus == RegistryStatus.urgent
        ? const Color(0xFFFFF8F7)
        : colorScheme.surfaceContainerLowest;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: AppShadows.card(context),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardBorder,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.cardBorder,
              border: BorderDirectional(
                start: BorderSide(color: accent, width: 3),
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.minTapTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    RegistryIconBadge(
                      icon: DocumentIcons.forCategory(document.category),
                      size: 43,
                      background: const Color(0xFFF0EFFF),
                      foreground: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            document.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            document.hasDistinctActionDate
                                ? l10n.startByDate(actionDate)
                                : l10n.expiresDate(expiryDate),
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              RegistryStatusChip(
                                status: registryStatus,
                                label: DocumentStatus.label(
                                  l10n,
                                  registryStatus,
                                ),
                                compact: true,
                              ),
                              if (document.hasAttachment)
                                Semantics(
                                  label: l10n.hasAttachment,
                                  child: Icon(
                                    Icons.attach_file_rounded,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        color: const Color(0xFF737B91),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
