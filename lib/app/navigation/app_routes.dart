import 'package:flutter/material.dart';
import 'package:the_registry/features/documents/presentation/add_document_screen.dart';
import 'package:the_registry/features/documents/presentation/document_detail_screen.dart';
import 'package:the_registry/features/home/data/registry_item.dart';
import 'package:the_registry/features/home/presentation/attention_list_screen.dart';
import 'package:the_registry/features/home/presentation/catalog_item_detail_screen.dart';
import 'package:the_registry/features/home/presentation/horizon_90_day_screen.dart';
import 'package:the_registry/features/notifications/presentation/notifications_screen.dart';
import 'package:the_registry/features/profile/presentation/profile_placeholder_screen.dart';
import 'package:the_registry/features/subscriptions/presentation/add_subscription_screen.dart';
import 'package:the_registry/features/subscriptions/presentation/subscription_detail_screen.dart';
import 'package:the_registry/l10n/app_localizations.dart';

abstract final class AppRoutes {
  static Future<void> openProfile(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProfilePlaceholderScreen()),
    );
  }

  static Future<void> openNotifications(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
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

  static Future<bool> openAddSubscription(BuildContext context) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AddSubscriptionScreen()),
    );
    final didSave = saved ?? false;
    if (didSave && context.mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.subscriptionSaved)));
    }
    return didSave;
  }

  static Future<void> openSubscriptionDetail(BuildContext context, String id) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubscriptionDetailScreen(subscriptionId: id),
      ),
    );
  }

  static Future<bool> openEditSubscription(
    BuildContext context,
    String id,
  ) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddSubscriptionScreen(subscriptionId: id),
      ),
    );
    final didSave = saved ?? false;
    if (didSave && context.mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.subscriptionUpdated)));
    }
    return didSave;
  }

  static Future<void> openRegistryItem(
    BuildContext context,
    RegistryItem item,
  ) {
    if (item.type == RegistryItemType.document) {
      return openDocumentDetail(context, item.sourceId ?? item.id);
    }
    if (item.type == RegistryItemType.subscription) {
      return openSubscriptionDetail(context, item.sourceId ?? item.id);
    }
    return openCatalogItemReview(context, item.id);
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

  static Future<void> openAttentionList(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AttentionListScreen()),
    );
  }

  static Future<void> openHorizon90Day(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const Horizon90DayScreen()));
  }
}
