import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_empty_state.dart';
import 'package:the_registry/core/widgets/registry_section_header.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
import 'package:the_registry/features/home/data/mock_registry_catalog.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/features/home/data/registry_item.dart';
import 'package:the_registry/l10n/app_localizations.dart';

/// Read-only Aura review for a Home catalog highlight.
///
/// Catalog items are not [DocumentRepository] records, so this screen does not
/// offer Edit, Delete, or Renew.
class CatalogItemDetailScreen extends StatelessWidget {
  const CatalogItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final item = MockRegistryCatalog.byId(itemId);

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.catalogReviewTitle)),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: RegistryEmptyState(
            key: const ValueKey<String>('catalog-item-unavailable'),
            title: l10n.documentUnavailableTitle,
            message: l10n.documentUnavailableMessage,
          ),
        ),
      );
    }

    return _CatalogItemDetailBody(item: item);
  }
}

class _CatalogItemDetailBody extends StatelessWidget {
  const _CatalogItemDetailBody({required this.item});

  final RegistryItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = l10n.localeName;
    final actionDate = RegistryDateFormatter.dayMonthYear(
      item.actionDate,
      locale,
    );
    final dueDate = RegistryDateFormatter.dayMonthYear(item.dueDate, locale);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.xs,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.catalogReviewEyebrow,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.tertiary,
              ),
            ),
            Text(l10n.catalogReviewTitle, style: theme.textTheme.titleLarge),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          key: const ValueKey<String>('catalog-item-detail'),
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.screenPadding,
            AppSpacing.sm,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RegistrySurface(
                padding: const EdgeInsets.all(14),
                borderRadius: BorderRadius.circular(19),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(item.icon, color: theme.colorScheme.primary),
                        RegistryAuraStatusPill(
                          status: item.status,
                          label: item.statusLabel(l10n),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      item.heroTitle(l10n),
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${item.title(l10n)} · ${item.typeLabel(l10n)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              RegistrySurface(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RegistrySectionHeader(title: l10n.documentInformation),
                    RegistryInfoRow(
                      label: l10n.fieldDocumentName,
                      value: item.title(l10n),
                    ),
                    RegistryInfoRow(
                      label: l10n.fieldDocumentType,
                      value: item.typeLabel(l10n),
                    ),
                    RegistryInfoRow(
                      label: l10n.documentStatusLabel,
                      value: item.statusLabel(l10n),
                    ),
                    RegistryInfoRow(
                      label: l10n.fieldActionDate,
                      value: actionDate,
                    ),
                    RegistryInfoRow(
                      label: item.type == RegistryItemType.subscription
                          ? l10n.catalogChargeDate
                          : l10n.fieldExpiryDate,
                      value: dueDate,
                    ),
                    RegistryInfoRow(
                      label: l10n.fieldImpact,
                      value: item.impactLabel(l10n),
                    ),
                    RegistryInfoRow(
                      label: l10n.catalogActionLabel,
                      value: item.actionLabel(l10n),
                    ),
                    RegistryInfoRow(
                      label: l10n.catalogRemainingLabel,
                      value: item.remainingLabel(l10n),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              RegistryCallout(
                tone: RegistryCalloutTone.tip,
                title: l10n.catalogNotInWalletTitle,
                message: l10n.catalogNotInWallet,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
