import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/csv_import/csv_charge_import.dart';
import 'package:the_registry/features/csv_import/csv_import_limits.dart';
import 'package:the_registry/features/csv_import/presentation/import_charges_screen.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/entitlements/entitlement_service.dart';
import 'package:the_registry/features/entitlements/local_pro_entitlement.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';

import 'support/fake_onboarding_repository.dart';
import 'support/phase2_fakes.dart';
import 'support/sample_subscription.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CsvChargeImportSession sessionFor(
    InMemorySubscriptionRepository subscriptions,
  ) {
    final documents = InMemoryDocumentRepository();
    return CsvChargeImportSession(
      subscriptions: subscriptions,
      writes: RegistryWrites(
        documents: documents,
        subscriptions: subscriptions,
        entitlements: EntitlementService(
          documents: documents,
          subscriptions: subscriptions,
          source: LocalProEntitlement.disabled(),
        ),
      ),
      clock: FixedClock(DateTime(2026, 4, 2)),
    );
  }

  test(
    'documented CSV suggests recurrence and saves only after confirmation',
    () async {
      final subscriptions = InMemorySubscriptionRepository();
      final session = sessionFor(subscriptions);
      session.loadBytes(
        _csv('''
date,merchant,amount_minor,currency
2026-01-01,City Gym,3500,USD
2026-02-01,City Gym,3500,usd
2026-03-01,"City, Gym",12.50,USD
2026-01-03,One Off,1000,EUR
'''),
      );
      expect(session.step, CsvImportStep.map);
      expect(session.mapping.isComplete, isTrue);
      session.continueFromMapping();
      expect(session.candidates, hasLength(1));
      final candidate = session.candidates.single;
      expect(candidate.merchant, 'City Gym');
      expect(candidate.cycle, BillingCycle.monthly);
      expect(candidate.nextPaymentDate, DateTime(2026, 3, 1));
      expect(candidate.sourceRows, [2, 3]);
      expect(candidate.selected, isTrue);
      expect(session.skippedLines, [4]);

      session.setSelected(candidate.id, false);
      expect(await session.confirm(note: 'no'), isFalse);
      expect(subscriptions.subscriptions, isEmpty);
      expect(session.notice, CsvImportNotice.nothingSelected);

      session.setSelected(candidate.id, true);
      expect(
        session.updateCandidate(
          id: candidate.id,
          merchant: 'City Gym',
          minorUnitsText: '3600',
          currencyCode: 'USD',
          cycle: BillingCycle.monthly,
          nextDateText: '2026-04-15',
        ),
        isTrue,
      );
      expect(await session.confirm(note: 'Suggested only'), isTrue);
      expect(subscriptions.subscriptions, hasLength(1));
      expect(subscriptions.subscriptions.single.amount.minorUnits, 3600);
      expect(subscriptions.subscriptions.single.notes, 'Suggested only');
      expect(subscriptions.subscriptions.single.id, startsWith('csv_'));
    },
  );

  test(
    'invalid files, duplicates, and the free limit leave the repository unchanged',
    () async {
      final subscriptions = InMemorySubscriptionRepository();
      await subscriptions.save(
        sampleSubscription(serviceName: 'City Gym', minorUnits: 3500),
      );
      final session = sessionFor(subscriptions);
      session.loadBytes(null);
      expect(session.notice, CsvImportNotice.cancelled);
      expect(subscriptions.subscriptions, hasLength(1));

      session.loadBytes(Uint8List(CsvImportLimits.maxFileBytes + 1));
      expect(session.notice, CsvImportNotice.tooLarge);

      final wide = List.filled(CsvImportLimits.maxColumns + 1, 'h').join(',');
      session.loadBytes(_csv(wide));
      expect(session.notice, CsvImportNotice.tooManyColumns);

      session.loadBytes(_csv('date,merchant\n"unterminated'));
      expect(session.notice, CsvImportNotice.invalidFile);

      session.loadBytes(
        _csv('''
date,merchant,amount_minor,currency
2026-01-01,City Gym,3500,USD
2026-02-01,City Gym,3500,USD
'''),
      );
      session.continueFromMapping();
      expect(session.candidates.single.possibleDuplicate, isTrue);
      expect(session.candidates.single.selected, isFalse);
      expect(await session.confirm(note: 'no'), isFalse);
      expect(subscriptions.subscriptions, hasLength(1));

      for (var index = 0; index < 4; index++) {
        await subscriptions.save(
          sampleSubscription(id: 'other_$index', serviceName: 'Other $index'),
        );
      }
      expect(subscriptions.subscriptions, hasLength(5));
      final limited = sessionFor(subscriptions);
      limited.loadBytes(
        _csv('''
date,merchant,amount_minor,currency
2026-01-05,News,900,EUR
2026-02-05,News,900,EUR
'''),
      );
      limited.continueFromMapping();
      expect(limited.candidates.single.selected, isTrue);
      expect(await limited.confirm(note: 'no'), isFalse);
      expect(limited.notice, CsvImportNotice.subscriptionLimit);
      expect(subscriptions.subscriptions, hasLength(5));
    },
  );

  test('irregular charges are not treated as confirmed subscriptions', () {
    final suggested = suggestRecurringCharges(
      charges: [
        _charge(1, DateTime(2026, 1, 1), 'Cafe'),
        _charge(2, DateTime(2026, 1, 4), 'Cafe'),
        _charge(3, DateTime(2026, 6, 1), 'Cafe'),
      ],
      subscriptions: const [],
      idFor: (index) => 's$index',
    );
    expect(suggested, isEmpty);
  });

  testWidgets('the import screen saves only the confirmed suggestion', (
    tester,
  ) async {
    final subscriptions = InMemorySubscriptionRepository();
    final files = ScriptedCsvFileGateway(
      _csv('''
date,merchant,amount_minor,currency
2026-01-01,City Gym,3500,USD
2026-02-01,City Gym,3500,USD
'''),
    );
    await tester.pumpWidget(
      RegistryApp(
        onboardingRepository: FakeOnboardingRepository(completed: true),
        locale: const Locale('en'),
        subscriptionRepository: subscriptions,
        csvFiles: files,
        clock: FixedClock(DateTime(2026, 4, 2)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('nav-profile')));
    await tester.pumpAndSettle();
    await tapProfileControl(tester, const ValueKey<String>('csv-import-open'));
    expect(
      find.textContaining('not a connection to your bank'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('csv-choose-file')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('csv-continue')));
    await tester.pumpAndSettle();
    expect(find.textContaining('not a confirmed subscription'), findsOneWidget);
    expect(find.textContaining('Source rows 2, 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('csv-confirm')));
    await tester.pumpAndSettle();
    expect(find.byType(ImportChargesScreen), findsNothing);
    expect(subscriptions.subscriptions, hasLength(1));
    expect(find.textContaining('1 subscription added'), findsOneWidget);
    expect(files.calls, 1);
  });
}

Uint8List _csv(String text) => Uint8List.fromList(utf8.encode(text.trim()));

CsvChargeRow _charge(int line, DateTime date, String merchant) {
  return CsvChargeRow(
    lineNumber: line,
    date: date,
    merchant: merchant,
    minorUnits: 3500,
    currencyCode: 'USD',
  );
}
