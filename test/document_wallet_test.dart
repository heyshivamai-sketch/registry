import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/features/documents/domain/document_wallet.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/l10n/app_localizations.dart';

import 'support/sample_document.dart';

void main() {
  final now = DateTime(2026, 9, 18);
  final l10n = lookupAppLocalizations(const Locale('en'));

  RegistryDocument doc({
    required String id,
    required String name,
    required DateTime expiry,
    required DateTime action,
    String? owner,
    String? issuer,
    String? number,
  }) {
    return sampleDocument(
      id: id,
      name: name,
      expiryDate: expiry,
      actionDate: action,
      ownerName: owner,
      issuingAuthority: issuer,
      documentNumber: number,
    );
  }

  test(
    'Featured selection prefers overdue, then action needed, upcoming, active',
    () {
      final active = doc(
        id: 'active',
        name: 'Active',
        expiry: DateTime(2028, 1, 1),
        action: DateTime(2027, 12, 1),
      );
      final upcoming = doc(
        id: 'upcoming',
        name: 'Upcoming',
        expiry: DateTime(2026, 12, 1),
        action: DateTime(2026, 10, 1),
      );
      final urgent = doc(
        id: 'urgent',
        name: 'Urgent',
        expiry: DateTime(2026, 11, 1),
        action: DateTime(2026, 9, 10),
      );
      final overdue = doc(
        id: 'overdue',
        name: 'Overdue',
        expiry: DateTime(2026, 9, 1),
        action: DateTime(2026, 8, 1),
      );

      expect(
        DocumentWallet.featured([
          active,
          upcoming,
          urgent,
          overdue,
        ], now: now)?.id,
        'overdue',
      );
      expect(
        DocumentWallet.featured([active, upcoming, urgent], now: now)?.id,
        'urgent',
      );
      expect(
        DocumentWallet.featured([active, upcoming], now: now)?.id,
        'upcoming',
      );
      expect(DocumentWallet.featured([active], now: now)?.id, 'active');
    },
  );

  test('Same status uses earlier action then expiry then id', () {
    final later = doc(
      id: 'b',
      name: 'Later',
      expiry: DateTime(2026, 9, 10),
      action: DateTime(2026, 8, 10),
    );
    final earlier = doc(
      id: 'a',
      name: 'Earlier',
      expiry: DateTime(2026, 9, 2),
      action: DateTime(2026, 8, 1),
    );

    expect(DocumentWallet.featured([later, earlier], now: now)?.id, 'a');
  });

  test('Remaining excludes the featured document', () {
    final overdue = doc(
      id: 'overdue',
      name: 'Overdue',
      expiry: DateTime(2026, 9, 1),
      action: DateTime(2026, 8, 1),
    );
    final active = doc(
      id: 'active',
      name: 'Active',
      expiry: DateTime(2028, 1, 1),
      action: DateTime(2027, 12, 1),
    );
    final featured = DocumentWallet.featured([overdue, active], now: now);
    final remaining = DocumentWallet.remaining([
      overdue,
      active,
    ], featuredDocument: featured);
    expect(featured?.id, 'overdue');
    expect(remaining.map((item) => item.id), ['active']);
  });

  test('Search matches name, type, owner, issuer and numbers only', () {
    final passport = doc(
      id: 'p',
      name: 'Family passport',
      expiry: DateTime(2027, 1, 1),
      action: DateTime(2026, 12, 1),
      owner: 'Amira',
      issuer: 'Algeria',
      number: 'AB12345678',
    );

    expect(DocumentWallet.matchesQuery(passport, 'family', l10n), isTrue);
    expect(DocumentWallet.matchesQuery(passport, 'passport', l10n), isTrue);
    expect(DocumentWallet.matchesQuery(passport, 'amira', l10n), isTrue);
    expect(DocumentWallet.matchesQuery(passport, 'algeria', l10n), isTrue);
    expect(DocumentWallet.matchesQuery(passport, '5678', l10n), isTrue);
    expect(DocumentWallet.matchesQuery(passport, 'ab12', l10n), isTrue);
    expect(
      DocumentWallet.matchesQuery(passport, 'travel disruption', l10n),
      isFalse,
    );
  });
}
