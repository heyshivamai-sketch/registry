import 'package:flutter/material.dart';
import 'package:the_registry/features/documents/presentation/add_document_screen.dart';
import 'package:the_registry/features/profile/presentation/profile_placeholder_screen.dart';
import 'package:the_registry/features/subscriptions/presentation/add_subscription_placeholder_screen.dart';
import 'package:the_registry/l10n/app_localizations.dart';

abstract final class AppRoutes {
  static Future<void> openProfile(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProfilePlaceholderScreen()),
    );
  }

  static Future<bool> openAddDocument(BuildContext context) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AddDocumentScreen()),
    );
    final didSave = saved ?? false;
    if (didSave && context.mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.documentSaved)));
    }
    return didSave;
  }

  static Future<void> openAddSubscription(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AddSubscriptionPlaceholderScreen(),
      ),
    );
  }
}
