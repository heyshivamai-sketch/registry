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
