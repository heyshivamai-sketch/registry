import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_empty_state.dart';
import 'package:the_registry/features/home/data/coming_up_grouping.dart';
import 'package:the_registry/features/home/data/mock_registry_catalog.dart';
import 'package:the_registry/features/home/data/registry_item.dart';
import 'package:the_registry/features/home/data/registry_read_model.dart';
import 'package:the_registry/features/home/widgets/home_attention_card.dart';
import 'package:the_registry/features/home/widgets/home_first_visit.dart';
import 'package:the_registry/features/home/widgets/home_header.dart';
import 'package:the_registry/features/home/widgets/home_metrics_row.dart';
import 'package:the_registry/features/home/widgets/home_search_field.dart';
import 'package:the_registry/features/home/widgets/home_upcoming_item.dart';
import 'package:the_registry/features/home/widgets/priority_hero_card.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_estimate.dart';
import 'package:the_registry/l10n/app_localizations.dart';

enum ComingUpFilter { all, documents, subscriptions }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  ComingUpFilter _comingUpFilter = ComingUpFilter.all;

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
    final deps = RegistryDependencies.of(context);
    final now = deps.clock.now();

    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([deps.documents, deps.subscriptions]),
        builder: (context, _) {
          final documents = deps.documents.documents;
          final subscriptions = deps.subscriptions.subscriptions;
          final isFirstVisit = documents.isEmpty && subscriptions.isEmpty;
          final allItems = RegistryReadModel.fromRepositories(
            documents: documents,
            subscriptions: subscriptions,
            l10n: l10n,
            now: now,
          );
          final visible = MockRegistryCatalog.byImpact(
            allItems.where(
              (item) => MockRegistryCatalog.matches(
                item,
                _searchController.text,
                l10n,
              ),
            ),
          );
          final searching = _searchController.text.trim().isNotEmpty;
          final hero = RegistryReadModel.pulseItem(visible);
          final attention = RegistryReadModel.attentionItems(visible);
          final comingUp = RegistryReadModel.horizonItems(visible, now: now);
          final filteredComingUp = switch (_comingUpFilter) {
            ComingUpFilter.all => comingUp,
            ComingUpFilter.documents =>
              comingUp
                  .where((item) => item.type == RegistryItemType.document)
                  .toList(),
            ComingUpFilter.subscriptions =>
              comingUp
                  .where((item) => item.type == RegistryItemType.subscription)
                  .toList(),
          };
          final homeComingUp = filteredComingUp.take(4).toList();
          final groups = ComingUpGrouping.group(
            items: homeComingUp,
            now: now,
            locale: l10n.localeName,
            l10n: l10n,
          );
          final totals = SubscriptionEstimate.monthlyTotals(subscriptions);

          return ListView(
            padding: EdgeInsetsDirectional.fromSTEB(
              AppSpacing.screenPadding,
              AppSpacing.pageTop,
              AppSpacing.screenPadding,
              AppSpacing.scrollClearanceForDock(this.context),
            ),
            children: [
              const HomeHeader(),
              const SizedBox(height: AppSpacing.sm),
              HomeSearchField(controller: _searchController),
              const SizedBox(height: AppSpacing.md),
              if (searching && visible.isEmpty)
                RegistryEmptyState(
                  key: const ValueKey<String>('home-search-empty'),
                  title: l10n.searchNoResultsTitle,
                  message: l10n.searchNoResultsMessage,
                  icon: Icons.search_off_rounded,
                )
              else if (isFirstVisit && !searching)
                const HomeFirstVisit()
              else ...[
                PriorityHeroCard(
                  key: const ValueKey<String>('home-hero'),
                  item: hero,
                  upcomingItem: comingUp.isEmpty ? null : comingUp.first,
                  now: now,
                ),
                const SizedBox(height: AppSpacing.md),
                HomeMetricsRow(
                  key: const ValueKey<String>('home-metrics'),
                  documentCount: documents.length,
                  subscriptionCount: subscriptions.length,
                  horizonCount: comingUp.length,
                  monthlyTotals: totals,
                  locale: l10n.localeName,
                ),
                const SizedBox(height: AppSpacing.md),
                _AttentionSection(
                  items: attention.take(3).toList(),
                  totalCount: attention.length,
                  now: now,
                ),
                const SizedBox(height: AppSpacing.xs),
                _ComingUpSection(
                  filter: _comingUpFilter,
                  onFilter: (filter) =>
                      setState(() => _comingUpFilter = filter),
                  groups: groups,
                  empty: homeComingUp.isEmpty,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AttentionSection extends StatelessWidget {
  const _AttentionSection({
    required this.items,
    required this.totalCount,
    required this.now,
  });

  final List<RegistryItem> items;
  final int totalCount;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = AppStatusColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    l10n.sectionNeedsAttention,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: status.urgent,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        '$totalCount',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          letterSpacing: 0,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (totalCount > 3)
              IconButton(
                key: const ValueKey<String>('home-attention-view-all'),
                tooltip: l10n.homeViewAll,
                onPressed: () => AppRoutes.openAttentionList(context),
                icon: Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (items.isEmpty)
          Text(l10n.attentionEmpty, style: theme.textTheme.bodySmall)
        else
          for (var index = 0; index < items.length; index++) ...[
            HomeAttentionCard(
              item: items[index],
              now: now,
              onTap: () => AppRoutes.openRegistryItem(context, items[index]),
            ),
            if (index != items.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class _ComingUpSection extends StatelessWidget {
  const _ComingUpSection({
    required this.filter,
    required this.onFilter,
    required this.groups,
    required this.empty,
  });

  final ComingUpFilter filter;
  final ValueChanged<ComingUpFilter> onFilter;
  final List<ComingUpGroup> groups;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final brand = AppBrandColors.of(context);

    Widget chip(ComingUpFilter value, String label, Key key) {
      final selected = filter == value;
      return FilterChip(
        key: key,
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onFilter(value),
        visualDensity: VisualDensity.compact,
        selectedColor: brand.dockSelected,
        labelStyle: theme.textTheme.labelSmall?.copyWith(
          color: selected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
          letterSpacing: 0,
        ),
        side: BorderSide(
          color: selected ? brand.dockSelected : theme.colorScheme.outline,
        ),
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.sectionComingUp,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              key: const ValueKey<String>('home-ninety-day'),
              onPressed: () => AppRoutes.openHorizon90Day(context),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(l10n.homeViewAll),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            chip(
              ComingUpFilter.all,
              l10n.comingUpFilterAll,
              const ValueKey<String>('coming-up-filter-all'),
            ),
            chip(
              ComingUpFilter.documents,
              l10n.comingUpFilterDocuments,
              const ValueKey<String>('coming-up-filter-documents'),
            ),
            chip(
              ComingUpFilter.subscriptions,
              l10n.comingUpFilterSubscriptions,
              const ValueKey<String>('coming-up-filter-subscriptions'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (empty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              l10n.comingUpEmptyFilter,
              key: const ValueKey<String>('coming-up-empty'),
              style: theme.textTheme.bodySmall,
            ),
          )
        else
          for (final group in groups) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                group.label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.1,
                  fontSize: 11,
                ),
              ),
            ),
            for (var index = 0; index < group.items.length; index++)
              HomeUpcomingItem(
                key: ValueKey<String>('upcoming-${group.items[index].id}'),
                item: group.items[index],
                isLast: index == group.items.length - 1,
                onTap: () =>
                    AppRoutes.openRegistryItem(context, group.items[index]),
              ),
          ],
      ],
    );
  }
}
