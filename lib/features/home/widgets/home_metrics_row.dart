import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_shell.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/features/home/widgets/registry_document_stack.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class HomeMetricsRow extends StatelessWidget {
  const HomeMetricsRow({
    super.key,
    required this.documentCount,
    required this.subscriptionCount,
    required this.horizonCount,
    this.documentSupporting,
    this.subscriptionSupporting,
    this.horizonSupporting,
    this.onHorizonTap,
    this.monthlyTotals = const [],
    this.locale = 'en',
  });

  final int documentCount;
  final int subscriptionCount;
  final int horizonCount;
  final String? documentSupporting;
  final String? subscriptionSupporting;
  final String? horizonSupporting;
  final VoidCallback? onHorizonTap;
  final List<Money> monthlyTotals;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brand = AppBrandColors.of(context);
    final tabs = RegistryTabScope.maybeOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 300 || textScale >= 1.35;
        final documents = _OverviewTile(
          key: const ValueKey<String>('metric-documents'),
          background: brand.mintSurface,
          onTap: tabs == null ? null : () => tabs.onSelect(1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$documentCount',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      l10n.homeDocumentsTile,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const RegistryDocumentStack(size: RegistryDocumentStackSize.tile),
            ],
          ),
        );
        final subscriptions = _OverviewTile(
          key: const ValueKey<String>('metric-subscriptions'),
          background: brand.lavenderSurface,
          onTap: tabs == null ? null : () => tabs.onSelect(2),
          child: _SubscriptionTotals(
            totals: monthlyTotals,
            subscriptionCount: subscriptionCount,
            locale: locale,
            l10n: l10n,
          ),
        );

        if (stacked) {
          return Column(
            children: [
              documents,
              const SizedBox(height: AppSpacing.xs),
              subscriptions,
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: documents),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: subscriptions),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({
    super.key,
    required this.background,
    required this.child,
    this.onTap,
  });

  final Color background;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.metric),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.metric),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 96),
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _SubscriptionTotals extends StatelessWidget {
  const _SubscriptionTotals({
    required this.totals,
    required this.subscriptionCount,
    required this.locale,
    required this.l10n,
  });

  final List<Money> totals;
  final int subscriptionCount;
  final String locale;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = totals.take(2).toList();
    final overflow = totals.length > 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: theme.colorScheme.primary,
            ),
            const Spacer(),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (totals.isEmpty)
          Text(
            l10n.homeNoActivePlans,
            style: theme.textTheme.titleMedium?.copyWith(fontSize: 16),
          )
        else ...[
          Text(
            MoneyFormat.format(visible.first, locale),
            style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
          ),
          for (final extra in visible.skip(1))
            Text(
              MoneyFormat.format(extra, locale),
              style: theme.textTheme.bodySmall,
            ),
          if (overflow)
            Semantics(
              button: true,
              label: l10n.homeSeeAllCurrencies,
              child: GestureDetector(
                key: const ValueKey<String>('home-currency-breakdown'),
                onTap: () => _showBreakdown(context),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.homeSeeAllCurrencies,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
        ],
        const SizedBox(height: 6),
        Text(l10n.homeEstimatedMonthlyCost, style: theme.textTheme.bodySmall),
        Text(
          l10n.homeSubscriptionCount(subscriptionCount),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _showBreakdown(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeCurrencyBreakdownTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final total in totals)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(MoneyFormat.format(total, locale)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
