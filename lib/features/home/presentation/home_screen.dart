import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_empty_state.dart';
import 'package:the_registry/core/widgets/registry_section_header.dart';
import 'package:the_registry/features/home/data/mock_registry_catalog.dart';
import 'package:the_registry/features/home/data/registry_item.dart';
import 'package:the_registry/features/home/widgets/home_header.dart';
import 'package:the_registry/features/home/widgets/home_metric_card.dart';
import 'package:the_registry/features/home/widgets/home_search_field.dart';
import 'package:the_registry/features/home/widgets/priority_hero_card.dart';
import 'package:the_registry/features/home/widgets/registry_item_card.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

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

  void _onFilter() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.filtersComingSoon)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allItems = MockRegistryCatalog.items;
    final visible = MockRegistryCatalog.byImpact(
      allItems.where(
        (item) =>
            MockRegistryCatalog.matches(item, _searchController.text, l10n),
      ),
    );
    final hero = visible.where((item) => item.isHero).firstOrNull;
    final attention = visible.where((item) => item.needsAttention).toList();
    final comingUp = visible.where((item) => !item.needsAttention).toList();
    final documentCount = allItems
        .where((item) => item.type == RegistryItemType.document)
        .length;
    final subscriptionCount = allItems
        .where((item) => item.type == RegistryItemType.subscription)
        .length;
    final attentionCount = allItems.where((item) => item.needsAttention).length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.screenPadding,
          AppSpacing.screenPadding,
          AppSpacing.screenPadding,
          AppSpacing.xxl + AppSpacing.xl,
        ),
        children: [
          const HomeHeader(),
          const SizedBox(height: AppSpacing.md),
          HomeSearchField(controller: _searchController, onFilter: _onFilter),
          const SizedBox(height: AppSpacing.sectionGap),
          if (visible.isEmpty)
            RegistryEmptyState(
              title: l10n.searchNoResultsTitle,
              message: l10n.searchNoResultsMessage,
              icon: Icons.search_off_rounded,
            )
          else ...[
            if (hero != null) ...[
              PriorityHeroCard(item: hero),
              const SizedBox(height: AppSpacing.md),
            ],
            Row(
              children: [
                Expanded(
                  child: HomeMetricCard(
                    title: l10n.summaryDocuments,
                    value: '$documentCount',
                    icon: Icons.folder_outlined,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: HomeMetricCard(
                    title: l10n.summarySubscriptions,
                    value: '$subscriptionCount',
                    icon: Icons.subscriptions_outlined,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: HomeMetricCard(
                    title: l10n.summaryNeedsAttention,
                    value: '$attentionCount',
                    icon: Icons.priority_high_rounded,
                  ),
                ),
              ],
            ),
            if (attention.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sectionGap),
              RegistrySectionHeader(title: l10n.sectionNeedsAttention),
              const SizedBox(height: AppSpacing.sm),
              for (final item in attention) ...[
                RegistryItemCard(item: item),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
            if (comingUp.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              RegistrySectionHeader(title: l10n.sectionComingUp),
              const SizedBox(height: AppSpacing.sm),
              for (final item in comingUp) ...[
                RegistryItemCard(item: item),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ],
        ],
      ),
    );
  }
}
