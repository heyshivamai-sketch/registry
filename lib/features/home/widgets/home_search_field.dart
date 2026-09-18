import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_motion.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class HomeSearchField extends StatelessWidget {
  const HomeSearchField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final hasQuery = controller.text.isNotEmpty;
    final border = OutlineInputBorder(
      borderRadius: AppRadius.lgBorder,
      borderSide: BorderSide(color: colorScheme.outlineVariant),
    );

    return AnimatedContainer(
      duration: AppMotion.short,
      curve: Curves.easeOut,
      child: TextField(
        key: const ValueKey<String>('home-search'),
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: l10n.searchPlaceholder,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          suffixIcon: hasQuery
              ? IconButton(
                  key: const ValueKey<String>('home-search-clear'),
                  tooltip: l10n.searchClear,
                  onPressed: controller.clear,
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          filled: true,
          fillColor: colorScheme.surfaceContainerLowest,
          border: border,
          enabledBorder: border,
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.lgBorder,
            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
    );
  }
}
