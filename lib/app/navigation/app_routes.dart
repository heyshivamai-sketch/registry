import 'package:flutter/material.dart';
import 'package:the_registry/features/documents/presentation/add_document_placeholder_screen.dart';
import 'package:the_registry/features/profile/presentation/profile_placeholder_screen.dart';
import 'package:the_registry/features/subscriptions/presentation/add_subscription_placeholder_screen.dart';

abstract final class AppRoutes {
  static Future<void> openProfile(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProfilePlaceholderScreen()),
    );
  }

  static Future<void> openAddDocument(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AddDocumentPlaceholderScreen(),
      ),
    );
  }

  static Future<void> openAddSubscription(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AddSubscriptionPlaceholderScreen(),
      ),
    );
  }
}
