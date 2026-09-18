import 'package:flutter/material.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';

abstract final class DocumentIcons {
  static IconData forCategory(DocumentCategory category) {
    return switch (category) {
      DocumentCategory.passport => Icons.badge_outlined,
      DocumentCategory.idCard => Icons.badge_outlined,
      DocumentCategory.drivingLicence => Icons.credit_card_outlined,
      DocumentCategory.insurance => Icons.health_and_safety_outlined,
      DocumentCategory.visaResidence => Icons.flight_takeoff_outlined,
      DocumentCategory.certificate => Icons.workspace_premium_outlined,
      DocumentCategory.warranty => Icons.verified_outlined,
      DocumentCategory.other => Icons.description_outlined,
    };
  }
}
