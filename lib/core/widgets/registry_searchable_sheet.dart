import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_search_field.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class RegistrySearchableOption<T> {
  const RegistrySearchableOption({
    required this.value,
    required this.label,
    required this.itemKey,
  });

  final T value;
  final String label;
  final String itemKey;
}

abstract final class RegistrySearchableSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<RegistrySearchableOption<T>> options,
    T? selected,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _SearchableSheetBody<T>(
          title: title,
          options: options,
          selected: selected,
        );
      },
    );
  }
}

class _SearchableSheetBody<T> extends StatefulWidget {
  const _SearchableSheetBody({
    required this.title,
    required this.options,
    this.selected,
  });

  final String title;
  final List<RegistrySearchableOption<T>> options;
  final T? selected;

  @override
  State<_SearchableSheetBody<T>> createState() =>
      _SearchableSheetBodyState<T>();
}

class _SearchableSheetBodyState<T> extends State<_SearchableSheetBody<T>> {
  final TextEditingController _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final needle = _query.text.trim().toLowerCase();
    final filtered = needle.isEmpty
        ? widget.options
        : [
            for (final option in widget.options)
              if (option.label.toLowerCase().contains(needle)) option,
          ];
    final height = MediaQuery.sizeOf(context).height * 0.7;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.screenPadding,
                0,
                AppSpacing.screenPadding,
                AppSpacing.sm,
              ),
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: RegistrySearchField(
                controller: _query,
                hintText: l10n.searchListHint,
                fieldKey: const ValueKey<String>('sheet-search'),
                clearKey: const ValueKey<String>('sheet-search-clear'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final option = filtered[index];
                  return ListTile(
                    key: ValueKey<String>(option.itemKey),
                    title: Text(option.label),
                    selected: option.value == widget.selected,
                    onTap: () => Navigator.of(context).pop(option.value),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
