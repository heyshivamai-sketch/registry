import 'package:flutter/material.dart';
import 'package:the_registry/core/widgets/registry_form_field.dart';

/// Filled selector with a persistent label above the value, never overlaid.
class RegistrySelectorField extends StatelessWidget {
  const RegistrySelectorField({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.empty,
    required this.onTap,
    this.errorText,
    this.requiredField = false,
    this.enabled = true,
    this.placeholder,
    this.trailingIcon = Icons.expand_more,
  });

  final String fieldKey;
  final String label;
  final String value;
  final bool empty;
  final VoidCallback onTap;
  final String? errorText;
  final bool requiredField;
  final bool enabled;
  final String? placeholder;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shownLabel = requiredField ? '$label *' : label;
    final display = empty ? (placeholder ?? '') : value;

    return RegistryLabeledField(
      key: ValueKey<String>(fieldKey),
      label: label,
      requiredField: requiredField,
      errorText: errorText,
      child: Semantics(
        button: enabled,
        label: shownLabel,
        value: empty ? null : value,
        child: RegistryFieldSurface(
          enabled: enabled,
          error: errorText != null,
          onTap: enabled ? onTap : null,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  display,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: empty
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(trailingIcon, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
