import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_shell.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_metric.dart';
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
  });

  final int documentCount;
  final int subscriptionCount;
  final int horizonCount;
  final String? documentSupporting;
  final String? subscriptionSupporting;
  final String? horizonSupporting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final status = AppStatusColors.of(context);
    final tabs = RegistryTabScope.maybeOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final metrics = [
      (
        title: l10n.summaryDocuments,
        value: '$documentCount',
        supporting: documentSupporting ?? l10n.snapshotDocumentsHint,
        color: colorScheme.surfaceContainerLowest,
        onTap: tabs == null ? null : () => tabs.onSelect(1),
      ),
      (
        title: l10n.summarySubscriptions,
        value: '$subscriptionCount',
        supporting: subscriptionSupporting ?? l10n.snapshotSubscriptionsHint,
        color: colorScheme.secondaryContainer,
        onTap: tabs == null ? null : () => tabs.onSelect(2),
      ),
      (
        title: l10n.summaryNext90Days,
        value: '$horizonCount',
        supporting: horizonSupporting ?? l10n.snapshotNext90Hint,
        color: status.warningContainer,
        onTap: null,
      ),
    ];

    Widget card(int i) {
      final metric = metrics[i];
      final child = Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: RegistryAuraMetricCard(
          label: metric.title,
          value: metric.value,
          supportingText: metric.supporting,
        ),
      );
      return Material(
        color: metric.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.metric),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: metric.onTap == null
            ? child
            : InkWell(
                onTap: metric.onTap,
                borderRadius: BorderRadius.circular(AppRadius.metric),
                child: child,
              ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final minColumnWidth = 108.0 * textScale.clamp(1.0, 1.75);
        final canFitRow =
            constraints.maxWidth >= (minColumnWidth * 3) + (AppSpacing.xs * 2);

        if (!canFitRow) {
          return Column(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                if (i != 0) const SizedBox(height: AppSpacing.xs),
                SizedBox(width: double.infinity, child: card(i)),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < metrics.length; i++) ...[
              if (i != 0) const SizedBox(width: AppSpacing.xs),
              Expanded(child: card(i)),
            ],
          ],
        );
      },
    );
  }
}
