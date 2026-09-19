import 'package:flutter/material.dart';
import 'package:the_registry/app/theme/app_spacing.dart';
import 'package:the_registry/core/widgets/registry_empty_state.dart';
import 'package:the_registry/core/widgets/registry_primary_button.dart';

class RegistryPlaceholderPage extends StatelessWidget {
  const RegistryPlaceholderPage({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.hourglass_empty_outlined,
    this.embedded = false,
  });

  final String title;
  final String message;
  final IconData icon;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: ListView(
        padding: EdgeInsetsDirectional.fromSTEB(
          AppSpacing.screenPadding,
          AppSpacing.screenPadding,
          AppSpacing.screenPadding,
          embedded
              ? AppSpacing.scrollClearanceForDock(context)
              : AppSpacing.screenPadding,
        ),
        children: [
          if (embedded) ...[
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.md),
          ],
          RegistryEmptyState(title: title, message: message, icon: icon),
          if (!embedded) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: RegistryPrimaryButton(
                label: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ],
      ),
    );

    if (embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: body,
    );
  }
}
