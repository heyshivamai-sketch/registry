import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_spacing.dart';

/// Outline selector that keeps the label and selected value on separate lines.
///
/// [InputDecorator] defaults can draw a selected value such as "Other" on top
/// of the floating label. This widget always floats the label and never uses
/// the label (or a fallback such as "Other") as the empty-state value.
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
  });

  final String fieldKey;
  final String label;
  final String value;
  final bool empty;
  final VoidCallback onTap;
  final String? errorText;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shownLabel = requiredField ? '$label *' : label;

    return Semantics(
      button: true,
      label: shownLabel,
      value: empty ? null : value,
      child: InkWell(
        key: ValueKey<String>(fieldKey),
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          isEmpty: empty,
          decoration: InputDecoration(
            labelText: shownLabel,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            errorText: errorText,
            errorMaxLines: 4,
            suffixIcon: const Icon(Icons.arrow_drop_down),
            border: const OutlineInputBorder(),
            alignLabelWithHint: false,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTapTarget - 24,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                empty ? '' : value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
