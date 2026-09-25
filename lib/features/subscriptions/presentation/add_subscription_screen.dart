import 'package:flutter/material.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_amount_field.dart';
import 'package:the_registry/core/widgets/registry_empty_state.dart';
import 'package:the_registry/core/widgets/registry_form_field.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/core/widgets/registry_searchable_sheet.dart';
import 'package:the_registry/core/widgets/registry_secondary_button.dart';
import 'package:the_registry/core/widgets/registry_selectable_chip.dart';
import 'package:the_registry/core/widgets/registry_selector_field.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/presentation/document_copy.dart';
import 'package:the_registry/features/documents/widgets/document_date_field.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_estimate.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/presentation/add_subscription_controller.dart';
import 'package:the_registry/features/subscriptions/presentation/subscription_copy.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class AddSubscriptionScreen extends StatefulWidget {
  const AddSubscriptionScreen({super.key, this.subscriptionId});

  final String? subscriptionId;

  @override
  State<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends State<AddSubscriptionScreen> {
  late final AddSubscriptionController _controller;
  final TextEditingController _service = TextEditingController();
  final TextEditingController _plan = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  bool _loaded = false;
  bool _missing = false;
  double? _loggedViewInsets;

  bool get _isEditing => widget.subscriptionId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) {
      return;
    }
    _loaded = true;
    final deps = RegistryDependencies.of(context);
    _controller = AddSubscriptionController(clock: deps.clock);
    final id = widget.subscriptionId;
    if (id == null) {
      return;
    }
    final subscription = deps.subscriptions.findById(id);
    if (subscription == null) {
      _missing = true;
      return;
    }
    _controller.loadSubscription(subscription);
    _syncText();
  }

  void _syncText() {
    _service.text = _controller.serviceName;
    _plan.text = _controller.planName;
    _amount.text = _controller.amountText;
    _notes.text = _controller.notes;
  }

  void _flushEditors() {
    _controller.setServiceName(_service.text);
    _controller.setPlanName(_plan.text);
    _controller.setAmountText(_amount.text);
    _controller.setNotes(_notes.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    _service.dispose();
    _plan.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            _isEditing ? l10n.discardChangesTitle : l10n.discardDraftTitle,
          ),
          content: Text(
            _isEditing ? l10n.discardChangesMessage : l10n.discardDraftMessage,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.discardDraftKeep),
            ),
            TextButton(
              key: const ValueKey<String>('discard-confirm'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.discardDraftConfirm),
            ),
          ],
        );
      },
    );
    if (discard == true && mounted) {
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _pickCategory() async {
    final l10n = AppLocalizations.of(context);
    final selected = await RegistrySearchableSheet.show<SubscriptionCategory>(
      context: context,
      title: l10n.fieldCategory,
      selected: _controller.category,
      options: [
        for (final category in SubscriptionCategory.values)
          RegistrySearchableOption(
            value: category,
            label: SubscriptionCopy.category(l10n, category),
            itemKey: 'sub-category-${category.name}',
          ),
      ],
    );
    if (selected != null) {
      _controller.setCategory(selected);
    }
  }

  Future<void> _pickCurrency() async {
    final l10n = AppLocalizations.of(context);
    final selected = await RegistrySearchableSheet.show<String>(
      context: context,
      title: l10n.fieldCurrency,
      selected: _controller.currencyCode,
      options: [
        for (final code in CurrencyInfo.supportedCodes)
          RegistrySearchableOption(
            value: code,
            label: code,
            itemKey: 'currency-$code',
          ),
      ],
    );
    if (selected != null) {
      _controller.setCurrencyCode(selected);
    }
  }

  Future<void> _pickDate(String fieldId) async {
    final deps = RegistryDependencies.of(context);
    final initial = fieldId == 'decide-by'
        ? _controller.decideByDate
        : _controller.nextPaymentDate;
    final picked = await deps.datePicker.pickDate(
      context,
      fieldId: fieldId,
      initialDate: initial,
    );
    if (picked == null) {
      return;
    }
    if (fieldId == 'decide-by') {
      _controller.setDecideByDate(picked);
    } else {
      _controller.setNextPaymentDate(picked);
    }
  }

  bool _dismissKeyboardIfOpen() {
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final editing = FocusManager.instance.primaryFocus is EditableTextState;
    if (insets <= 0 && !editing) {
      return false;
    }
    FocusScope.of(context).unfocus();
    return true;
  }

  Future<void> _save() async {
    _flushEditors();
    final l10n = AppLocalizations.of(context);
    final deps = RegistryDependencies.of(context);
    final saved = await _controller.submit(
      l10n: l10n,
      save: deps.subscriptions.save,
      update: deps.subscriptions.update,
    );
    if (saved && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_missing) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.editSubscriptionTitle)),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: RegistryEmptyState(
            title: l10n.subscriptionUnavailableTitle,
            message: l10n.subscriptionUnavailableMessage,
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
        assert(() {
          if (_loggedViewInsets != viewInsets) {
            _loggedViewInsets = viewInsets;
            debugPrint('AddSubscription viewInsets.bottom=$viewInsets');
          }
          return true;
        }());
        return PopScope(
          canPop: !_controller.isDirty && viewInsets <= 0,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) {
              return;
            }
            if (_dismissKeyboardIfOpen()) {
              return;
            }
            _confirmDiscard();
          },
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              titleSpacing: AppSpacing.xs,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.guidedSetup,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  Text(
                    _isEditing
                        ? l10n.editSubscriptionTitle
                        : l10n.addSubscriptionTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.screenPadding,
                      AppSpacing.sm,
                      AppSpacing.screenPadding,
                      0,
                    ),
                    child: _ProgressHeader(controller: _controller),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: const ValueKey<String>('add-subscription-scroll'),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        AppSpacing.screenPadding,
                        AppSpacing.md,
                        AppSpacing.screenPadding,
                        AppSpacing.xl,
                      ),
                      child: _body(l10n),
                    ),
                  ),
                  _ActionBar(
                    controller: _controller,
                    isEditing: _isEditing,
                    onBack: () {
                      if (_dismissKeyboardIfOpen()) {
                        return;
                      }
                      if (_controller.step == AddSubscriptionStep.service) {
                        if (_controller.isDirty) {
                          _confirmDiscard();
                        } else {
                          Navigator.of(context).pop(false);
                        }
                        return;
                      }
                      _controller.backStep();
                    },
                    onContinue: () {
                      _flushEditors();
                      if (_controller.step == AddSubscriptionStep.review) {
                        _save();
                        return;
                      }
                      _controller.continueStep(l10n);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body(AppLocalizations l10n) {
    return switch (_controller.step) {
      AddSubscriptionStep.service => _ServiceStep(
        controller: _controller,
        service: _service,
        plan: _plan,
        onPickCategory: _pickCategory,
      ),
      AddSubscriptionStep.billing => _BillingStep(
        controller: _controller,
        amount: _amount,
        onPickCurrency: _pickCurrency,
        onPickDate: _pickDate,
      ),
      AddSubscriptionStep.preferences => _PreferencesStep(
        controller: _controller,
        notes: _notes,
        onPickDate: _pickDate,
      ),
      AddSubscriptionStep.review => _ReviewStep(
        controller: _controller,
        onJump: _controller.goToStep,
      ),
    };
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.controller});

  final AddSubscriptionController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = controller.stepIndex + 1;
    return RegistryWizardProgress(
      current: current,
      total: controller.stepCount,
      label: l10n.wizardStepOf(current, controller.stepCount),
      labelKey: const ValueKey<String>('sub-wizard-progress'),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.controller,
    required this.isEditing,
    required this.onBack,
    required this.onContinue,
  });

  final AddSubscriptionController controller;
  final bool isEditing;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onReview = controller.step == AddSubscriptionStep.review;
    final continueLabel = onReview
        ? (isEditing ? l10n.saveChanges : l10n.saveSubscription)
        : l10n.wizardContinue;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.saveError != null) ...[
              Text(
                controller.saveError!,
                key: const ValueKey<String>('subscription-save-error'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.error),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            Row(
              children: [
                if (controller.canGoBack || controller.stepIndex > 0)
                  Expanded(
                    child: RegistrySecondaryButton(
                      key: const ValueKey<String>('sub-wizard-back'),
                      label: l10n.wizardBack,
                      onPressed: controller.saving ? null : onBack,
                    ),
                  ),
                if (controller.canGoBack || controller.stepIndex > 0)
                  const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: RegistryPrimaryButton(
                    key: ValueKey<String>(
                      onReview ? 'save-subscription' : 'sub-wizard-continue',
                    ),
                    label: continueLabel,
                    backgroundColor: scheme.tertiary,
                    foregroundColor: scheme.onTertiary,
                    trailing: onReview
                        ? null
                        : const Icon(Icons.arrow_forward_rounded, size: 18),
                    onPressed: controller.saving ? null : onContinue,
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

class _ServiceStep extends StatelessWidget {
  const _ServiceStep({
    required this.controller,
    required this.service,
    required this.plan,
    required this.onPickCategory,
  });

  final AddSubscriptionController controller;
  final TextEditingController service;
  final TextEditingController plan;
  final VoidCallback onPickCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.subscriptionServiceIntroTitle,
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.subscriptionServiceIntro, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        RegistryTextField(
          label: l10n.fieldServiceName,
          controller: service,
          fieldKey: const ValueKey<String>('field-service-name'),
          requiredField: true,
          errorText: controller.serviceNameError,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          onChanged: controller.setServiceName,
        ),
        const SizedBox(height: AppSpacing.md),
        RegistrySelectorField(
          fieldKey: 'field-subscription-category',
          label: l10n.fieldCategory,
          value: controller.category == null
              ? ''
              : SubscriptionCopy.category(l10n, controller.category!),
          empty: controller.category == null,
          requiredField: true,
          errorText: controller.categoryError,
          placeholder: l10n.chooseOption,
          onTap: onPickCategory,
        ),
        const SizedBox(height: AppSpacing.md),
        RegistryTextField(
          label: l10n.fieldPlanName,
          controller: plan,
          fieldKey: const ValueKey<String>('field-plan-name'),
          helperText: l10n.optionalMarker,
          textCapitalization: TextCapitalization.sentences,
          onChanged: controller.setPlanName,
        ),
      ],
    );
  }
}

class _BillingStep extends StatelessWidget {
  const _BillingStep({
    required this.controller,
    required this.amount,
    required this.onPickCurrency,
    required this.onPickDate,
  });

  final AddSubscriptionController controller;
  final TextEditingController amount;
  final VoidCallback onPickCurrency;
  final ValueChanged<String> onPickDate;

  String? _estimate(AppLocalizations l10n) {
    if (controller.currencyCode == null ||
        controller.billingCycle == null ||
        controller.amountText.trim().isEmpty) {
      return null;
    }
    try {
      final money = MoneyParser.parse(
        controller.amountText,
        controller.currencyCode!,
      );
      final draft = RegistrySubscription(
        id: 'draft',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        serviceName: controller.serviceName,
        category: controller.category ?? SubscriptionCategory.other,
        amount: money,
        billingCycle: controller.billingCycle!,
        nextPaymentDate: controller.nextPaymentDate ?? DateTime(2000),
        autoRenew: controller.autoRenew,
        lifecycle: SubscriptionLifecycle.active,
        impact: DocumentImpact.low,
      );
      final share = SubscriptionEstimate.monthlyShare(draft).roundHalfUp();
      return MoneyFormat.format(share, l10n.localeName);
    } on MoneyParseException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final estimate = _estimate(l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.subscriptionBillingIntroTitle,
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 22),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.subscriptionBillingIntro, style: theme.textTheme.bodyMedium),
        if (controller.serviceName.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          RegistrySurface(
            padding: const EdgeInsets.all(AppSpacing.sm),
            borderRadius: BorderRadius.circular(AppRadius.input),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.lavenderSurface,
                  child: Text(
                    controller.serviceName.trim().substring(0, 1).toUpperCase(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.serviceName.trim(),
                        style: theme.textTheme.titleSmall,
                      ),
                      if (controller.planName.trim().isNotEmpty)
                        Text(
                          controller.planName.trim(),
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        RegistryAmountCurrencyField(
          amountLabel: l10n.fieldAmount,
          currencyLabel: l10n.fieldCurrency,
          amount: amount,
          currencyCode: controller.currencyCode ?? '',
          currencyEmpty: controller.currencyCode == null,
          amountError: controller.amountError,
          currencyError: controller.currencyError,
          onAmountChanged: controller.setAmountText,
          onPickCurrency: onPickCurrency,
        ),
        const SizedBox(height: AppSpacing.md),
        RegistryFieldLabel(label: l10n.fieldBillingCycle, requiredField: true),
        if (controller.cycleError != null)
          Text(
            controller.cycleError!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final cycle in BillingCycle.values)
              RegistrySelectableChip(
                key: ValueKey<String>('cycle-${cycle.name}'),
                label: SubscriptionCopy.cycle(l10n, cycle),
                selected: controller.billingCycle == cycle,
                selectedColor: theme.colorScheme.tertiary,
                selectedForegroundColor: theme.colorScheme.onTertiary,
                showCheckmark: false,
                onSelected: (_) => controller.setBillingCycle(cycle),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        DocumentDateField(
          fieldId: 'next-payment',
          label: l10n.fieldNextPayment,
          value: controller.nextPaymentDate,
          requiredField: true,
          errorText: controller.nextPaymentError,
          helperText: l10n.nextPaymentHelper,
          onTap: () => onPickDate('next-payment'),
        ),
        if (estimate != null) ...[
          const SizedBox(height: AppSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.lavenderSurface,
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.violet, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.estimatedMonthlyCostValue(estimate),
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.estimatedMonthlyDisclaimer,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PreferencesStep extends StatelessWidget {
  const _PreferencesStep({
    required this.controller,
    required this.notes,
    required this.onPickDate,
  });

  final AddSubscriptionController controller;
  final TextEditingController notes;
  final ValueChanged<String> onPickDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.subscriptionPreferencesIntroTitle,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.subscriptionPreferencesIntro,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        DocumentDateField(
          fieldId: 'decide-by',
          label: l10n.fieldDecideBy,
          value: controller.decideByDate,
          errorText: controller.decideByError,
          helperText: l10n.decideByHelper,
          onTap: () => onPickDate('decide-by'),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            key: const ValueKey<String>('clear-decide-by'),
            onPressed: controller.decideByDate == null
                ? null
                : () => controller.setDecideByDate(null),
            child: Text(l10n.clearDecideBy),
          ),
        ),
        SwitchListTile(
          key: const ValueKey<String>('field-auto-renew'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.fieldAutoRenew),
          subtitle: Text(l10n.autoRenewHelper),
          value: controller.autoRenew,
          onChanged: controller.setAutoRenew,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.fieldImpact, style: theme.textTheme.titleSmall),
        if (controller.impactError != null)
          Text(
            controller.impactError!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final impact in DocumentImpact.values)
              RegistrySelectableChip(
                key: ValueKey<String>('sub-impact-${impact.name}'),
                label: DocumentCopy.impact(l10n, impact),
                selected: controller.impact == impact,
                onSelected: (_) => controller.setImpact(impact),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.remindersTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          l10n.subscriptionRemindersHelper,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final reminder in SubscriptionReminder.values)
              RegistrySelectableChip(
                key: ValueKey<String>('sub-reminder-${reminder.name}'),
                label: SubscriptionCopy.reminder(l10n, reminder),
                selected: controller.reminders.contains(reminder),
                onSelected: (_) => controller.toggleReminder(reminder),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        RegistryTextField(
          label: l10n.fieldNotes,
          controller: notes,
          fieldKey: const ValueKey<String>('field-subscription-notes'),
          helperText: l10n.optionalMarker,
          minLines: 3,
          maxLines: 5,
          onChanged: controller.setNotes,
        ),
        const SizedBox(height: AppSpacing.md),
        RegistryCallout(
          tone: RegistryCalloutTone.tip,
          title: l10n.decideByWhyTitle,
          message: l10n.decideByWhyMessage,
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.controller, required this.onJump});

  final AddSubscriptionController controller;
  final ValueChanged<AddSubscriptionStep> onJump;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = l10n.localeName;
    Money? amount;
    try {
      if (controller.currencyCode != null) {
        amount = MoneyParser.parse(
          controller.amountText,
          controller.currencyCode!,
        );
      }
    } on MoneyParseException {
      amount = null;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.subscriptionReviewIntroTitle,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.subscriptionReviewIntro, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        RegistrySurface(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  controller.serviceName.trim(),
                  if (controller.planName.trim().isNotEmpty)
                    controller.planName.trim(),
                ].join(' '),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                [
                  if (controller.category != null)
                    SubscriptionCopy.category(l10n, controller.category!),
                  if (controller.billingCycle != null)
                    SubscriptionCopy.cycle(l10n, controller.billingCycle!),
                ].join(' · '),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              RegistryInfoRow(
                label: l10n.fieldAmount,
                value: amount == null
                    ? controller.amountText
                    : '${MoneyFormat.format(amount, locale)} ${controller.billingCycle == null ? '' : SubscriptionCopy.cycleSuffix(l10n, controller.billingCycle!)}'
                          .trim(),
              ),
              if (controller.nextPaymentDate != null)
                RegistryInfoRow(
                  label: l10n.fieldNextPayment,
                  value: RegistryDateFormatter.dayMonthYear(
                    controller.nextPaymentDate!,
                    locale,
                  ),
                ),
              if (controller.decideByDate != null)
                RegistryInfoRow(
                  label: l10n.fieldDecideBy,
                  value: RegistryDateFormatter.dayMonthYear(
                    controller.decideByDate!,
                    locale,
                  ),
                ),
              RegistryInfoRow(
                label: l10n.fieldAutoRenew,
                value: controller.autoRenew
                    ? l10n.autoRenewOn
                    : l10n.autoRenewOff,
              ),
              if (controller.impact != null)
                RegistryInfoRow(
                  label: l10n.fieldImpact,
                  value: DocumentCopy.impact(l10n, controller.impact!),
                ),
              if (controller.notes.trim().isNotEmpty)
                RegistryInfoRow(
                  label: l10n.fieldNotes,
                  value: controller.notes,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            TextButton(
              key: const ValueKey<String>('review-jump-service'),
              onPressed: () => onJump(AddSubscriptionStep.service),
              child: Text(l10n.reviewJumpService),
            ),
            TextButton(
              key: const ValueKey<String>('review-jump-billing'),
              onPressed: () => onJump(AddSubscriptionStep.billing),
              child: Text(l10n.reviewJumpBilling),
            ),
            TextButton(
              key: const ValueKey<String>('review-jump-preferences'),
              onPressed: () => onJump(AddSubscriptionStep.preferences),
              child: Text(l10n.reviewJumpPreferences),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        RegistryCallout(
          tone: RegistryCalloutTone.privacy,
          message: l10n.subscriptionSessionNote,
        ),
      ],
    );
  }
}
