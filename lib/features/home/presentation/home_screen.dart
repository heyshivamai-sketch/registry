import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_empty_state.dart';
import 'package:the_registry/core/widgets/registry_section_header.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/features/home/data/mock_registry_catalog.dart';
import 'package:the_registry/features/home/data/registry_item.dart';
import 'package:the_registry/features/home/data/registry_read_model.dart';
import 'package:the_registry/features/home/widgets/home_attention_card.dart';
import 'package:the_registry/features/home/widgets/home_header.dart';
import 'package:the_registry/features/home/widgets/home_metrics_row.dart';
import 'package:the_registry/features/home/widgets/home_search_field.dart';
import 'package:the_registry/features/home/widgets/home_upcoming_item.dart';
import 'package:the_registry/features/home/widgets/priority_hero_card.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_estimate.dart';
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
    final deps = RegistryDependencies.of(context);
    final now = deps.clock.now();

    return SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([deps.documents, deps.subscriptions]),
        builder: (context, _) {
          final allItems = RegistryReadModel.fromRepositories(
            documents: deps.documents.documents,
            subscriptions: deps.subscriptions.subscriptions,
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
          final hero = RegistryReadModel.pulseItem(visible);
          final attention = RegistryReadModel.attentionItems(visible);
          final comingUp = RegistryReadModel.horizonItems(visible, now: now);
          final documentCount = allItems
              .where((item) => item.type == RegistryItemType.document)
              .length;
          final subscriptionCount = allItems
              .where((item) => item.type == RegistryItemType.subscription)
              .length;
          final horizonCount = MockRegistryCatalog.withinHorizonCount(
            allItems.where((item) => item.status != RegistryStatus.neutral),
            now: now,
          );
          final documentAttention = allItems
              .where(
                (item) =>
                    item.type == RegistryItemType.document &&
                    item.requiresAttention,
              )
              .length;
          final totals = SubscriptionEstimate.monthlyTotals(
            deps.subscriptions.subscriptions,
          );
          final locale = l10n.localeName;
          final subscriptionSupporting = totals.isEmpty
              ? l10n.snapshotSubscriptionsHint
              : totals.length == 1
              ? l10n.homeEstimatedMonthly(
                  MoneyFormat.format(totals.first, locale),
                )
              : totals
                    .map((total) => MoneyFormat.format(total, locale))
                    .join(' · ');

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
              if (_searchController.text.trim().isNotEmpty && visible.isEmpty)
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
                ] else if (allItems.isEmpty || attention.isEmpty) ...[
                  RegistryEmptyState(
                    key: const ValueKey<String>('home-calm-empty'),
                    title: allItems.isEmpty
                        ? l10n.homeEmptyTitle
                        : l10n.homeCalmTitle,
                    message: allItems.isEmpty
                        ? l10n.homeEmptyMessage
                        : l10n.homeCalmMessage,
                    icon: Icons.spa_outlined,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                RegistryAuraSectionHeader(
                  key: const ValueKey<String>('home-snapshot-header'),
                  title: l10n.sectionRegistrySnapshot,
                  actionLabel: l10n.snapshotNinetyDayView,
                  actionKey: const ValueKey<String>('home-ninety-day'),
                  onAction: () => AppRoutes.openHorizon90Day(context),
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
                  subscriptionSupporting: subscriptionSupporting,
                  horizonSupporting: l10n.snapshotNext90Hint,
                  onHorizonTap: () => AppRoutes.openHorizon90Day(context),
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
                    HomeAttentionCard(
                      item: item,
                      onTap: () => AppRoutes.openRegistryItem(context, item),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
                if (comingUp.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  RegistryAuraSectionHeader(
                    key: const ValueKey<String>('home-coming-up-header'),
                    title: l10n.sectionComingUp,
                    actionLabel: l10n.horizonOpenCalendar,
                    actionKey: const ValueKey<String>('home-open-calendar'),
                    onAction: () => AppRoutes.openHorizon90Day(context),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (var index = 0; index < comingUp.length; index++)
                    HomeUpcomingItem(
                      key: ValueKey<String>('upcoming-${comingUp[index].id}'),
                      item: comingUp[index],
                      isLast: index == comingUp.length - 1,
                      onTap: () =>
                          AppRoutes.openRegistryItem(context, comingUp[index]),
                    ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}
