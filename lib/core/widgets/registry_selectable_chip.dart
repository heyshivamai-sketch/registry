import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_spacing.dart';

/// Compact Aura filter/choice chip. Selected state uses the ink surface.
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
        ? (selectedColor ?? colorScheme.primary)
        : colorScheme.surfaceContainerLowest;
    final foreground = selected
        ? (selectedForegroundColor ?? colorScheme.onPrimary)
        : colorScheme.onSurfaceVariant;

    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: true,
      onSelected: onSelected,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      side: BorderSide(
        color: selected ? background : colorScheme.outlineVariant,
      ),
      backgroundColor: background,
      selectedColor: background,
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        color: foreground,
        letterSpacing: 0.1,
        fontSize: 12,
      ),
    );
  }
}
