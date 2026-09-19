import 'package:flutter/material.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_empty_state.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/core/widgets/registry_secondary_button.dart';
import 'package:the_registry/core/widgets/registry_selectable_chip.dart';
import 'package:the_registry/core/widgets/registry_selector_field.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/presentation/document_copy.dart';
import 'package:the_registry/features/documents/widgets/document_date_field.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
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
    final selected = await showModalBottomSheet<SubscriptionCategory>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.screenPadding,
                  0,
                  AppSpacing.screenPadding,
                  AppSpacing.sm,
                ),
                child: Text(
                  l10n.fieldCategory,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              for (final category in SubscriptionCategory.values)
                ListTile(
                  key: ValueKey<String>('sub-category-${category.name}'),
                  title: Text(SubscriptionCopy.category(l10n, category)),
                  selected: _controller.category == category,
                  onTap: () => Navigator.of(sheetContext).pop(category),
                ),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      _controller.setCategory(selected);
    }
  }

  Future<void> _pickCurrency() async {
    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.screenPadding,
                  0,
                  AppSpacing.screenPadding,
                  AppSpacing.sm,
                ),
                child: Text(
                  l10n.fieldCurrency,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              for (final code in CurrencyInfo.supportedCodes)
                ListTile(
                  key: ValueKey<String>('currency-$code'),
                  title: Text(code),
                  selected: _controller.currencyCode == code,
                  onTap: () => Navigator.of(sheetContext).pop(code),
                ),
            ],
          ),
        );
      },
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

  InputDecoration _decoration({
    required String label,
    String? errorText,
    String? helperText,
    bool requiredField = false,
  }) {
    return InputDecoration(
      labelText: requiredField ? '$label *' : label,
      errorText: errorText,
      errorMaxLines: 4,
      helperText: helperText,
      helperMaxLines: 4,
      border: const OutlineInputBorder(),
    );
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
        decoration: _decoration,
        onPickCategory: _pickCategory,
      ),
      AddSubscriptionStep.billing => _BillingStep(
        controller: _controller,
        amount: _amount,
        decoration: _decoration,
        onPickCurrency: _pickCurrency,
        onPickDate: _pickDate,
      ),
      AddSubscriptionStep.preferences => _PreferencesStep(
        controller: _controller,
        notes: _notes,
        decoration: _decoration,
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
    final theme = Theme.of(context);
    final current = controller.stepIndex + 1;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: current / controller.stepCount,
              minHeight: 5,
              backgroundColor: const Color(0xFFE1E3EB),
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          l10n.wizardStepOf(current, controller.stepCount),
          key: const ValueKey<String>('sub-wizard-progress'),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0,
          ),
        ),
      ],
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

    return Material(
      color: Theme.of(context).colorScheme.surface,
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
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
    required this.decoration,
    required this.onPickCategory,
  });

  final AddSubscriptionController controller;
  final TextEditingController service;
  final TextEditingController plan;
  final InputDecoration Function({
    required String label,
    String? errorText,
    String? helperText,
    bool requiredField,
  })
  decoration;
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
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.subscriptionServiceIntro, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const ValueKey<String>('field-service-name'),
          controller: service,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          scrollPadding: AppSpacing.wizardFieldScrollPadding,
          onChanged: controller.setServiceName,
          decoration: decoration(
            label: l10n.fieldServiceName,
            errorText: controller.serviceNameError,
            requiredField: true,
          ),
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
          onTap: onPickCategory,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const ValueKey<String>('field-plan-name'),
          controller: plan,
          textCapitalization: TextCapitalization.sentences,
          scrollPadding: AppSpacing.wizardFieldScrollPadding,
          onChanged: controller.setPlanName,
          decoration: decoration(
            label: l10n.fieldPlanName,
            helperText: l10n.optionalMarker,
          ),
        ),
      ],
    );
  }
}

class _BillingStep extends StatelessWidget {
  const _BillingStep({
    required this.controller,
    required this.amount,
    required this.decoration,
    required this.onPickCurrency,
    required this.onPickDate,
  });

  final AddSubscriptionController controller;
  final TextEditingController amount;
  final InputDecoration Function({
    required String label,
    String? errorText,
    String? helperText,
    bool requiredField,
  })
  decoration;
  final VoidCallback onPickCurrency;
  final ValueChanged<String> onPickDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.subscriptionBillingIntroTitle,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.subscriptionBillingIntro, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const ValueKey<String>('field-amount'),
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          scrollPadding: AppSpacing.wizardFieldScrollPadding,
          onChanged: controller.setAmountText,
          decoration: decoration(
            label: l10n.fieldAmount,
            errorText: controller.amountError,
            requiredField: true,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        RegistrySelectorField(
          fieldKey: 'field-currency',
          label: l10n.fieldCurrency,
          value: controller.currencyCode ?? '',
          empty: controller.currencyCode == null,
          requiredField: true,
          errorText: controller.currencyError,
          onTap: onPickCurrency,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.fieldBillingCycle, style: theme.textTheme.titleSmall),
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
      ],
    );
  }
}

class _PreferencesStep extends StatelessWidget {
  const _PreferencesStep({
    required this.controller,
    required this.notes,
    required this.decoration,
    required this.onPickDate,
  });

  final AddSubscriptionController controller;
  final TextEditingController notes;
  final InputDecoration Function({
    required String label,
    String? errorText,
    String? helperText,
    bool requiredField,
  })
  decoration;
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
        TextField(
          key: const ValueKey<String>('field-subscription-notes'),
          controller: notes,
          minLines: 3,
          maxLines: 5,
          scrollPadding: AppSpacing.wizardFieldScrollPadding,
          onChanged: controller.setNotes,
          decoration: decoration(
            label: l10n.fieldNotes,
            helperText: l10n.optionalMarker,
          ),
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
