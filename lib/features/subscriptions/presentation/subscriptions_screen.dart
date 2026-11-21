import 'package:flutter/material.dart';

import '../../../app/navigation/app_routes.dart';
import '../../../app/registry_dependencies.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/registry_empty_state.dart';
import '../../../core/widgets/registry_primary_button.dart';
import '../../../core/widgets/registry_search_field.dart';
import '../../../core/widgets/registry_section_header.dart';
import '../../../core/widgets/registry_selectable_chip.dart';
import '../../../core/widgets/registry_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/money.dart';
import '../domain/subscription_estimate.dart';
import '../domain/subscription_status.dart';
import '../domain/subscription_wallet.dart';
import '../widgets/subscription_list_card.dart';
import 'subscription_calendar_view.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  SubscriptionWalletFilter _filter = SubscriptionWalletFilter.all;
  bool _isCalendarView = false;

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
          final cancelledCount = items.where((item) => item.isCancelled).length;
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
                cancelledCount: cancelledCount,
                isCalendarView: _isCalendarView,
                onToggleView: () =>
                    setState(() => _isCalendarView = !_isCalendarView),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_isCalendarView) ...[
                SubscriptionCalendarView(
                  subscriptions: items.where((item) => item.isActive).toList(),
                  now: now,
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const ValueKey<String>('subscriptions-add-calendar'),
                    onPressed: () => AppRoutes.openAddSubscription(context),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(l10n.addSubscription),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      minimumSize: const Size(AppSpacing.minTapTarget, 48),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height:
                      AppSpacing.minTapTarget *
                      MediaQuery.textScalerOf(context).scale(1),
                ),
              ] else ...[
                RegistryAuraSearchField(
                  controller: _searchController,
                  hintText: l10n.subscriptionsSearchPlaceholder,
                  fieldKey: const ValueKey<String>('subscriptions-search'),
                  clearKey: const ValueKey<String>(
                    'subscriptions-search-clear',
                  ),
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
                    cancelledCount: cancelledCount,
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
                    actionKey: const ValueKey<String>(
                      'subscriptions-add-header',
                    ),
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
                  SizedBox(
                    height:
                        AppSpacing.minTapTarget *
                        MediaQuery.textScalerOf(context).scale(1),
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

class _SubscriptionsHeader extends StatelessWidget {
  const _SubscriptionsHeader({
    required this.savedCount,
    required this.activeCount,
    this.cancelledCount = 0,
    this.isCalendarView = false,
    this.onToggleView,
  });

  final int savedCount;
  final int activeCount;
  final int cancelledCount;
  final bool isCalendarView;
  final VoidCallback? onToggleView;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.subscriptionsEyebrow,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.tertiary,
                ),
              ),
            ),
            Semantics(
              button: true,
              label: isCalendarView ? 'List view' : 'Calendar view',
              child: Material(
                color: isCalendarView
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(
                    color: isCalendarView
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                  ),
                ),
                child: InkWell(
                  key: const ValueKey<String>('subscriptions-calendar-toggle'),
                  onTap: onToggleView,
                  borderRadius: BorderRadius.circular(15),
                  child: SizedBox(
                    width: AppSpacing.minTapTarget,
                    height: AppSpacing.minTapTarget,
                    child: Icon(
                      isCalendarView
                          ? Icons.view_list_rounded
                          : Icons.calendar_month_outlined,
                      color: isCalendarView
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Semantics(
              button: true,
              label: l10n.cancelledSubscriptionsTitle,
              child: Material(
                color: colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: InkWell(
                  key: const ValueKey<String>('subscriptions-cancelled-button'),
                  onTap: () => AppRoutes.openCancelledSubscriptions(context),
                  borderRadius: BorderRadius.circular(15),
                  child: SizedBox(
                    width: AppSpacing.minTapTarget,
                    height: AppSpacing.minTapTarget,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.event_busy_outlined,
                          color: colorScheme.onSurface,
                        ),
                        if (cancelledCount > 0)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colorScheme.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Semantics(
              button: true,
              label: l10n.discoverSubscriptions,
              child: Material(
                color: colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: InkWell(
                  key: const ValueKey<String>('subscriptions-discover'),
                  onTap: () => AppRoutes.openDetectedSubscriptions(context),
                  borderRadius: BorderRadius.circular(15),
                  child: SizedBox(
                    width: AppSpacing.minTapTarget,
                    height: AppSpacing.minTapTarget,
                    child: Icon(
                      Icons.auto_awesome_outlined,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
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
        ),
        const SizedBox(height: AppSpacing.xxs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            l10n.subscriptionsTitle,
            maxLines: 1,
            softWrap: false,
            style: theme.textTheme.headlineMedium,
          ),
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
          if (cancelledCount > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              key: const ValueKey<String>('subscriptions-cancelled-link'),
              onTap: () => AppRoutes.openCancelledSubscriptions(context),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_busy_outlined,
                      size: 14,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      l10n.cancelledSubscriptionsCount(cancelledCount),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: colorScheme.error,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
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
    this.cancelledCount = 0,
  });

  final List<Money> totals;
  final int activeCount;
  final int attentionCount;
  final int cancelledCount;

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
          if (cancelledCount > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              onTap: () => AppRoutes.openCancelledSubscriptions(context),
              child: Text(
                '${l10n.cancelledSubscriptionsCount(cancelledCount)} · ${l10n.viewCancelledAction}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
