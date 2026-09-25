import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:the_registry/core/persistence/persisted_values.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';
import 'package:the_registry/features/subscriptions/domain/subscription_repository.dart';

class SqliteSubscriptionRepository extends ChangeNotifier
    implements SubscriptionRepository {
  SqliteSubscriptionRepository._(this._database);

  final Database _database;
  final List<RegistrySubscription> _subscriptions = [];

  static Future<SqliteSubscriptionRepository> load(Database database) async {
    final repository = SqliteSubscriptionRepository._(database);
    await repository._readAll();
    return repository;
  }

  @override
  List<RegistrySubscription> get subscriptions =>
      List.unmodifiable(_subscriptions);

  @override
  RegistrySubscription? findById(String id) {
    for (final subscription in _subscriptions) {
      if (subscription.id == id) {
        return subscription;
      }
    }
    return null;
  }

  @override
  Future<void> save(RegistrySubscription subscription) async {
    if (findById(subscription.id) != null) {
      throw StateError(
        'A subscription with id ${subscription.id} already exists.',
      );
    }
    await _database.transaction((txn) async {
      final rank = await _nextRank(txn);
      await txn.insert('subscriptions', _row(subscription, rank));
    });
    _subscriptions.insert(0, subscription);
    notifyListeners();
  }

  @override
  Future<bool> update(RegistrySubscription subscription) async {
    final index = _subscriptions.indexWhere(
      (item) => item.id == subscription.id,
    );
    if (index < 0) {
      return false;
    }
    await _database.update(
      'subscriptions',
      _row(subscription, null),
      where: 'id = ?',
      whereArgs: [subscription.id],
    );
    _subscriptions[index] = subscription;
    notifyListeners();
    return true;
  }

  @override
  Future<bool> delete(String id) async {
    final index = _subscriptions.indexWhere((item) => item.id == id);
    if (index < 0) {
      return false;
    }
    await _database.delete('subscriptions', where: 'id = ?', whereArgs: [id]);
    _subscriptions.removeAt(index);
    notifyListeners();
    return true;
  }

  Future<void> _readAll() async {
    final rows = await _database.query(
      'subscriptions',
      orderBy: 'sort_rank DESC',
    );
    for (final row in rows) {
      _subscriptions.add(_fromRow(row));
    }
  }

  Map<String, Object?> _row(RegistrySubscription subscription, int? sortRank) {
    return {
      'id': subscription.id,
      'created_at': PersistedValues.encodeDate(subscription.createdAt),
      'updated_at': PersistedValues.encodeOptionalDate(subscription.updatedAt),
      'service_name': subscription.serviceName,
      'plan_name': subscription.planName,
      'category': subscription.category.name,
      'minor_units': subscription.amount.minorUnits,
      'currency_code': subscription.amount.currencyCode,
      'billing_cycle': subscription.billingCycle.name,
      'next_payment_date': PersistedValues.encodeDate(
        subscription.nextPaymentDate,
      ),
      'decide_by_date': PersistedValues.encodeOptionalDate(
        subscription.decideByDate,
      ),
      'auto_renew': PersistedValues.encodeBool(subscription.autoRenew),
      'lifecycle': subscription.lifecycle.name,
      'impact': subscription.impact.name,
      'reminders': PersistedValues.encodeEnumSet(subscription.reminders),
      'notes': subscription.notes,
      'sort_rank': ?sortRank,
    };
  }

  RegistrySubscription _fromRow(Map<String, Object?> row) {
    return RegistrySubscription(
      id: PersistedValues.decodeString(row['id']),
      createdAt: PersistedValues.decodeDate(row['created_at']),
      updatedAt: PersistedValues.decodeOptionalDate(row['updated_at']),
      serviceName: PersistedValues.decodeString(row['service_name']),
      planName: PersistedValues.decodeOptionalString(row['plan_name']),
      category: PersistedValues.decodeEnum(
        SubscriptionCategory.values,
        row['category'],
      ),
      amount: Money(
        minorUnits: PersistedValues.decodeInt(row['minor_units']),
        currencyCode: PersistedValues.decodeString(row['currency_code']),
      ),
      billingCycle: PersistedValues.decodeEnum(
        BillingCycle.values,
        row['billing_cycle'],
      ),
      nextPaymentDate: PersistedValues.decodeDate(row['next_payment_date']),
      decideByDate: PersistedValues.decodeOptionalDate(row['decide_by_date']),
      autoRenew: PersistedValues.decodeBool(row['auto_renew']),
      lifecycle: PersistedValues.decodeEnum(
        SubscriptionLifecycle.values,
        row['lifecycle'],
      ),
      impact: PersistedValues.decodeEnum(DocumentImpact.values, row['impact']),
      reminders: PersistedValues.decodeEnumSet(
        SubscriptionReminder.values,
        row['reminders'],
      ),
      notes: PersistedValues.decodeOptionalString(row['notes']),
    );
  }

  Future<int> _nextRank(DatabaseExecutor txn) async {
    final rows = await txn.rawQuery(
      'SELECT COALESCE(MAX(sort_rank), 0) AS max_rank FROM subscriptions',
    );
    return PersistedValues.decodeInt(rows.first['max_rank']) + 1;
  }
}
