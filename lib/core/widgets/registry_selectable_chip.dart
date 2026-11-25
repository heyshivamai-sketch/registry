import 'package:flutter/material.dart';
import '../../app/theme/app_spacing.dart';

/// Compact Aura filter/choice chip. Selected state uses the ink surface.
class RegistrySelectableChip extends StatelessWidget {
  const RegistrySelectableChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
    this.selectedColor,
    this.selectedForegroundColor,
    this.checkmarkColor,
    this.showCheckmark = true,
    this.isMultiSelect = false,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Color? selectedColor;
  final Color? selectedForegroundColor;
  final Color? checkmarkColor;
  final bool showCheckmark;

  /// Whether this chip represents a multi-select item (e.g. checkbox behavior).
  ///
  /// When true, renders distinct checkbox icons ([Icons.check_box_rounded] when selected
  /// and [Icons.check_box_outline_blank_rounded] when unselected) to immediately communicate
  /// multi-select behavior and unambiguous selected/unselected states.
  final bool isMultiSelect;

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
      avatar: isMultiSelect
          ? Icon(
              selected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 16,
              color: selected ? foreground : colorScheme.primary,
            )
          : null,
      label: Text(
        label,
        maxLines: 2,
        softWrap: true,
        overflow: TextOverflow.ellipsis,
      ),
      selected: selected,
      showCheckmark: !isMultiSelect && showCheckmark,
      checkmarkColor: checkmarkColor ?? foreground,
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
        width: selected ? 1.5 : 1.0,
      ),
      backgroundColor: background,
      selectedColor: background,
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        color: foreground,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        letterSpacing: 0.1,
        fontSize: 12,
      ),
    );
  }
}
