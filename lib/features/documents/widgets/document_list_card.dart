import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
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
    final status = AppStatusColors.of(context);
    final locale = l10n.localeName;
    final actionDate = RegistryDateFormatter.dayMonthYear(
      document.displayActionDate,
      locale,
    );
    final expiryDate = RegistryDateFormatter.dayMonthYear(
      document.expiryDate,
      locale,
    );
    final registryStatus = _statusFor(document.impact);
    final accent = switch (registryStatus) {
      RegistryStatus.urgent => status.urgent,
      RegistryStatus.upcoming => status.warning,
      RegistryStatus.active => status.success,
      RegistryStatus.expired => status.expired,
    };

    return RegistrySurface(
      padding: EdgeInsets.zero,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: AppRadius.cardBorder,
          border: BorderDirectional(start: BorderSide(color: accent, width: 3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RegistryIconBadge(
                icon: _iconFor(document.category),
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
                      Text(
                        document.maskedDocumentNumber,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
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

  IconData _iconFor(DocumentCategory category) {
    return switch (category) {
      DocumentCategory.passport => Icons.badge_outlined,
      DocumentCategory.idCard => Icons.badge_outlined,
      DocumentCategory.drivingLicence => Icons.credit_card_outlined,
      DocumentCategory.insurance => Icons.health_and_safety_outlined,
      DocumentCategory.visaResidence => Icons.flight_takeoff_outlined,
      DocumentCategory.certificate => Icons.workspace_premium_outlined,
      DocumentCategory.warranty => Icons.verified_outlined,
      DocumentCategory.other => Icons.description_outlined,
    };
  }
}
