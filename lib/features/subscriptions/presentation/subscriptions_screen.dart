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
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_estimate.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_status.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_wallet.dart';
import 'package:the_registry/features/subscriptions/widgets/subscription_list_card.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  SubscriptionWalletFilter _filter = SubscriptionWalletFilter.all;

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
        listenable: deps.subscriptions,
        builder: (context, _) {
          final items = [...deps.subscriptions.subscriptions]
            ..sort(
              (a, b) => SubscriptionWallet.compareRelevance(a, b, now: now),
            );
          final query = _searchController.text;
          final visible = SubscriptionWallet.visible(
            items,
            query: query,
            filter: _filter,
            l10n: l10n,
            now: now,
          );
          final activeCount = items.where((item) => item.isActive).length;
          final totals = SubscriptionEstimate.monthlyTotals(items);
          final attention = SubscriptionStatus.attentionCount(items, now: now);

          return ListView(
            padding: EdgeInsetsDirectional.fromSTEB(
              AppSpacing.screenPadding,
              AppSpacing.pageTop,
              AppSpacing.screenPadding,
              AppSpacing.scrollClearanceForDock(this.context),
            ),
            children: [
              _SubscriptionsHeader(
                savedCount: items.length,
                activeCount: activeCount,
              ),
              const SizedBox(height: AppSpacing.sm),
              RegistryAuraSearchField(
                controller: _searchController,
                hintText: l10n.subscriptionsSearchPlaceholder,
                fieldKey: const ValueKey<String>('subscriptions-search'),
                clearKey: const ValueKey<String>('subscriptions-search-clear'),
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _SubscriptionFilters(
                  selected: _filter,
                  totalCount: items.length,
                  onSelected: (filter) => setState(() => _filter = filter),
                ),
                const SizedBox(height: AppSpacing.md),
                _MonthlyCostCard(
                  totals: totals,
                  activeCount: activeCount,
                  attentionCount: attention,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              if (items.isEmpty)
                RegistryEmptyState(
                  key: const ValueKey<String>('subscriptions-empty'),
                  title: l10n.subscriptionsEmptyTitle,
                  message: l10n.subscriptionsEmptyMessage,
                  illustration: const RegistrySubscriptionIllustration(),
                  action: SizedBox(
                    width: double.infinity,
                    child: RegistryPrimaryButton(
                      key: const ValueKey<String>('subscriptions-add'),
                      label: l10n.addSubscription,
                      onPressed: () => AppRoutes.openAddSubscription(context),
                    ),
                  ),
                )
              else if (visible.isEmpty)
                RegistryEmptyState(
                  key: const ValueKey<String>('subscriptions-filter-empty'),
                  title: query.trim().isEmpty
                      ? l10n.subscriptionsFilterEmptyTitle
                      : l10n.subscriptionsSearchEmptyTitle,
                  message: query.trim().isEmpty
                      ? l10n.subscriptionsFilterEmptyMessage
                      : l10n.subscriptionsSearchEmptyMessage,
                  icon: Icons.search_off_rounded,
                )
              else ...[
                RegistryAuraSectionHeader(
                  title: l10n.subscriptionsListHeader,
                  actionLabel: l10n.addSubscriptionShort,
                  actionKey: const ValueKey<String>('subscriptions-add-header'),
                  onAction: () => AppRoutes.openAddSubscription(context),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final subscription in visible) ...[
                  SubscriptionListCard(
                    key: ValueKey<String>(subscription.id),
                    subscription: subscription,
                    onTap: () => AppRoutes.openSubscriptionDetail(
                      context,
                      subscription.id,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
              if (items.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: const ValueKey<String>('subscriptions-add'),
                    onPressed: () => AppRoutes.openAddSubscription(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(AppSpacing.minTapTarget, 45),
                      side: const BorderSide(color: Color(0xFFA9AFC2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(l10n.addSubscription),
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

class _SubscriptionsHeader extends StatelessWidget {
  const _SubscriptionsHeader({
    required this.savedCount,
    required this.activeCount,
  });

  final int savedCount;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.subscriptionsEyebrow,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.tertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                l10n.subscriptionsTitle,
                style: theme.textTheme.headlineMedium,
              ),
              if (savedCount > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.subscriptionsSavedSummary(savedCount),
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  l10n.subscriptionsActiveSummary(activeCount),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        Semantics(
          button: true,
          label: l10n.notificationsButton,
          child: Material(
            color: colorScheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: InkWell(
              onTap: () => AppRoutes.openNotifications(context),
              borderRadius: BorderRadius.circular(15),
              child: SizedBox(
                width: AppSpacing.minTapTarget,
                height: AppSpacing.minTapTarget,
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SubscriptionFilters extends StatelessWidget {
  const _SubscriptionFilters({
    required this.selected,
    required this.totalCount,
    required this.onSelected,
  });

  final SubscriptionWalletFilter selected;
  final int totalCount;
  final ValueChanged<SubscriptionWalletFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filters = <(SubscriptionWalletFilter, String, Key)>[
      (
        SubscriptionWalletFilter.all,
        '${l10n.documentsFilterAll} $totalCount',
        const ValueKey<String>('sub-filter-all'),
      ),
      (
        SubscriptionWalletFilter.actionNeeded,
        l10n.actionNeeded,
        const ValueKey<String>('sub-filter-action'),
      ),
      (
        SubscriptionWalletFilter.upcoming,
        l10n.statusUpcoming,
        const ValueKey<String>('sub-filter-upcoming'),
      ),
      (
        SubscriptionWalletFilter.active,
        l10n.statusActive,
        const ValueKey<String>('sub-filter-active'),
      ),
      (
        SubscriptionWalletFilter.overdue,
        l10n.statusOverdue,
        const ValueKey<String>('sub-filter-overdue'),
      ),
      (
        SubscriptionWalletFilter.cancelled,
        l10n.subscriptionCancelled,
        const ValueKey<String>('sub-filter-cancelled'),
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

class _MonthlyCostCard extends StatelessWidget {
  const _MonthlyCostCard({
    required this.totals,
    required this.activeCount,
    required this.attentionCount,
  });

  final List<Money> totals;
  final int activeCount;
  final int attentionCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = l10n.localeName;
    final headline = totals.isEmpty
        ? MoneyFormat.format(
            const Money(minorUnits: 0, currencyCode: 'USD'),
            locale,
          )
        : totals.length == 1
        ? MoneyFormat.format(totals.first, locale)
        : l10n.estimatedMonthlyMultiple(totals.length);

    return RegistrySurface(
      key: const ValueKey<String>('monthly-cost-card'),
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.monthlySnapshotEyebrow,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.tertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            headline,
            key: totals.length == 1
                ? ValueKey<String>('monthly-total-${totals.first.code}')
                : const ValueKey<String>('monthly-cost-headline'),
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(l10n.estimatedMonthlyCost, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.estimatedMonthlyDisclaimer,
            style: theme.textTheme.bodySmall,
          ),
          if (totals.length > 1) ...[
            const SizedBox(height: AppSpacing.sm),
            for (final total in totals)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  MoneyFormat.format(total, locale),
                  key: ValueKey<String>('monthly-total-${total.code}'),
                  style: theme.textTheme.titleSmall,
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.subscriptionsActiveSummary(activeCount),
            style: theme.textTheme.bodySmall,
          ),
          Text(
            l10n.subscriptionsAttentionSummary(attentionCount),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
