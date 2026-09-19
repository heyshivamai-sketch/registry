import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/features/subscriptions/data/in_memory_subscription_repository.dart';

import 'support/sample_subscription.dart';

void main() {
  late InMemorySubscriptionRepository repository;

  setUp(() {
    repository = InMemorySubscriptionRepository();
  });

  test('save adds a subscription and notifies once', () async {
    var notifications = 0;
    repository.addListener(() => notifications++);

    await repository.save(sampleSubscription());

    expect(repository.subscriptions, hasLength(1));
    expect(repository.subscriptions.single.id, 'sub_1');
    expect(notifications, 1);
  });

  test('findById returns the matching subscription', () async {
    await repository.save(sampleSubscription(id: 'a'));
    await repository.save(sampleSubscription(id: 'b', serviceName: 'News'));

    expect(repository.findById('a')?.serviceName, 'City Gym');
    expect(repository.findById('missing'), isNull);
  });

  test('update replaces in place, preserves id and notifies once', () async {
    var notifications = 0;
    repository.addListener(() => notifications++);
    await repository.save(sampleSubscription(id: 'sub_1'));
    notifications = 0;

    final success = await repository.update(
      sampleSubscription(id: 'sub_1', serviceName: 'Updated gym'),
    );

    expect(success, isTrue);
    expect(repository.subscriptions, hasLength(1));
    expect(repository.subscriptions.single.id, 'sub_1');
    expect(repository.subscriptions.single.serviceName, 'Updated gym');
    expect(notifications, 1);
  });

  test('update of a missing id fails without notifying', () async {
    var notifications = 0;
    repository.addListener(() => notifications++);

    expect(await repository.update(sampleSubscription(id: 'missing')), isFalse);
    expect(repository.subscriptions, isEmpty);
    expect(notifications, 0);
  });

  test('delete removes a subscription and notifies once', () async {
    var notifications = 0;
    repository.addListener(() => notifications++);
    await repository.save(sampleSubscription(id: 'sub_1'));
    notifications = 0;

    expect(await repository.delete('sub_1'), isTrue);
    expect(repository.subscriptions, isEmpty);
    expect(notifications, 1);
    expect(await repository.delete('sub_1'), isFalse);
    expect(notifications, 1);
  });

  test(
    'subscriptions getter does not expose a mutable internal list',
    () async {
      await repository.save(sampleSubscription());
      expect(
        () => repository.subscriptions.add(sampleSubscription(id: 'other')),
        throwsUnsupportedError,
      );
    },
  );
}
