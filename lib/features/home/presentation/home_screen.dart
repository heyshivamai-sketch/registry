import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_empty_state.dart';
import 'package:the_registry/core/widgets/registry_section_header.dart';
import 'package:the_registry/features/home/data/mock_registry_catalog.dart';
import 'package:the_registry/features/home/data/registry_item.dart';
import 'package:the_registry/features/home/widgets/home_attention_card.dart';
import 'package:the_registry/features/home/widgets/home_header.dart';
import 'package:the_registry/features/home/widgets/home_metrics_row.dart';
import 'package:the_registry/features/home/widgets/home_search_field.dart';
import 'package:the_registry/features/home/widgets/home_upcoming_item.dart';
import 'package:the_registry/features/home/widgets/priority_hero_card.dart';
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
    final attention = MockRegistryCatalog.byImpact(
      visible.where((item) => item.requiresAttention),
    );
    final comingUp = MockRegistryCatalog.byUpcomingDate(
      visible.where((item) => !item.requiresAttention),
    );
    final documentCount = allItems
        .where((item) => item.type == RegistryItemType.document)
        .length;
    final subscriptionCount = allItems
        .where((item) => item.type == RegistryItemType.subscription)
        .length;
    final horizonCount = MockRegistryCatalog.withinHorizonCount(allItems);
    final documentAttention = allItems
        .where(
          (item) =>
              item.type == RegistryItemType.document && item.requiresAttention,
        )
        .length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.screenPadding,
          AppSpacing.pageTop,
          AppSpacing.screenPadding,
          AppSpacing.scrollDockClearance,
        ),
        children: [
          const HomeHeader(),
          const SizedBox(height: AppSpacing.sm),
          HomeSearchField(controller: _searchController),
          const SizedBox(height: AppSpacing.md),
          if (visible.isEmpty)
            RegistryEmptyState(
              key: const ValueKey<String>('home-search-empty'),
              title: l10n.searchNoResultsTitle,
              message: l10n.searchNoResultsMessage,
              icon: Icons.search_off_rounded,
            )
          else ...[
            if (hero != null) ...[
              PriorityHeroCard(
                key: const ValueKey<String>('home-hero'),
                item: hero,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            RegistryAuraSectionHeader(
              key: const ValueKey<String>('home-snapshot-header'),
              title: l10n.sectionRegistrySnapshot,
              actionLabel: l10n.snapshotNinetyDayView,
            ),
            const SizedBox(height: AppSpacing.sm),
            HomeMetricsRow(
              key: const ValueKey<String>('home-metrics'),
              documentCount: documentCount,
              subscriptionCount: subscriptionCount,
              horizonCount: horizonCount,
              documentSupporting: l10n.snapshotDocumentsSupporting(
                documentAttention,
              ),
              subscriptionSupporting: l10n.snapshotSubscriptionsSupporting(
                subscriptionCount,
              ),
              horizonSupporting: l10n.snapshotNext90Hint,
            ),
            if (attention.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              RegistryAuraSectionHeader(
                key: const ValueKey<String>('home-attention-header'),
                title: l10n.sectionNeedsAttention,
                count: attention.length,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final item in attention) ...[
                HomeAttentionCard(item: item),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
            if (comingUp.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              RegistryAuraSectionHeader(
                key: const ValueKey<String>('home-coming-up-header'),
                title: l10n.sectionComingUp,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (var index = 0; index < comingUp.length; index++)
                HomeUpcomingItem(
                  key: ValueKey<String>('upcoming-${comingUp[index].id}'),
                  item: comingUp[index],
                  isLast: index == comingUp.length - 1,
                ),
            ],
          ],
        ],
      ),
    );
  }
}
