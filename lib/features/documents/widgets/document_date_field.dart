import 'package:flutter/material.dart';
import 'package:the_registry/core/widgets/registry_form_field.dart';
import 'package:the_registry/features/home/data/registry_date_formatter.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class DocumentDateField extends StatelessWidget {
  const DocumentDateField({
    super.key,
    required this.fieldId,
    required this.label,
    required this.value,
    required this.onTap,
    this.helperText,
    this.errorText,
    this.requiredField = false,
    this.enabled = true,
  });

  final String fieldId;
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String? helperText;
  final String? errorText;
  final bool requiredField;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final empty = value == null;
    final display = empty
        ? l10n.selectDate
        : RegistryDateFormatter.dayMonthYear(value!, l10n.localeName);

    return RegistryLabeledField(
      label: label,
      requiredField: requiredField,
      errorText: errorText,
      helperText: helperText,
      child: Semantics(
        button: enabled,
        label: label,
        value: empty ? null : display,
        child: RegistryFieldSurface(
          key: ValueKey<String>('date-$fieldId'),
          enabled: enabled,
          error: errorText != null,
          onTap: enabled ? onTap : null,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  display,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: empty
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
