import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/app/app.dart';
import 'package:the_registry/core/time/clock.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';

import 'support/fake_onboarding_repository.dart';
import 'support/save_screenshot.dart';

void main() {
  setUpAll(() async {
    final config = File('.dart_tool/package_config.json').absolute;
    final packages =
        (jsonDecode(await config.readAsString()) as Map)['packages'] as List;
    final flutter = packages.firstWhere((p) => p['name'] == 'flutter');
    final root = config.uri
        .resolve('${flutter['rootUri']}/')
        .resolve('../../bin/cache/artifacts/material_fonts/');
    for (final entry in {
      'Roboto': 'Roboto-Regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf',
    }.entries) {
      final loader = FontLoader(entry.key)
        ..addFont(
          File.fromUri(
            root.resolve(entry.value),
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await loader.load();
    }
    final loraLoader = FontLoader('Lora')
      ..addFont(
        File('assets/fonts/Lora-SemiBold.ttf')
            .readAsBytes()
            .then((bytes) => ByteData.sublistView(bytes)),
      )
      ..addFont(
        File('assets/fonts/Lora-Bold.ttf')
            .readAsBytes()
            .then((bytes) => ByteData.sublistView(bytes)),
      );
    await loraLoader.load();
  });

  Future<({
    InMemoryDocumentRepository docs,
    InMemorySubscriptionRepository subs,
    Clock clock,
  })> seedDemoData() async {
    final clock = FixedClock(DateTime(2026, 11, 26, 10, 0));
    final docs = InMemoryDocumentRepository();
    await docs.save(
      RegistryDocument(
        id: 'demo-passport',
        name: 'Passport',
        category: DocumentCategory.passport,
        countryCode: 'FR',
        schemaId: 'generic_passport',
        ownerName: 'Amina Laurent',
        issuingAuthority: 'Republic of France',
        documentNumber: '24FR89104',
        issueDate: DateTime(2021, 12, 10),
        expiryDate: DateTime(2026, 12, 10),
        actionDate: DateTime(2026, 11, 24),
        impact: DocumentImpact.critical,
        renewalEffort: RenewalEffort.moderate,
        reminders: const {
          ReminderPreference.thirtyDaysBefore,
          ReminderPreference.sevenDaysBefore,
          ReminderPreference.onActionDate,
        },
        createdAt: DateTime(2026, 1, 10),
      ),
    );
    await docs.save(
      RegistryDocument(
        id: 'demo-insurance',
        name: 'Car Insurance',
        category: DocumentCategory.insurance,
        countryCode: 'IN',
        ownerName: 'Amina Laurent',
        issuingAuthority: 'Aegis Mutual',
        documentNumber: 'POL-482019',
        issueDate: DateTime(2026, 1, 15),
        expiryDate: DateTime(2027, 1, 15),
        actionDate: DateTime(2026, 12, 20),
        impact: DocumentImpact.high,
        renewalEffort: RenewalEffort.easy,
        reminders: const {ReminderPreference.thirtyDaysBefore},
        createdAt: DateTime(2026, 2, 1),
      ),
    );
    await docs.save(
      RegistryDocument(
        id: 'demo-licence',
        name: 'Driving Licence',
        category: DocumentCategory.drivingLicence,
        countryCode: 'FR',
        ownerName: 'Amina Laurent',
        issuingAuthority: 'ANTS',
        documentNumber: 'DL-773019',
        issueDate: DateTime(2020, 6, 1),
        expiryDate: DateTime(2030, 6, 1),
        impact: DocumentImpact.medium,
        renewalEffort: RenewalEffort.easy,
        reminders: const {ReminderPreference.thirtyDaysBefore},
        createdAt: DateTime(2026, 3, 1),
      ),
    );

    final subs = InMemorySubscriptionRepository();
    await subs.save(
      RegistrySubscription(
        id: 'demo-cloud',
        serviceName: 'Cloud Storage',
        planName: '200 GB Family',
        category: SubscriptionCategory.cloudStorage,
        amount: const Money(minorUnits: 999, currencyCode: 'EUR'),
        billingCycle: BillingCycle.monthly,
        nextPaymentDate: DateTime(2026, 12, 4),
        decideByDate: DateTime(2026, 12, 1),
        autoRenew: true,
        lifecycle: SubscriptionLifecycle.active,
        impact: DocumentImpact.medium,
        reminders: const {
          SubscriptionReminder.sevenDaysBefore,
          SubscriptionReminder.oneDayBefore,
        },
        createdAt: DateTime(2026, 5, 1),
      ),
    );
    await subs.save(
      RegistrySubscription(
        id: 'demo-gym',
        serviceName: 'Atelier Fitness',
        planName: 'Annual Pass',
        category: SubscriptionCategory.fitness,
        amount: const Money(minorUnits: 4200, currencyCode: 'EUR'),
        billingCycle: BillingCycle.monthly,
        nextPaymentDate: DateTime(2026, 12, 18),
        decideByDate: DateTime(2026, 12, 12),
        autoRenew: true,
        lifecycle: SubscriptionLifecycle.active,
        impact: DocumentImpact.low,
        reminders: const {SubscriptionReminder.sevenDaysBefore},
        createdAt: DateTime(2026, 4, 1),
      ),
    );
    return (docs: docs, subs: subs, clock: clock);
  }

  testWidgets('Captures Paper Wallet visual QA screenshots', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final demo = await seedDemoData();

    await tester.pumpWidget(
      wrapForScreenshot(
        RegistryApp(
          onboardingRepository: FakeOnboardingRepository(completed: true),
          documentRepository: demo.docs,
          subscriptionRepository: demo.subs,
          clock: demo.clock,
          locale: const Locale('en'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await saveScreenshot(tester, 'home_action_needed', folder: 'paper_wallet', pixelRatio: 2.0);

    // Documents tab
    await tester.tap(find.byKey(const ValueKey<String>('nav-documents')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await saveScreenshot(tester, 'documents_wallet', folder: 'paper_wallet', pixelRatio: 2.0);

    // Subscriptions tab
    await tester.tap(find.byKey(const ValueKey<String>('nav-subscriptions')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await saveScreenshot(tester, 'subscriptions_wallet', folder: 'paper_wallet', pixelRatio: 2.0);

    // Quick Add -> Add Document
    await tester.tap(find.byKey(const ValueKey<String>('home-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('add-document')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await saveScreenshot(tester, 'add_document_step1', folder: 'paper_wallet', pixelRatio: 2.0);
  });

  testWidgets('Captures Arabic RTL Home screenshot', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final demo = await seedDemoData();

    await tester.pumpWidget(
      wrapForScreenshot(
        RegistryApp(
          onboardingRepository: FakeOnboardingRepository(completed: true),
          documentRepository: demo.docs,
          subscriptionRepository: demo.subs,
          clock: demo.clock,
          locale: const Locale('ar'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await saveScreenshot(tester, 'home_arabic_rtl', folder: 'paper_wallet', pixelRatio: 2.0);
  });
}
