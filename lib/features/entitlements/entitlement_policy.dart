import 'package:the_registry/features/backup/backup_models.dart';
import 'package:the_registry/features/entitlements/registry_plan.dart';
import 'package:the_registry/features/reminders/domain/reminder_plan.dart';

/// Why a new record was refused.
///
/// Existing records are never refused for these reasons.
enum EntitlementDenialKind { documentLimit, subscriptionLimit }

class EntitlementDecision {
  const EntitlementDecision.allow() : denial = null;

  const EntitlementDecision.deny(this.denial);

  final EntitlementDenialKind? denial;

  bool get allowed => denial == null;
}

class EntitlementDenied implements Exception {
  const EntitlementDenied(this.decision);

  final EntitlementDecision decision;

  @override
  String toString() => 'EntitlementDenied(${decision.denial})';
}

/// A create was asked to insert an id that is already stored.
///
/// Editing an existing record must go through update, which keeps the id.
class DuplicateRecordId implements Exception {
  const DuplicateRecordId();
}

/// The only commercial record-count rules in the app.
///
/// Free includes [freeDocumentLimit] documents and [freeSubscriptionLimit]
/// subscription records. Local Pro removes those two limits.
///
/// Technical caps stay in force for every plan: backup size in [BackupLimits],
/// the pending reminder cap [maxPendingLocalReminders], CSV import limits,
/// and whatever space the device has left. This policy does not raise them.
///
/// Viewing, editing, renewing, deleting, reminders, app lock, export, and
/// restore stay available for records that are already stored. Restore is
/// not an admission decision: it must not drop records to fit a plan.
abstract final class EntitlementPolicy {
  static const freeDocumentLimit = 10;
  static const freeSubscriptionLimit = 5;

  static const technicalBackupDocumentCap = BackupLimits.maxDocuments;
  static const technicalBackupSubscriptionCap = BackupLimits.maxSubscriptions;
  static const technicalReminderCap = maxPendingLocalReminders;

  static EntitlementDecision admitDocuments({
    required RegistryPlan plan,
    required int currentCount,
    required int additional,
  }) {
    return _admit(
      plan: plan,
      currentCount: currentCount,
      additional: additional,
      limit: freeDocumentLimit,
      denial: EntitlementDenialKind.documentLimit,
    );
  }

  static EntitlementDecision admitSubscriptions({
    required RegistryPlan plan,
    required int currentCount,
    required int additional,
  }) {
    return _admit(
      plan: plan,
      currentCount: currentCount,
      additional: additional,
      limit: freeSubscriptionLimit,
      denial: EntitlementDenialKind.subscriptionLimit,
    );
  }

  /// Edit, renew, delete, reminders, app lock, export, and restore.
  static EntitlementDecision existingRecordAccess() {
    return const EntitlementDecision.allow();
  }

  static EntitlementDecision _admit({
    required RegistryPlan plan,
    required int currentCount,
    required int additional,
    required int limit,
    required EntitlementDenialKind denial,
  }) {
    if (additional < 0) {
      throw ArgumentError.value(additional, 'additional');
    }
    if (additional == 0 || plan == RegistryPlan.localPro) {
      return const EntitlementDecision.allow();
    }
    if (currentCount + additional > limit) {
      return EntitlementDecision.deny(denial);
    }
    return const EntitlementDecision.allow();
  }
}
