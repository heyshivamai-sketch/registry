import 'package:flutter/material.dart';
import 'package:the_registry/features/entitlements/entitlement_policy.dart';
import 'package:the_registry/l10n/app_localizations.dart';

String entitlementDenialMessage(
  AppLocalizations l10n,
  EntitlementDecision decision,
) {
  return switch (decision.denial) {
    EntitlementDenialKind.documentLimit => l10n.freeLimitDocuments(
      EntitlementPolicy.freeDocumentLimit,
    ),
    EntitlementDenialKind.subscriptionLimit => l10n.freeLimitSubscriptions(
      EntitlementPolicy.freeSubscriptionLimit,
    ),
    null => '',
  };
}

/// Opens Local Pro on top of the current route so a draft stays put.
void showEntitlementLimit(
  BuildContext context,
  EntitlementDecision decision, {
  required VoidCallback onUpgrade,
}) {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(entitlementDenialMessage(l10n, decision)),
        action: SnackBarAction(
          label: l10n.localProAction,
          onPressed: onUpgrade,
        ),
      ),
    );
}
