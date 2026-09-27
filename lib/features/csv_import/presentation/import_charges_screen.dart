import 'dart:async';

import 'package:flutter/material.dart';
import 'package:the_registry/app/registry_dependencies.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';
import 'package:the_registry/core/widgets/registry_selector_field.dart';
import 'package:the_registry/core/widgets/registry_surface.dart';
import 'package:the_registry/features/csv_import/csv_charge_import.dart';
import 'package:the_registry/features/csv_import/csv_import_limits.dart';
import 'package:the_registry/features/entitlements/entitlement_copy.dart';
import 'package:the_registry/features/entitlements/entitlement_policy.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/presentation/subscription_copy.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class ImportChargesScreen extends StatefulWidget {
  const ImportChargesScreen({super.key});

  @override
  State<ImportChargesScreen> createState() => _ImportChargesScreenState();
}

class _ImportChargesScreenState extends State<ImportChargesScreen> {
  CsvChargeImportSession? _session;
  var _working = false;

  CsvChargeImportSession _requireSession() {
    final existing = _session;
    if (existing != null) {
      return existing;
    }
    final deps = RegistryDependencies.of(context);
    final created = CsvChargeImportSession(
      subscriptions: deps.subscriptions,
      writes: deps.writes,
      clock: deps.clock,
    );
    _session = created;
    return created;
  }

  Future<void> _pick() async {
    if (_working) {
      return;
    }
    setState(() => _working = true);
    final session = _requireSession();
    try {
      final bytes = await RegistryDependencies.of(context).csvFiles.pickCsv();
      if (!mounted) {
        return;
      }
      setState(() => session.loadBytes(bytes));
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  Future<void> _confirm() async {
    if (_working) {
      return;
    }
    final session = _session;
    if (session == null) {
      return;
    }
    setState(() => _working = true);
    final l10n = AppLocalizations.of(context);
    try {
      final saved = await session.confirm(note: l10n.csvSuggestionNote);
      if (!mounted) {
        return;
      }
      if (saved) {
        Navigator.of(context).pop(session.savedCount);
      } else {
        setState(() {});
      }
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  Future<void> _edit(RecurringChargeCandidate candidate) async {
    final l10n = AppLocalizations.of(context);
    final merchant = TextEditingController(text: candidate.merchant);
    final amount = TextEditingController(text: '${candidate.minorUnits}');
    final date = TextEditingController(
      text: _isoDate(candidate.nextPaymentDate),
    );
    var currency = candidate.currencyCode;
    var cycle = candidate.cycle;
    var error = false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(l10n.csvEditCandidate),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      key: const ValueKey<String>('csv-edit-merchant'),
                      controller: merchant,
                      decoration: InputDecoration(
                        labelText: l10n.csvMerchantLabel,
                      ),
                    ),
                    TextField(
                      key: const ValueKey<String>('csv-edit-amount'),
                      controller: amount,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.csvAmountMinorLabel,
                      ),
                    ),
                    TextField(
                      key: const ValueKey<String>('csv-edit-date'),
                      controller: date,
                      decoration: InputDecoration(
                        labelText: l10n.csvNextDateLabel,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButton<String>(
                      key: const ValueKey<String>('csv-edit-currency'),
                      isExpanded: true,
                      value: currency,
                      items: [
                        for (final code in CurrencyInfo.supportedCodes)
                          DropdownMenuItem(value: code, child: Text(code)),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => currency = value);
                        }
                      },
                    ),
                    DropdownButton<BillingCycle>(
                      key: const ValueKey<String>('csv-edit-cycle'),
                      isExpanded: true,
                      value: cycle,
                      items: [
                        for (final item in BillingCycle.values)
                          DropdownMenuItem(
                            value: item,
                            child: Text(SubscriptionCopy.cycle(l10n, item)),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => cycle = value);
                        }
                      },
                    ),
                    if (error)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          l10n.csvInvalidCandidate,
                          style: TextStyle(
                            color: Theme.of(dialogContext).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.backupCancel),
                ),
                TextButton(
                  key: const ValueKey<String>('csv-edit-save'),
                  onPressed: () {
                    final accepted = _requireSession().updateCandidate(
                      id: candidate.id,
                      merchant: merchant.text,
                      minorUnitsText: amount.text,
                      currencyCode: currency,
                      cycle: cycle,
                      nextDateText: date.text,
                    );
                    if (!accepted) {
                      setDialogState(() => error = true);
                      return;
                    }
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: Text(l10n.csvEditSave),
                ),
              ],
            );
          },
        );
      },
    );
    merchant.dispose();
    amount.dispose();
    date.dispose();
    if (saved == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = _session;
    final step = session?.step ?? CsvImportStep.choose;
    return PopScope(
      canPop: step == CsvImportStep.choose,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || session == null) {
          return;
        }
        setState(session.back);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.csvImportTitle)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              AppSpacing.screenPadding,
            ),
            children: [
              if (session != null && session.notice != CsvImportNotice.none)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    key: const ValueKey<String>('csv-notice'),
                    _notice(l10n, session.notice),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              if (step == CsvImportStep.choose) ..._choose(l10n),
              if (step == CsvImportStep.map && session != null)
                ..._mapping(l10n, session),
              if (step == CsvImportStep.review && session != null)
                ..._review(l10n, session),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _choose(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return [
      Text(l10n.csvImportIntro, style: theme.textTheme.bodyLarge),
      const SizedBox(height: AppSpacing.md),
      RegistrySurface(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.csvFormatTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.csvFormatBody(
                CsvImportLimits.maxFileBytes ~/ (1024 * 1024),
                CsvImportLimits.maxDataRows,
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      RegistryPrimaryButton(
        key: const ValueKey<String>('csv-choose-file'),
        label: l10n.csvChooseFile,
        onPressed: _working ? null : () => unawaited(_pick()),
      ),
    ];
  }

  List<Widget> _mapping(AppLocalizations l10n, CsvChargeImportSession session) {
    final headers = session.table?.headers ?? const <String>[];
    return [
      Text(l10n.csvMapTitle, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: AppSpacing.sm),
      Text(l10n.csvMapHelp, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: AppSpacing.md),
      _columnField(
        fieldKey: 'csv-date-column',
        label: l10n.csvMapDate,
        headers: headers,
        selected: session.mapping.date,
        onSelected: (index) => setState(() => session.setDateColumn(index)),
      ),
      _columnField(
        fieldKey: 'csv-merchant-column',
        label: l10n.csvMapMerchant,
        headers: headers,
        selected: session.mapping.merchant,
        onSelected: (index) => setState(() => session.setMerchantColumn(index)),
      ),
      _columnField(
        fieldKey: 'csv-amount-column',
        label: l10n.csvMapAmount,
        headers: headers,
        selected: session.mapping.amount,
        onSelected: (index) => setState(() => session.setAmountColumn(index)),
      ),
      _columnField(
        fieldKey: 'csv-currency-column',
        label: l10n.csvMapCurrency,
        headers: headers,
        selected: session.mapping.currency,
        onSelected: (index) => setState(() => session.setCurrencyColumn(index)),
      ),
      const SizedBox(height: AppSpacing.lg),
      RegistryPrimaryButton(
        key: const ValueKey<String>('csv-continue'),
        label: l10n.csvContinue,
        onPressed: () => setState(session.continueFromMapping),
      ),
    ];
  }

  Widget _columnField({
    required String fieldKey,
    required String label,
    required List<String> headers,
    required int? selected,
    required ValueChanged<int> onSelected,
  }) {
    final value = selected == null ? '' : headers[selected];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: RegistrySelectorField(
        fieldKey: fieldKey,
        label: label,
        value: value,
        empty: selected == null,
        placeholder: label,
        onTap: () async {
          final chosen = await showModalBottomSheet<int>(
            context: context,
            showDragHandle: true,
            builder: (sheetContext) {
              return SafeArea(
                child: ListView(
                  children: [
                    for (var index = 0; index < headers.length; index++)
                      ListTile(
                        key: ValueKey<String>('$fieldKey-$index'),
                        title: Text(headers[index]),
                        onTap: () => Navigator.of(sheetContext).pop(index),
                      ),
                  ],
                ),
              );
            },
          );
          if (chosen != null) {
            onSelected(chosen);
          }
        },
      ),
    );
  }

  List<Widget> _review(AppLocalizations l10n, CsvChargeImportSession session) {
    final theme = Theme.of(context);
    final locale = l10n.localeName;
    return [
      Text(l10n.csvSuggestionsTitle, style: theme.textTheme.titleMedium),
      const SizedBox(height: AppSpacing.sm),
      Text(l10n.csvSuggestionsBody, style: theme.textTheme.bodyMedium),
      if (session.skippedLines.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.csvRowErrors(session.skippedLines.length),
          style: theme.textTheme.bodyMedium,
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      for (final candidate in session.candidates) ...[
        RegistrySurface(
          key: ValueKey<String>('csv-candidate-${candidate.id}'),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: candidate.selected,
                onChanged: (value) {
                  setState(
                    () => session.setSelected(candidate.id, value ?? false),
                  );
                },
                title: Text(candidate.merchant),
                subtitle: Text(
                  '${MoneyFormat.format(Money(minorUnits: candidate.minorUnits, currencyCode: candidate.currencyCode), locale)} · ${SubscriptionCopy.cycle(l10n, candidate.cycle)}',
                ),
              ),
              Text(
                l10n.csvSourceRows(candidate.sourceRows.join(', ')),
                style: theme.textTheme.bodySmall,
              ),
              Text(
                l10n.csvNextDate(_isoDate(candidate.nextPaymentDate)),
                style: theme.textTheme.bodySmall,
              ),
              if (candidate.possibleDuplicate)
                Text(
                  l10n.csvDuplicate,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  key: ValueKey<String>('csv-edit-${candidate.id}'),
                  onPressed: () => unawaited(_edit(candidate)),
                  child: Text(l10n.csvEditCandidate),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      if (session.candidates.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        RegistryPrimaryButton(
          key: const ValueKey<String>('csv-confirm'),
          label: l10n.csvConfirmCreate,
          onPressed: _working ? null : () => unawaited(_confirm()),
        ),
      ],
    ];
  }

  String _notice(AppLocalizations l10n, CsvImportNotice notice) {
    return switch (notice) {
      CsvImportNotice.none => '',
      CsvImportNotice.cancelled => l10n.csvCancelled,
      CsvImportNotice.tooLarge => l10n.csvFileTooLarge,
      CsvImportNotice.tooManyRows => l10n.csvTooManyRows(
        CsvImportLimits.maxDataRows,
      ),
      CsvImportNotice.tooManyColumns => l10n.csvTooManyColumns(
        CsvImportLimits.maxColumns,
      ),
      CsvImportNotice.invalidFile => l10n.csvInvalidFile,
      CsvImportNotice.columnsRequired => l10n.csvMapRequired,
      CsvImportNotice.noCharges => l10n.csvNoCharges,
      CsvImportNotice.noSuggestions => l10n.csvNoSuggestions,
      CsvImportNotice.nothingSelected => l10n.csvNothingSelected,
      CsvImportNotice.subscriptionLimit => entitlementDenialMessage(
        l10n,
        const EntitlementDecision.deny(EntitlementDenialKind.subscriptionLimit),
      ),
      CsvImportNotice.duplicateId => l10n.recordAlreadyExists,
    };
  }
}

String _isoDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
