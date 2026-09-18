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

class DocumentDigitalPass extends StatelessWidget {
  const DocumentDigitalPass({
    super.key,
    required this.document,
    this.onTap,
    this.showExpiry = true,
  });

  final RegistryDocument document;
  final VoidCallback? onTap;
  final bool showExpiry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final brand = AppBrandColors.of(context);
    final locale = l10n.localeName;
    final status = DocumentStatus.resolve(document);
    final category = DocumentCopy.category(l10n, document.category);
    final issuer = document.issuingAuthority?.trim();
    final onHero = Colors.white;
    final expiry = RegistryDateFormatter.dayMonthYear(
      document.expiryDate,
      locale,
    );

    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RegistryIconBadge(
                icon: DocumentIcons.forCategory(document.category),
                background: onHero.withValues(alpha: 0.14),
                foreground: onHero,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RegistryStatusChip(
                      status: status,
                      label: DocumentStatus.label(l10n, status),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      category,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: onHero.withValues(alpha: 0.78),
                        letterSpacing: 1.1,
                      ),
                    ),
                    if (issuer != null && issuer.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        issuer,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: onHero.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      document.name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: onHero,
                        fontSize: 26,
                      ),
                    ),
                    if (_present(document.ownerName)) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        document.ownerName!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: onHero.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (document.hasAttachment)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.xs,
                  ),
                  child: Semantics(
                    label: l10n.hasAttachment,
                    child: Icon(
                      Icons.photo_outlined,
                      color: onHero.withValues(alpha: 0.86),
                      size: AppSpacing.iconMd,
                    ),
                  ),
                ),
            ],
          ),
          if (document.maskedDocumentNumber.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Semantics(
              label: l10n.maskedDocumentNumberLabel(
                document.maskedDocumentNumber,
              ),
              child: Text(
                document.maskedDocumentNumber,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: onHero,
                  letterSpacing: 1.6,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
          if (showExpiry) ...[
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final expiryCell = _PassDateCell(
                  eyebrow: l10n.pulseExpiresEyebrow,
                  value: expiry,
                  onHero: onHero,
                );
                if (!document.hasDistinctActionDate) {
                  return expiryCell;
                }
                final startCell = _PassDateCell(
                  eyebrow: l10n.pulseStartByEyebrow,
                  value: RegistryDateFormatter.dayMonthYear(
                    document.displayActionDate,
                    locale,
                  ),
                  onHero: onHero,
                );
                if (constraints.maxWidth < 280) {
                  return Column(
                    children: [
                      SizedBox(width: double.infinity, child: startCell),
                      const SizedBox(height: AppSpacing.xs),
                      SizedBox(width: double.infinity, child: expiryCell),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: startCell),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(child: expiryCell),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );

    final pass = Semantics(
      container: true,
      button: onTap != null,
      label: l10n.documentPassLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.xlBorder,
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [
              brand.heroStart,
              Color.lerp(brand.heroEnd, brand.indigo, 0.28)!,
            ],
          ),
        ),
        child: content,
      ),
    );

    if (onTap == null) {
      return pass;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: pass,
    );
  }

  bool _present(String? value) => value != null && value.trim().isNotEmpty;
}

class _PassDateCell extends StatelessWidget {
  const _PassDateCell({
    required this.eyebrow,
    required this.value,
    required this.onHero,
  });

  final String eyebrow;
  final String value;
  final Color onHero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: onHero.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: onHero.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: theme.textTheme.labelSmall?.copyWith(
                color: onHero.withValues(alpha: 0.72),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(color: onHero),
            ),
          ],
        ),
      ),
    );
  }
}
