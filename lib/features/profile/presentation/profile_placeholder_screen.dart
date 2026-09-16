import 'package:flutter/material.dart';
import 'package:the_registry/core/widgets/registry_placeholder_page.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class ProfilePlaceholderScreen extends StatelessWidget {
  const ProfilePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RegistryPlaceholderPage(
      title: l10n.profileTitle,
      message: l10n.profileMessage,
      icon: Icons.person_outline_rounded,
    );
  }
}
