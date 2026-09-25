import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:the_registry/app/registry_bootstrap.dart';
import 'package:the_registry/core/persistence/registry_store.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/home/widgets/home_first_visit.dart';

import 'support/fake_onboarding_repository.dart';
import 'support/sample_document.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late String databasePath;
  late Directory attachments;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    root = await Directory.systemTemp.createTemp('registry_bootstrap_');
    databasePath = p.join(root.path, 'registry.db');
    attachments = Directory(p.join(root.path, 'attachments'));
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  Future<RegistryStore> openStore() {
    return RegistryStore.open(
      databasePath: databasePath,
      attachmentsDirectory: attachments,
    );
  }

  Future<RegistryStore> openReal(WidgetTester tester) async {
    final store = await tester.runAsync(openStore);
    expect(store, isNotNull);
    return store!;
  }

  Future<void> settle(WidgetTester tester) async {
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('saved records load before Home can show the first visit', (
    tester,
  ) async {
    final ready = await openReal(tester);
    final document = _visibleDocument();
    await tester.runAsync(() => ready.documents.save(document));

    final gate = Completer<RegistryStore>();
    await tester.pumpWidget(
      RegistryBootstrap(
        locale: const Locale('en'),
        openStore: () => gate.future,
        onboardingRepository: FakeOnboardingRepository(completed: true),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('registry-storage-loading')),
      findsOneWidget,
    );
    expect(find.byType(HomeFirstVisit), findsNothing);
    expect(find.textContaining('Family passport'), findsNothing);

    gate.complete(ready);
    await settle(tester);

    expect(find.byType(HomeFirstVisit), findsNothing);
    expect(find.textContaining('Family passport'), findsWidgets);
    await tester.runAsync(ready.close);
  });

  testWidgets('an empty device still shows the first-visit home', (
    tester,
  ) async {
    final store = await openReal(tester);
    await tester.pumpWidget(
      RegistryBootstrap(
        locale: const Locale('en'),
        openStore: () async => store,
        onboardingRepository: FakeOnboardingRepository(completed: true),
      ),
    );
    await settle(tester);

    expect(find.byType(HomeFirstVisit), findsOneWidget);
    await tester.runAsync(store.close);
  });

  testWidgets('startup failure keeps existing records and can retry', (
    tester,
  ) async {
    final seeded = await openReal(tester);
    final document = _visibleDocument();
    await tester.runAsync(() => seeded.documents.save(document));
    await tester.runAsync(seeded.close);
    final before = await tester.runAsync(
      () => File(databasePath).readAsBytes(),
    );
    var attempts = 0;
    RegistryStore? restored;

    await tester.pumpWidget(
      RegistryBootstrap(
        locale: const Locale('en'),
        onboardingRepository: FakeOnboardingRepository(completed: true),
        openStore: () async {
          attempts += 1;
          if (attempts == 1 || restored == null) {
            throw StateError('storage unavailable');
          }
          return restored;
        },
      ),
    );
    await settle(tester);

    expect(
      find.byKey(const ValueKey<String>('registry-storage-error')),
      findsOneWidget,
    );
    expect(find.text('Saved records could not be opened'), findsOneWidget);
    expect(find.byType(HomeFirstVisit), findsNothing);
    final afterFailure = await tester.runAsync(
      () => File(databasePath).readAsBytes(),
    );
    expect(afterFailure, before);

    restored = await openReal(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('registry-storage-retry')),
    );
    await settle(tester);

    expect(find.byType(HomeFirstVisit), findsNothing);
    expect(find.textContaining('Family passport'), findsWidgets);

    expect(restored.documents.findById(document.id)?.name, document.name);
    expect(
      restored.documents.findById(document.id)?.expiryDate,
      document.expiryDate,
    );
    await tester.runAsync(restored.close);
  });
}

RegistryDocument _visibleDocument() {
  final today = DateTime.now();
  final day = DateTime(today.year, today.month, today.day);
  return sampleDocument(
    name: 'Family passport',
    issueDate: day.subtract(const Duration(days: 400)),
    expiryDate: day.add(const Duration(days: 20)),
    actionDate: day.subtract(const Duration(days: 1)),
  );
}
