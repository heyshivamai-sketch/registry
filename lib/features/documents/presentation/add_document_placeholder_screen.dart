import 'package:flutter/material.dart';
import 'package:the_registry/core/widgets/registry_placeholder_page.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class AddDocumentPlaceholderScreen extends StatelessWidget {
  const AddDocumentPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RegistryPlaceholderPage(
      title: l10n.addDocumentTitle,
      message: l10n.addDocumentMessage,
      icon: Icons.description_outlined,
    );
  }
}
