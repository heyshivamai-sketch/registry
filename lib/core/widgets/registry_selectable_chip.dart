import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_spacing.dart';

/// Material 3 selectable chip with a clear unselected border and checkmark.
class RegistrySelectableChip extends StatelessWidget {
  const RegistrySelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.selectedColor,
    this.selectedForegroundColor,
    this.checkmarkColor,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Color? selectedColor;
  final Color? selectedForegroundColor;
  final Color? checkmarkColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = selected
        ? (selectedColor ?? colorScheme.primaryContainer)
        : colorScheme.surface;
    final foreground = selected
        ? (selectedForegroundColor ?? colorScheme.onPrimaryContainer)
        : colorScheme.onSurface;
    final border = selected
        ? (checkmarkColor ?? colorScheme.primary)
        : colorScheme.outline;

    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: true,
      checkmarkColor: checkmarkColor ?? colorScheme.primary,
      onSelected: onSelected,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      side: BorderSide(color: border, width: selected ? 1.5 : 1),
      backgroundColor: background,
      selectedColor: background,
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        color: foreground,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }
}
