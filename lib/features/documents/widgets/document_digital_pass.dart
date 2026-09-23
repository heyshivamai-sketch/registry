import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_shadows.dart';
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
    final locale = l10n.localeName;
    final status = DocumentStatus.resolve(document);
    final category = DocumentCopy.category(l10n, document.category);
    final country = DocumentCopy.country(l10n, document.countryCode);
    final onHero = Colors.white;
    final expiry = RegistryDateFormatter.dayMonthYear(
      document.expiryDate,
      locale,
    );

    final content = Padding(
      padding: EdgeInsets.all(compact ? 14 : (large ? 19 : 17)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RegistryIconBadge(
                icon: DocumentIcons.forCategory(document.category),
                size: 43,
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
          SizedBox(height: compact ? 12 : 20),
          Wrap(
            spacing: 6,
            children: [
              Text(
                country,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFAEB9DB),
                  letterSpacing: 1.4,
                  fontSize: 10,
                ),
              ),
              Text(
                '·',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFAEB9DB),
                ),
              ),
              Text(
                category,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFAEB9DB),
                  letterSpacing: 1.4,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            document.name,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: onHero,
              fontSize: 24,
              height: 1.15,
            ),
          ),
          if (_present(document.ownerName)) ...[
            const SizedBox(height: 3),
            Text(
              document.ownerName!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFFCCD3EB),
                fontSize: 12,
              ),
            ),
          ],
          if (showExpiry) ...[
            SizedBox(height: compact ? 16 : 26),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                if (document.maskedDocumentNumber.isNotEmpty)
                  Semantics(
                    label: l10n.maskedDocumentNumberLabel(
                      document.maskedDocumentNumber,
                    ),
                    child: Text(
                      document.maskedDocumentNumber,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: onHero,
                        letterSpacing: 1.6,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                if (document.hasDistinctActionDate)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l10n.pulseStartByEyebrow,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFAEB9DB),
                          letterSpacing: 0.8,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        RegistryDateFormatter.dayMonthYear(
                          document.displayActionDate,
                          locale,
                        ),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: onHero,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.pulseExpiresEyebrow,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFFAEB9DB),
                        letterSpacing: 0.8,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      expiry,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: onHero,
                        fontSize: 13,
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
            colors: [const Color(0xFF141D43), const Color(0xFF283E79)],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.passRadius),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -40,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF7F74FF).withValues(alpha: 0.55),
                          const Color(0xFF7F74FF).withValues(alpha: 0),
                        ],
                      ),
                    ),
                    child: const SizedBox(width: 200, height: 200),
                  ),
                ),
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

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: pass,
    );
  }

  bool _present(String? value) => value != null && value.trim().isNotEmpty;
}
