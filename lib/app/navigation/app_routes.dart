import 'package:flutter/material.dart';
import 'package:the_registry/features/documents/presentation/add_document_screen.dart';
import 'package:the_registry/features/documents/presentation/document_detail_screen.dart';
import 'package:the_registry/features/home/presentation/catalog_item_detail_screen.dart';
import 'package:the_registry/features/home/presentation/horizon_90_day_screen.dart';
import 'package:the_registry/features/notifications/presentation/notifications_placeholder_screen.dart';
import 'package:the_registry/features/profile/presentation/profile_placeholder_screen.dart';
import 'package:the_registry/features/subscriptions/presentation/add_subscription_placeholder_screen.dart';
import 'package:the_registry/l10n/app_localizations.dart';

abstract final class AppRoutes {
  static Future<void> openProfile(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProfilePlaceholderScreen()),
    );
  }

  static Future<void> openNotifications(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationsPlaceholderScreen(),
      ),
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

  static Future<void> openDocumentDetail(BuildContext context, String id) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DocumentDetailScreen(documentId: id),
      ),
    );
  }

  static Future<bool> openEditDocument(BuildContext context, String id) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddDocumentScreen(documentId: id),
      ),
    );
    final didSave = saved ?? false;
    if (didSave && context.mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.documentUpdated)));
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

  static Future<void> openCatalogItemReview(
    BuildContext context,
    String itemId,
  ) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CatalogItemDetailScreen(itemId: itemId),
      ),
    );
  }

  static Future<void> openHorizon90Day(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const Horizon90DayScreen()));
  }
}
