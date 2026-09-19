import 'package:flutter/material.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_shadows.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_status.dart';
import 'package:the_registry/features/subscriptions/presentation/subscription_copy.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class SubscriptionListCard extends StatelessWidget {
  const SubscriptionListCard({
    super.key,
    required this.subscription,
    this.onTap,
  });

  final RegistrySubscription subscription;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColors = AppStatusColors.of(context);
    final locale = l10n.localeName;
    final now = RegistryDependencies.of(context).clock.now();
    final status = SubscriptionStatus.resolve(subscription, now: now);
    final accent = status.accent(statusColors);
    final letter = subscription.serviceName.trim().isEmpty
        ? '?'
        : subscription.serviceName.trim().characters.first.toUpperCase();
    final nextPayment = RegistryDateFormatter.dayMonthYear(
      subscription.nextPaymentDate,
      locale,
    );
    final decideBy = subscription.decideByDate == null
        ? null
        : RegistryDateFormatter.dayMonthYear(
            subscription.decideByDate!,
            locale,
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: AppShadows.card(context),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardBorder,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.cardBorder,
              border: BorderDirectional(
                start: BorderSide(color: accent, width: 3),
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.minTapTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    RegistryIconBadge(
                      icon: SubscriptionCopy.iconFor(subscription.category),
                      size: 43,
                      background: const Color(0xFFF0EFFF),
                      foreground: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subscription.serviceName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            semanticsLabel: subscription.serviceName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontSize: 13,
                            ),
                          ),
                          if (subscription.planName != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subscription.planName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            '${SubscriptionCopy.category(l10n, subscription.category)} · ${SubscriptionCopy.cycle(l10n, subscription.billingCycle)}',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${MoneyFormat.format(subscription.amount, locale)} ${SubscriptionCopy.cycleSuffix(l10n, subscription.billingCycle)}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.nextChargeDate(nextPayment),
                            style: theme.textTheme.bodySmall,
                          ),
                          if (subscription.hasDistinctDecideBy &&
                              decideBy != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              l10n.decideByDate(decideBy),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 4),
                          RegistryStatusChip(
                            status: status,
                            label: SubscriptionStatus.label(
                              l10n,
                              subscription,
                              now: now,
                            ),
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      excludeSemantics: true,
                      child: Text(
                        letter,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.tertiary,
                        ),
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        color: const Color(0xFF737B91),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
