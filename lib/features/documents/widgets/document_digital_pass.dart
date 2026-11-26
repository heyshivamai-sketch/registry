import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_shadows.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/paper_wallet_engraving.dart';
import '../../../core/widgets/registry_status_chip.dart';
import '../../../core/widgets/registry_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/registry_date_formatter.dart';
import '../domain/document_icons.dart';
import '../domain/document_status.dart';
import '../domain/registry_document.dart';
import '../presentation/document_copy.dart';

class DocumentDigitalPass extends StatelessWidget {
  const DocumentDigitalPass({
    super.key,
    required this.document,
    this.onTap,
    this.showExpiry = true,
    this.large = false,
    this.compact = false,
  });

  final RegistryDocument document;
  final VoidCallback? onTap;
  final bool showExpiry;
  final bool large;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final brand = AppBrandColors.of(context);
    final locale = l10n.localeName;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final status = DocumentStatus.resolve(document);
    final category = DocumentCopy.category(l10n, document.category);
    final country = DocumentCopy.country(l10n, document.countryCode);
    const onHero = Colors.white;
    const subtleInk = Color(0xFFC8CFE8);
    final expiry = RegistryDateFormatter.dayMonthYear(document.expiryDate, locale);

    final content = Padding(
      padding: EdgeInsets.all(compact ? 16 : (large ? 20 : 18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RegistryIconBadge(
                icon: DocumentIcons.forCategory(document.category),
                size: 42,
                background: onHero.withValues(alpha: 0.14),
                foreground: onHero,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: RegistryStatusChip(
                    status: status,
                    label: DocumentStatus.label(l10n, status),
                    onDark: true,
                    compact: true,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 14 : 20),
          Wrap(
            spacing: 6,
            children: [
              Text(
                country.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: subtleInk,
                  letterSpacing: isRtl ? 0 : 1.1,
                  fontSize: 10,
                ),
              ),
              Text('·', style: theme.textTheme.labelSmall?.copyWith(color: subtleInk)),
              Text(
                category.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: subtleInk,
                  letterSpacing: isRtl ? 0 : 1.1,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            document.name,
            style: AppTypography.serif(
              context,
              fontSize: compact ? 22 : 25,
              height: 1.15,
              color: onHero,
            ),
          ),
          if (_present(document.ownerName)) ...[
            const SizedBox(height: 4),
            Text(
              document.ownerName!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFFDCE1F4),
                fontSize: 12.5,
              ),
            ),
          ],
          if (showExpiry && document.hasExpiry) ...[
            SizedBox(height: compact ? 16 : 24),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                if (document.maskedDocumentNumber.isNotEmpty)
                  Semantics(
                    label: l10n.maskedDocumentNumberLabel(document.maskedDocumentNumber),
                    child: Text(
                      document.maskedDocumentNumber,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: onHero,
                        letterSpacing: 1.4,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                if (document.hasDistinctActionDate)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l10n.pulseStartByEyebrow.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: subtleInk,
                          letterSpacing: isRtl ? 0 : 0.8,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        RegistryDateFormatter.dayMonthYear(document.displayActionDate, locale),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: onHero,
                          fontSize: 13,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.pulseExpiresEyebrow.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: subtleInk,
                        letterSpacing: isRtl ? 0 : 0.8,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      expiry,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: onHero,
                        fontSize: 13,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
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
          borderRadius: BorderRadius.circular(AppSpacing.passRadius),
          boxShadow: AppShadows.pulse(context),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [brand.heroStart, brand.heroEnd],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.passRadius),
          child: Stack(
            children: [
              const Positioned.fill(
                child: PaperWalletEngraving(opacity: 0.14),
              ),
              content,
            ],
          ),
        ),
      ),
    );

    if (onTap == null) {
      return pass;
    }

    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: pass);
  }

  bool _present(String? value) => value != null && value.trim().isNotEmpty;
}
