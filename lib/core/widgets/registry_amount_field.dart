import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_form_field.dart';
import 'package:the_registry/core/widgets/registry_selector_field.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class RegistryAmountCurrencyField extends StatelessWidget {
  const RegistryAmountCurrencyField({
    super.key,
    required this.amountLabel,
    required this.currencyLabel,
    required this.amount,
    required this.currencyCode,
    required this.onAmountChanged,
    required this.onPickCurrency,
    this.amountError,
    this.currencyError,
    this.currencyEmpty = false,
  });

  final String amountLabel;
  final String currencyLabel;
  final TextEditingController amount;
  final String currencyCode;
  final ValueChanged<String> onAmountChanged;
  final VoidCallback onPickCurrency;
  final String? amountError;
  final String? currencyError;
  final bool currencyEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack =
            constraints.maxWidth < 340 ||
            MediaQuery.textScalerOf(context).scale(14) / 14 >= 1.3;
        final amountField = RegistryTextField(
          label: amountLabel,
          controller: amount,
          fieldKey: const ValueKey<String>('field-amount'),
          requiredField: true,
          errorText: amountError,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          onChanged: onAmountChanged,
        );
        final currencyField = RegistrySelectorField(
          fieldKey: 'field-currency',
          label: currencyLabel,
          value: currencyCode,
          empty: currencyEmpty,
          requiredField: true,
          errorText: currencyError,
          placeholder: l10n.chooseOption,
          onTap: onPickCurrency,
        );
        if (stack) {
          return Column(
            children: [
              amountField,
              const SizedBox(height: AppSpacing.md),
              currencyField,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: amountField),
            const SizedBox(width: AppSpacing.sm),
            Expanded(flex: 2, child: currencyField),
          ],
        );
      },
    );
  }
}
