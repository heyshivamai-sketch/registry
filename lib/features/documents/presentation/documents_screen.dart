import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_empty_state.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/core/widgets/registry_search_field.dart';
import 'package:the_registry/core/widgets/registry_section_header.dart';
import 'package:the_registry/core/widgets/registry_selectable_chip.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
import 'package:the_registry/features/documents/domain/document_status.dart';
import 'package:the_registry/features/documents/domain/document_wallet.dart';
import 'package:the_registry/features/documents/widgets/document_digital_pass.dart';
import 'package:the_registry/features/documents/widgets/document_list_card.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  DocumentWalletFilter _filter = DocumentWalletFilter.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final documents = RegistryDependencies.of(context).documents;

    return SafeArea(
      child: ListenableBuilder(
        listenable: documents,
        builder: (context, _) {
          final items = documents.documents;
          final query = _searchController.text;
          final visible = DocumentWallet.visible(
            items,
            query: query,
            filter: _filter,
            l10n: l10n,
          );
          final featured = DocumentWallet.featured(visible);
          final remaining = DocumentWallet.remaining(
            visible,
            featuredDocument: featured,
          );
          final attentionCount = DocumentStatus.attentionCount(items);

          return ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.screenPadding,
              AppSpacing.screenPadding,
              AppSpacing.screenPadding,
              AppSpacing.scrollDockClearance,
            ),
            children: [
              _DocumentsHeader(
                savedCount: items.length,
                attentionCount: attentionCount,
              ),
              const SizedBox(height: AppSpacing.sm),
              RegistryAuraSearchField(
                controller: _searchController,
                hintText: l10n.documentsSearchPlaceholder,
                fieldKey: const ValueKey<String>('documents-search'),
                clearKey: const ValueKey<String>('documents-search-clear'),
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _DocumentsFilters(
                  selected: _filter,
                  onSelected: (filter) => setState(() => _filter = filter),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              if (items.isEmpty)
                RegistryEmptyState(
                  key: const ValueKey<String>('documents-empty'),
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
              else if (visible.isEmpty)
                RegistryEmptyState(
                  key: const ValueKey<String>('documents-filter-empty'),
                  title: query.trim().isEmpty
                      ? l10n.documentsFilterEmptyTitle
                      : l10n.documentsSearchEmptyTitle,
                  message: query.trim().isEmpty
                      ? l10n.documentsFilterEmptyMessage
                      : l10n.documentsSearchEmptyMessage,
                  icon: Icons.search_off_rounded,
                )
              else ...[
                if (featured != null) ...[
                  DocumentDigitalPass(
                    key: const ValueKey<String>('featured-document-pass'),
                    document: featured,
                    onTap: () =>
                        AppRoutes.openDocumentDetail(context, featured.id),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (remaining.isNotEmpty) ...[
                  RegistryAuraSectionHeader(
                    title: l10n.documentsRemainingHeader,
                    count: remaining.length,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final document in remaining) ...[
                    DocumentListCard(
                      key: ValueKey<String>(document.id),
                      document: document,
                      onTap: () =>
                          AppRoutes.openDocumentDetail(context, document.id),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ],
              if (items.isNotEmpty) ...[
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

class _DocumentsHeader extends StatelessWidget {
  const _DocumentsHeader({
    required this.savedCount,
    required this.attentionCount,
  });

  final int savedCount;
  final int attentionCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.documentsEyebrow,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.tertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(l10n.documentsTitle, style: theme.textTheme.headlineMedium),
        if (savedCount > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          RegistrySurface(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                Text(
                  l10n.documentsSummary(savedCount),
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  l10n.documentsAttentionSummary(attentionCount),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DocumentsFilters extends StatelessWidget {
  const _DocumentsFilters({required this.selected, required this.onSelected});

  final DocumentWalletFilter selected;
  final ValueChanged<DocumentWalletFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filters = <(DocumentWalletFilter, String, Key)>[
      (
        DocumentWalletFilter.all,
        l10n.documentsFilterAll,
        const ValueKey<String>('filter-all'),
      ),
      (
        DocumentWalletFilter.actionNeeded,
        l10n.actionNeeded,
        const ValueKey<String>('filter-action'),
      ),
      (
        DocumentWalletFilter.upcoming,
        l10n.statusUpcoming,
        const ValueKey<String>('filter-upcoming'),
      ),
      (
        DocumentWalletFilter.active,
        l10n.statusActive,
        const ValueKey<String>('filter-active'),
      ),
      (
        DocumentWalletFilter.overdue,
        l10n.statusOverdue,
        const ValueKey<String>('filter-overdue'),
      ),
    ];

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final filter in filters)
          RegistrySelectableChip(
            key: filter.$3,
            label: filter.$2,
            selected: selected == filter.$1,
            onSelected: (_) => onSelected(filter.$1),
          ),
      ],
    );
  }
}
