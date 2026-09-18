import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
import 'package:the_registry/features/home/widgets/home_metric_card.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class HomeMetricsRow extends StatelessWidget {
  const HomeMetricsRow({
    super.key,
    required this.documentCount,
    required this.subscriptionCount,
    required this.attentionCount,
  });

  final int documentCount;
  final int subscriptionCount;
  final int attentionCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final status = AppStatusColors.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final metrics = [
      (
        title: l10n.summaryDocuments,
        value: '$documentCount',
        icon: Icons.folder_outlined,
        tone: HomeMetricTone.documents,
        color: colorScheme.primaryContainer,
      ),
      (
        title: l10n.summarySubscriptions,
        value: '$subscriptionCount',
        icon: Icons.subscriptions_outlined,
        tone: HomeMetricTone.subscriptions,
        color: colorScheme.secondaryContainer,
      ),
      (
        title: l10n.summaryNeedsAttention,
        value: '$attentionCount',
        icon: Icons.priority_high_rounded,
        tone: HomeMetricTone.attention,
        color: status.urgentContainer,
      ),
    ];

    return RegistrySurface(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minColumnWidth = 96.0 * textScale.clamp(1.0, 1.75);
          final canFitRow =
              constraints.maxWidth >=
              (minColumnWidth * 3) + (AppSpacing.xs * 2);

          if (!canFitRow) {
            return Column(
              children: [
                for (var i = 0; i < metrics.length; i++) ...[
                  if (i != 0) const SizedBox(height: AppSpacing.xs),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: metrics[i].color.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                        horizontal: AppSpacing.sm,
                      ),
                      child: HomeMetricCard(
                        title: metrics[i].title,
                        value: metrics[i].value,
                        icon: metrics[i].icon,
                        tone: metrics[i].tone,
                        inline: true,
                      ),
                    ),
                  ),
                ],
              ],
            );
          }

          return Row(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                if (i != 0) const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: metrics[i].color.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                        horizontal: AppSpacing.xxs,
                      ),
                      child: HomeMetricCard(
                        title: metrics[i].title,
                        value: metrics[i].value,
                        icon: metrics[i].icon,
                        tone: metrics[i].tone,
                      ),
                    ),
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
