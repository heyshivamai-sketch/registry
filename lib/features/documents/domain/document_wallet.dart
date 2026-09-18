import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/features/documents/domain/document_status.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/presentation/document_copy.dart';
import 'package:the_registry/l10n/app_localizations.dart';

enum DocumentWalletFilter { all, actionNeeded, upcoming, active, overdue }

abstract final class DocumentWallet {
  static bool matchesQuery(
    RegistryDocument document,
    String query,
    AppLocalizations l10n,
  ) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return true;
    }
    final haystack = <String>[
      document.name,
      DocumentCopy.category(l10n, document.category),
      document.ownerName ?? '',
      document.issuingAuthority ?? '',
      document.maskedDocumentNumber,
      document.documentNumber ?? '',
    ].join(' ').toLowerCase();
    return haystack.contains(needle);
  }

  static bool matchesFilter(
    RegistryDocument document,
    DocumentWalletFilter filter, {
    DateTime? now,
  }) {
    if (filter == DocumentWalletFilter.all) {
      return true;
    }
    final status = DocumentStatus.resolve(document, now: now);
    return switch (filter) {
      DocumentWalletFilter.all => true,
      DocumentWalletFilter.actionNeeded => status == RegistryStatus.urgent,
      DocumentWalletFilter.upcoming => status == RegistryStatus.upcoming,
      DocumentWalletFilter.active => status == RegistryStatus.active,
      DocumentWalletFilter.overdue => status == RegistryStatus.expired,
    };
  }

  static List<RegistryDocument> visible(
    Iterable<RegistryDocument> documents, {
    required String query,
    required DocumentWalletFilter filter,
    required AppLocalizations l10n,
    DateTime? now,
  }) {
    return documents
        .where((document) => matchesQuery(document, query, l10n))
        .where((document) => matchesFilter(document, filter, now: now))
        .toList(growable: false);
  }

  static RegistryDocument? featured(
    Iterable<RegistryDocument> documents, {
    DateTime? now,
  }) {
    if (documents.isEmpty) {
      return null;
    }
    final ranked = [...documents]
      ..sort((a, b) => compareRelevance(a, b, now: now));
    return ranked.first;
  }

  static List<RegistryDocument> remaining(
    Iterable<RegistryDocument> documents, {
    RegistryDocument? featuredDocument,
  }) {
    if (featuredDocument == null) {
      return List<RegistryDocument>.unmodifiable(documents);
    }
    return documents
        .where((document) => document.id != featuredDocument.id)
        .toList(growable: false);
  }

  static int compareRelevance(
    RegistryDocument a,
    RegistryDocument b, {
    DateTime? now,
  }) {
    final rankA = _rank(DocumentStatus.resolve(a, now: now));
    final rankB = _rank(DocumentStatus.resolve(b, now: now));
    if (rankA != rankB) {
      return rankA.compareTo(rankB);
    }
    final byAction = a.displayActionDate.compareTo(b.displayActionDate);
    if (byAction != 0) {
      return byAction;
    }
    final byExpiry = a.expiryDate.compareTo(b.expiryDate);
    if (byExpiry != 0) {
      return byExpiry;
    }
    return a.id.compareTo(b.id);
  }

  static int _rank(RegistryStatus status) {
    return switch (status) {
      RegistryStatus.expired => 0,
      RegistryStatus.urgent => 1,
      RegistryStatus.upcoming => 2,
      RegistryStatus.active => 3,
      RegistryStatus.neutral => 4,
    };
  }
}
