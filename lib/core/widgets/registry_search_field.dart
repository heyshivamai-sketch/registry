import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class RegistrySearchField extends StatelessWidget {
  const RegistrySearchField({
    super.key,
    required this.controller,
    this.hintText,
    this.fieldKey,
    this.clearKey,
  });

  final TextEditingController controller;
  final String? hintText;
  final Key? fieldKey;
  final Key? clearKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final hasQuery = controller.text.isNotEmpty;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.search),
      borderSide: BorderSide(color: colorScheme.outlineVariant),
    );

    return SizedBox(
      height: AppSpacing.searchHeight,
      child: TextField(
        key: fieldKey,
        controller: controller,
        textInputAction: TextInputAction.search,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          hintText: hintText ?? l10n.searchPlaceholder,
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF788198),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colorScheme.onSurfaceVariant,
            size: 22,
          ),
          suffixIcon: hasQuery
              ? IconButton(
                  key: clearKey,
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
            borderRadius: BorderRadius.circular(AppRadius.search),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 0,
          ),
        ),
      ),
    );
  }
}

typedef RegistryAuraSearchField = RegistrySearchField;
