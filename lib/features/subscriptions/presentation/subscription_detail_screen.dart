import 'package:flutter/material.dart';
import 'package:the_registry/app/navigation/app_routes.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_empty_state.dart';
import 'package:the_registry/core/widgets/registry_section_header.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
import 'package:the_registry/features/documents/widgets/document_date_field.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_status.dart';
import 'package:the_registry/features/subscriptions/presentation/subscription_copy.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class SubscriptionDetailScreen extends StatelessWidget {
  const SubscriptionDetailScreen({super.key, required this.subscriptionId});

  final String subscriptionId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repository = RegistryDependencies.of(context).subscriptions;

    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final subscription = repository.findById(subscriptionId);
        if (subscription == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.subscriptionDetailsTitle)),
            body: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: RegistryEmptyState(
                key: const ValueKey<String>('subscription-unavailable'),
                title: l10n.subscriptionUnavailableTitle,
                message: l10n.subscriptionUnavailableMessage,
              ),
            ),
          );
        }
        return _SubscriptionDetailBody(subscription: subscription);
      },
    );
  }
}

class _SubscriptionDetailBody extends StatelessWidget {
  const _SubscriptionDetailBody({required this.subscription});

  final RegistrySubscription subscription;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = l10n.localeName;
    final now = RegistryDependencies.of(context).clock.now();
    final status = SubscriptionStatus.resolve(subscription, now: now);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.xs,
        title: Text(
          subscription.serviceName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          key: const ValueKey<String>('subscription-detail'),
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.screenPadding,
            AppSpacing.sm,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RegistrySurface(
                padding: const EdgeInsets.all(14),
                borderRadius: BorderRadius.circular(19),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(
                          SubscriptionCopy.iconFor(subscription.category),
                          color: theme.colorScheme.primary,
                        ),
                        RegistryAuraStatusPill(
                          status: status,
                          label: SubscriptionStatus.label(
                            l10n,
                            subscription,
                            now: now,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      subscription.serviceName,
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
                    ),
                    if (subscription.planName != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subscription.planName!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${MoneyFormat.format(subscription.amount, locale)} ${SubscriptionCopy.cycleSuffix(l10n, subscription.billingCycle)}',
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _PlanActions(subscription: subscription),
              const SizedBox(height: AppSpacing.md),
              RegistrySurface(
                padding: const EdgeInsets.all(14),
                borderRadius: BorderRadius.circular(19),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RegistrySectionHeader(
                      title: l10n.nextDecision,
                      actionLabel: subscription.isCancelled
                          ? l10n.subscriptionCancelled
                          : SubscriptionStatus.remainingLabel(
                              l10n,
                              subscription,
                              now: now,
                            ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DetailGrid(subscription: subscription),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              RegistrySurface(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RegistrySectionHeader(title: l10n.planInformation),
                    RegistryInfoRow(
                      label: l10n.fieldServiceName,
                      value: subscription.serviceName,
                    ),
                    if (subscription.planName != null)
                      RegistryInfoRow(
                        label: l10n.fieldPlanName,
                        value: subscription.planName!,
                      ),
                    RegistryInfoRow(
                      label: l10n.fieldCategory,
                      value: SubscriptionCopy.category(
                        l10n,
                        subscription.category,
                      ),
                    ),
                    RegistryInfoRow(
                      label: l10n.fieldAmount,
                      value: MoneyFormat.format(subscription.amount, locale),
                    ),
                    RegistryInfoRow(
                      label: l10n.fieldBillingCycle,
                      value: SubscriptionCopy.cycle(
                        l10n,
                        subscription.billingCycle,
                      ),
                    ),
                    RegistryInfoRow(
                      label: l10n.fieldAutoRenew,
                      value: subscription.autoRenew
                          ? l10n.autoRenewOn
                          : l10n.autoRenewOff,
                    ),
                    RegistryInfoRow(
                      label: l10n.fieldImpact,
                      value: SubscriptionCopy.impact(l10n, subscription.impact),
                    ),
                    RegistryInfoRow(
                      label: l10n.lifecycleLabel,
                      value: subscription.isCancelled
                          ? l10n.subscriptionCancelled
                          : l10n.subscriptionActive,
                    ),
                    if (subscription.notes != null)
                      RegistryInfoRow(
                        label: l10n.fieldNotes,
                        value: subscription.notes!,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              RegistrySurface(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RegistrySectionHeader(title: l10n.reminderPreferencesTitle),
                    const SizedBox(height: AppSpacing.xs),
                    if (subscription.reminders.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          l10n.noRemindersSelected,
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    else
                      RegistryInfoRow(
                        label: l10n.remindMePrefix,
                        value: [
                          for (final reminder in SubscriptionReminder.values)
                            if (subscription.reminders.contains(reminder))
                              SubscriptionCopy.reminder(l10n, reminder),
                        ].join(', '),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.subscriptionRemindersHelper,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              RegistryCallout(
                tone: RegistryCalloutTone.warning,
                message: l10n.subscriptionTrackingDisclaimer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.subscription});

  final RegistrySubscription subscription;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final cells = <(String, String)>[
      if (subscription.decideByDate != null)
        (
          l10n.fieldDecideBy,
          RegistryDateFormatter.dayMonthYear(
            subscription.decideByDate!,
            locale,
          ),
        ),
      (
        l10n.fieldNextPayment,
        RegistryDateFormatter.dayMonthYear(
          subscription.nextPaymentDate,
          locale,
        ),
      ),
      (
        l10n.fieldBillingCycle,
        SubscriptionCopy.cycle(l10n, subscription.billingCycle),
      ),
      (
        l10n.fieldAutoRenew,
        subscription.autoRenew ? l10n.autoRenewOn : l10n.autoRenewOff,
      ),
    ];

    return Column(
      children: [
        for (final cell in cells)
          RegistryInfoRow(label: cell.$1, value: cell.$2),
      ],
    );
  }
}

class _PlanActions extends StatelessWidget {
  const _PlanActions({required this.subscription});

  final RegistrySubscription subscription;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final actions = <Widget>[
      _PlanAction(
        key: const ValueKey<String>('subscription-edit'),
        icon: Icons.edit_outlined,
        label: l10n.editAction,
        onPressed: () =>
            AppRoutes.openEditSubscription(context, subscription.id),
      ),
      if (subscription.isActive)
        _PlanAction(
          key: const ValueKey<String>('subscription-cancel'),
          icon: Icons.cancel_outlined,
          label: l10n.markCancelled,
          onPressed: () => _confirmCancel(context, subscription),
        )
      else
        _PlanAction(
          key: const ValueKey<String>('subscription-reactivate'),
          icon: Icons.restart_alt_outlined,
          label: l10n.reactivatePlan,
          onPressed: () => _confirmReactivate(context, subscription),
        ),
      _PlanAction(
        key: const ValueKey<String>('subscription-delete'),
        icon: Icons.delete_outline,
        label: l10n.deleteSubscription,
        onPressed: () => _confirmDelete(context, subscription),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final stacked = constraints.maxWidth < 360 || scale >= 1.3;
        if (stacked) {
          return Column(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i != 0) const SizedBox(height: AppSpacing.xs),
                actions[i],
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i != 0) const SizedBox(width: 7),
              Expanded(child: actions[i]),
            ],
          ],
        );
      },
    );
  }
}

class _PlanAction extends StatelessWidget {
  const _PlanAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.minTapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.xxs),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmCancel(
  BuildContext context,
  RegistrySubscription subscription,
) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.cancelPlanTitle),
        content: Text(l10n.cancelPlanMessage(subscription.serviceName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.deleteDocumentCancel),
          ),
          TextButton(
            key: const ValueKey<String>('cancel-plan-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.markCancelled),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) {
    return;
  }
  final deps = RegistryDependencies.of(context);
  await deps.subscriptions.update(
    subscription.copyWith(
      lifecycle: SubscriptionLifecycle.cancelled,
      updatedAt: deps.clock.now(),
    ),
  );
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.planMarkedCancelled)));
}

Future<void> _confirmReactivate(
  BuildContext context,
  RegistrySubscription subscription,
) async {
  final l10n = AppLocalizations.of(context);
  DateTime nextPayment = subscription.nextPaymentDate;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.reactivatePlanTitle),
        content: _ReactivateDialog(
          subscription: subscription,
          onDateChanged: (value) => nextPayment = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.deleteDocumentCancel),
          ),
          TextButton(
            key: const ValueKey<String>('reactivate-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.reactivatePlan),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) {
    return;
  }
  final deps = RegistryDependencies.of(context);
  await deps.subscriptions.update(
    subscription.copyWith(
      lifecycle: SubscriptionLifecycle.active,
      nextPaymentDate: nextPayment,
      updatedAt: deps.clock.now(),
    ),
  );
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.planReactivated)));
}

Future<void> _confirmDelete(
  BuildContext context,
  RegistrySubscription subscription,
) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.deleteSubscriptionTitle),
        content: Text(l10n.deleteSubscriptionMessage(subscription.serviceName)),
        actions: [
          TextButton(
            key: const ValueKey<String>('delete-sub-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.deleteDocumentCancel),
          ),
          TextButton(
            key: const ValueKey<String>('delete-sub-confirm'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.deleteDocumentConfirm),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) {
    return;
  }
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final deleted = await RegistryDependencies.of(
    context,
  ).subscriptions.delete(subscription.id);
  if (!deleted) {
    return;
  }
  navigator.pop();
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.subscriptionDeleted)));
}

class _ReactivateDialog extends StatefulWidget {
  const _ReactivateDialog({
    required this.subscription,
    required this.onDateChanged,
  });

  final RegistrySubscription subscription;
  final ValueChanged<DateTime> onDateChanged;

  @override
  State<_ReactivateDialog> createState() => _ReactivateDialogState();
}

class _ReactivateDialogState extends State<_ReactivateDialog> {
  late DateTime _nextPayment = widget.subscription.nextPaymentDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.reactivatePlanMessage(widget.subscription.serviceName)),
        const SizedBox(height: AppSpacing.md),
        DocumentDateField(
          fieldId: 'reactivate-next-payment',
          label: l10n.fieldNextPayment,
          value: _nextPayment,
          requiredField: true,
          onTap: () async {
            final picked = await RegistryDependencies.of(context).datePicker
                .pickDate(
                  context,
                  fieldId: 'reactivate-next-payment',
                  initialDate: _nextPayment,
                );
            if (picked != null) {
              setState(() => _nextPayment = picked);
              widget.onDateChanged(picked);
            }
          },
        ),
      ],
    );
  }
}
