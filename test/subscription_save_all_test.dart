import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:the_registry/core/persistence/registry_store.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';

import 'support/sample_subscription.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('in-memory saveAll inserts every row or none', () async {
    final repository = InMemorySubscriptionRepository();
    await repository.save(sampleSubscription(id: 'kept'));
    await repository.saveAll([
      sampleSubscription(id: 'a', serviceName: 'A'),
      sampleSubscription(id: 'b', serviceName: 'B'),
    ]);
    expect(repository.subscriptions.map((item) => item.id), ['a', 'b', 'kept']);

    await expectLater(
      repository.saveAll([
        sampleSubscription(id: 'c'),
        sampleSubscription(id: 'a'),
      ]),
      throwsStateError,
    );
    expect(repository.subscriptions.map((item) => item.id), ['a', 'b', 'kept']);
  });

  test(
    'sqlite saveAll commits the batch or leaves the previous rows',
    () async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final root = await Directory.systemTemp.createTemp('registry_save_all_');
      final store = await RegistryStore.open(
        databasePath: p.join(root.path, 'registry.db'),
        attachmentsDirectory: Directory(p.join(root.path, 'attachments')),
      );
      try {
        await store.subscriptions.saveAll([
          sampleSubscription(id: 'a', serviceName: 'A'),
          sampleSubscription(id: 'b', serviceName: 'B'),
        ]);
        expect(store.subscriptions.subscriptions.map((item) => item.id), [
          'a',
          'b',
        ]);
        await expectLater(
          store.subscriptions.saveAll([
            sampleSubscription(id: 'c'),
            sampleSubscription(id: 'b'),
          ]),
          throwsStateError,
        );
        expect(store.subscriptions.subscriptions, hasLength(2));

        await store.close();
        final reopened = await RegistryStore.open(
          databasePath: p.join(root.path, 'registry.db'),
          attachmentsDirectory: Directory(p.join(root.path, 'attachments')),
        );
        expect(reopened.subscriptions.subscriptions.map((item) => item.id), [
          'a',
          'b',
        ]);
        await reopened.close();
      } finally {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      }
    },
  );
}
