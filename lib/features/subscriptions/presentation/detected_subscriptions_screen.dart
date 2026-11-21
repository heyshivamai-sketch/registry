import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_shadows.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_empty_state.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/core/widgets/registry_secondary_button.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/features/subscriptions/domain/detected_subscription.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/presentation/subscription_copy.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class DetectedSubscriptionsScreen extends StatefulWidget {
  const DetectedSubscriptionsScreen({super.key});

  @override
  State<DetectedSubscriptionsScreen> createState() =>
      _DetectedSubscriptionsScreenState();
}

class _DetectedSubscriptionsScreenState
    extends State<DetectedSubscriptionsScreen> {
  Future<void> _addCandidate(DetectedSubscriptionCandidate candidate) async {
    final deps = RegistryDependencies.of(context);
    final saved = await AppRoutes.openAddSubscription(
      context,
      initialCandidate: candidate,
    );
    if (saved && mounted) {
      await deps.discovery.acceptCandidate(candidate.id);
    }
  }

  Future<void> _ignoreCandidate(
      DetectedSubscriptionCandidate candidate) async {
    final l10n = AppLocalizations.of(context);
    final deps = RegistryDependencies.of(context);
    await deps.discovery.ignoreCandidate(candidate.id);
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.candidateIgnored)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final deps = RegistryDependencies.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.detectedSubscriptionsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.mail_outline),
            tooltip: l10n.connectGmailTitle,
            onPressed: () => AppRoutes.openGmailConnect(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: deps.discovery,
          builder: (context, _) {
            final candidates = deps.discovery.pendingCandidates;
            if (candidates.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RegistryEmptyState(
                        title: l10n.detectedSubscriptionsTitle,
                        message: l10n.detectedSubscriptionsEmpty,
                        icon: Icons.auto_awesome,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      RegistryPrimaryButton(
                        key: const ValueKey<String>('detected-empty-connect-gmail'),
                        label: l10n.connectGmailButton,
                        onPressed: () => AppRoutes.openGmailConnect(context),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: candidates.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final candidate = candidates[index];
                return _DetectedCandidateCard(
                  candidate: candidate,
                  onAdd: () => _addCandidate(candidate),
                  onIgnore: () => _ignoreCandidate(candidate),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DetectedCandidateCard extends StatelessWidget {
  const _DetectedCandidateCard({
    required this.candidate,
    required this.onAdd,
    required this.onIgnore,
  });

  final DetectedSubscriptionCandidate candidate;
  final VoidCallback onAdd;
  final VoidCallback onIgnore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locale = l10n.localeName;

    final formattedAmount = MoneyFormat.format(candidate.amount, locale);
    final cycleLabel = SubscriptionCopy.cycle(l10n, candidate.billingCycle);

    final nextDate = candidate.nextPaymentDate != null
        ? RegistryDateFormatter.dayMonthYear(
            candidate.nextPaymentDate!,
            locale,
          )
        : null;

    final lastDate = RegistryDateFormatter.dayMonthYear(
      candidate.lastPaymentDate,
      locale,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: AppShadows.card(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    candidate.merchantName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  formattedAmount,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Text(
                  cycleLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                _ConfidenceBadge(confidence: candidate.confidence),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                if (candidate.hasBankSource)
                  _SourceChip(
                    icon: Icons.account_balance,
                    label: l10n.sourceBankStatement,
                  ),
                if (candidate.hasGmailSource)
                  _SourceChip(
                    icon: Icons.mail_outline,
                    label: l10n.sourceGmail,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (nextDate != null)
              Text(
                candidate.nextPaymentIsEstimated
                    ? l10n.estimatedRenewalDate(nextDate)
                    : l10n.confirmedRenewalDate(nextDate),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            Text(
              lastDate,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (candidate.possibleDuplicate) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.csvDuplicate,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: RegistrySecondaryButton(
                    key: ValueKey<String>('ignore-candidate-${candidate.id}'),
                    label: l10n.notASubscription,
                    onPressed: onIgnore,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: RegistryPrimaryButton(
                    key: ValueKey<String>('add-candidate-${candidate.id}'),
                    label: l10n.addToResiday,
                    onPressed: onAdd,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confidence});

  final DetectionConfidence confidence;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, color) = switch (confidence) {
      DetectionConfidence.high => (l10n.confidenceHigh, Colors.green),
      DetectionConfidence.medium => (l10n.confidenceMedium, Colors.orange),
      DetectionConfidence.low => (l10n.confidenceLow, Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}