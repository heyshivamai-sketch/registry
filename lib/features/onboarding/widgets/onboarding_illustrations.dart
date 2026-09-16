import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class DatesIllustration extends StatelessWidget {
  const DatesIllustration({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _IllustrationFrame(
      semanticLabel: l10n.onboardingPage1IllustrationLabel,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: const AlignmentDirectional(-0.15, 0.1),
            child: _MiniCard(
              width: 168,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: colorScheme.primary,
                    size: AppSpacing.iconMd,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.onboardingDocumentName,
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    l10n.onboardingDocumentExpiry,
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: const AlignmentDirectional(0.85, -0.55),
            child: _MiniCard(
              width: 108,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: colorScheme.secondary,
                    size: AppSpacing.iconMd,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text('12', style: textTheme.titleLarge),
                ],
              ),
            ),
          ),
          Align(
            alignment: const AlignmentDirectional(-0.7, 0.85),
            child: UnconstrainedBox(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: AppRadius.chipBorder,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_active_outlined,
                        size: AppSpacing.md,
                        color: colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        l10n.onboardingReminder,
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SubscriptionsIllustration extends StatelessWidget {
  const SubscriptionsIllustration({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _IllustrationFrame(
      semanticLabel: l10n.onboardingPage2IllustrationLabel,
      child: Stack(
        children: [
          Align(
            alignment: const AlignmentDirectional(0.2, -0.35),
            child: Transform.rotate(
              angle: 0.04,
              child: _MiniCard(
                width: 200,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.subscriptions_outlined,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l10n.onboardingSubscriptionName,
                      style: textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: const AlignmentDirectional(-0.1, 0.15),
            child: _MiniCard(
              width: 220,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.onboardingUpcomingCharge,
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    l10n.onboardingDecisionDate,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyIllustration extends StatelessWidget {
  const PrivacyIllustration({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _IllustrationFrame(
      semanticLabel: l10n.onboardingPage3IllustrationLabel,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.smartphone_outlined,
                size: 88,
                color: colorScheme.primary,
              ),
              Positioned(
                bottom: AppSpacing.xs,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Icon(
                      Icons.shield_outlined,
                      color: colorScheme.onSecondaryContainer,
                      size: AppSpacing.iconMd,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: AppRadius.chipBorder,
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: AppSpacing.md,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(l10n.onboardingPrivacyLock, style: textTheme.labelLarge),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IllustrationFrame extends StatelessWidget {
  const _IllustrationFrame({required this.semanticLabel, required this.child});

  final String semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: semanticLabel,
      image: true,
      child: ClipRRect(
        borderRadius: AppRadius.cardBorder,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardBorder,
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [
                colorScheme.primaryContainer.withValues(alpha: 0.7),
                colorScheme.secondaryContainer.withValues(alpha: 0.45),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.child, required this.width});

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return UnconstrainedBox(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: AppRadius.cardBorder,
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ),
      ),
    );
  }
}
