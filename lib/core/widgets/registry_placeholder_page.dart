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
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.all(AppSpacing.screenPadding),
          children: [
            RegistryEmptyState(title: title, message: message, icon: icon),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: RegistryPrimaryButton(
                label: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
