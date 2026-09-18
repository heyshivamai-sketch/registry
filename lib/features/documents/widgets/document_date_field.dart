import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
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
    final colorScheme = theme.colorScheme;
    final display = value == null
        ? l10n.selectDate
        : RegistryDateFormatter.dayMonthYear(value!, l10n.localeName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: enabled,
          label: label,
          child: InkWell(
            key: ValueKey<String>('date-$fieldId'),
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: requiredField ? '$label *' : label,
                errorText: errorText,
                errorMaxLines: 4,
                helperMaxLines: 4,
                suffixIcon: enabled
                    ? const Icon(Icons.calendar_today_outlined)
                    : null,
                border: const OutlineInputBorder(),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Text(display, style: theme.textTheme.bodyLarge),
              ),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.sm,
            ),
            child: Text(
              helperText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
