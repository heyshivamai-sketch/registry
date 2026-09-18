import 'package:flutter/material.dart';
import 'package:the_registry/core/widgets/registry_placeholder_page.dart';
import 'package:the_registry/l10n/app_localizations.dart';

class NotificationsPlaceholderScreen extends StatelessWidget {
  const NotificationsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RegistryPlaceholderPage(
      title: l10n.notificationsTitle,
      message: l10n.notificationsPlaceholderMessage,
      icon: Icons.notifications_outlined,
    );
  }
}
