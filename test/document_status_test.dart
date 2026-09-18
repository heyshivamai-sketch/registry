import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/core/widgets/registry_status_chip.dart';
import 'package:the_registry/features/documents/domain/document_status.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/l10n/app_localizations.dart';

import 'support/sample_document.dart';

void main() {
  final now = DateTime(2026, 9, 18);

  RegistryDocument doc({
    DateTime? expiryDate,
    DateTime? actionDate,
    DocumentImpact impact = DocumentImpact.high,
  }) {
    return sampleDocument(
      expiryDate: expiryDate ?? DateTime(2027, 11, 12),
      actionDate: actionDate ?? DateTime(2027, 10, 12),
      impact: impact,
    );
  }

  test('High-impact Active documents are not attention', () {
    final document = doc();
    expect(DocumentStatus.resolve(document, now: now), RegistryStatus.active);
    expect(DocumentStatus.needsAttention(document, now: now), isFalse);
    expect(DocumentStatus.attentionCount([document], now: now), 0);
  });

  test('High-impact Action needed documents are attention', () {
    final document = doc(
      expiryDate: DateTime(2026, 11, 12),
      actionDate: DateTime(2026, 9, 10),
    );
    expect(DocumentStatus.resolve(document, now: now), RegistryStatus.urgent);
    expect(DocumentStatus.needsAttention(document, now: now), isTrue);
    expect(DocumentStatus.attentionCount([document], now: now), 1);
  });

  test('Overdue documents are attention regardless of impact', () {
    final document = doc(
      expiryDate: DateTime(2026, 9, 1),
      actionDate: DateTime(2026, 8, 1),
      impact: DocumentImpact.low,
    );
    expect(DocumentStatus.resolve(document, now: now), RegistryStatus.expired);
    expect(DocumentStatus.needsAttention(document, now: now), isTrue);
    expect(DocumentStatus.attentionCount([document], now: now), 1);
  });

  test('Upcoming is not an attention state', () {
    final document = doc(
      expiryDate: DateTime(2026, 12, 15),
      actionDate: DateTime(2026, 10, 18),
    );
    expect(DocumentStatus.resolve(document, now: now), RegistryStatus.upcoming);
    expect(DocumentStatus.needsAttention(document, now: now), isFalse);
    expect(DocumentStatus.attentionCount([document], now: now), 0);
  });

  test('Impact never changes the attention count on its own', () {
    final activeCritical = doc(impact: DocumentImpact.critical);
    final activeLow = doc(impact: DocumentImpact.low);
    expect(
      DocumentStatus.attentionCount([activeCritical, activeLow], now: now),
      0,
    );
  });

  test('Arabic remaining-days copy uses natural wording and plural forms', () {
    final ar = lookupAppLocalizations(const Locale('ar'));
    final en = lookupAppLocalizations(const Locale('en'));
    final fr = lookupAppLocalizations(const Locale('fr'));

    expect(ar.oneDayRemaining, 'متبقي يوم واحد');
    expect(ar.daysRemaining(2), 'متبقي يومين');
    expect(ar.daysRemaining(5), 'متبقي 5 أيام');
    expect(ar.daysRemaining(55), 'متبقي 55 يومًا');

    expect(en.oneDayRemaining, '1 day remaining');
    expect(en.daysRemaining(2), '2 days remaining');
    expect(en.daysRemaining(5), '5 days remaining');
    expect(en.daysRemaining(55), '55 days remaining');

    expect(fr.oneDayRemaining, '1 jour restant');
    expect(fr.daysRemaining(2), '2 jours restants');
    expect(fr.daysRemaining(5), '5 jours restants');
    expect(fr.daysRemaining(55), '55 jours restants');
  });

  test('Document remainingLabel uses localized remaining copy', () {
    final ar = lookupAppLocalizations(const Locale('ar'));
    String label(int days) {
      return DocumentStatus.remainingLabel(
        ar,
        doc(
          expiryDate: now.add(Duration(days: days + 30)),
          actionDate: now.add(Duration(days: days)),
        ),
        now: now,
      );
    }

    expect(label(1), 'متبقي يوم واحد');
    expect(label(2), 'متبقي يومين');
    expect(label(5), 'متبقي 5 أيام');
    expect(label(55), 'متبقي 55 يومًا');
  });
}
