import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class HomeSearchField extends StatelessWidget {
  const HomeSearchField({
    super.key,
    required this.controller,
    required this.onFilter,
  });

  final TextEditingController controller;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final hasQuery = controller.text.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const ValueKey<String>('home-search'),
            controller: controller,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.searchPlaceholder,
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: colorScheme.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: AppRadius.cardBorder,
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.cardBorder,
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        if (hasQuery) ...[
          IconButton(
            key: const ValueKey<String>('home-search-clear'),
            tooltip: l10n.searchClear,
            onPressed: controller.clear,
            icon: const Icon(Icons.close_rounded),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        Material(
          color: colorScheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonBorder,
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: IconButton(
            key: const ValueKey<String>('home-filter'),
            tooltip: l10n.filterTooltip,
            onPressed: onFilter,
            icon: const Icon(Icons.tune_rounded),
          ),
        ),
      ],
    );
  }
}
