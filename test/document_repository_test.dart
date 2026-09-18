import 'package:flutter_test/flutter_test.dart';
import 'package:the_registry/features/documents/data/in_memory_document_repository.dart';
import 'package:the_registry/features/documents/domain/document_renewal.dart';

import 'support/sample_document.dart';
import 'support/tiny_png.dart';

void main() {
  late InMemoryDocumentRepository repository;

  setUp(() {
    repository = InMemoryDocumentRepository();
  });

  test('save adds a document and notifies once', () async {
    var notifications = 0;
    repository.addListener(() => notifications++);
    final document = sampleDocument();

    await repository.save(document);

    expect(repository.documents, hasLength(1));
    expect(repository.documents.single.id, document.id);
    expect(notifications, 1);
  });

  test('findById returns the matching document', () async {
    await repository.save(sampleDocument(id: 'a'));
    await repository.save(sampleDocument(id: 'b', name: 'Visa'));

    expect(repository.findById('a')?.name, 'Family passport');
    expect(repository.findById('missing'), isNull);
  });

  test('copyWith preserves id, attachment and empty renewal history', () {
    final original = sampleDocument(attachmentBytes: kTinyPngBytes);
    final updated = original.copyWith(
      name: 'Updated passport',
      updatedAt: DateTime(2026, 3, 1),
    );

    expect(updated.id, original.id);
    expect(updated.name, 'Updated passport');
    expect(updated.attachmentBytes, original.attachmentBytes);
    expect(updated.createdAt, original.createdAt);
    expect(updated.renewalHistory, isEmpty);
    expect(updated.reminders, original.reminders);
  });

  test('update replaces in place, preserves id and notifies once', () async {
    var notifications = 0;
    repository.addListener(() => notifications++);
    await repository.save(sampleDocument(id: 'doc_1'));
    notifications = 0;

    final updated = sampleDocument(id: 'doc_1', name: 'Renewed passport');
    final success = await repository.update(updated);

    expect(success, isTrue);
    expect(repository.documents, hasLength(1));
    expect(repository.documents.single.id, 'doc_1');
    expect(repository.documents.single.name, 'Renewed passport');
    expect(notifications, 1);
  });

  test('update of a missing id fails without notifying', () async {
    var notifications = 0;
    repository.addListener(() => notifications++);

    final success = await repository.update(sampleDocument(id: 'missing'));

    expect(success, isFalse);
    expect(repository.documents, isEmpty);
    expect(notifications, 0);
  });

  test('delete removes a document and notifies once', () async {
    var notifications = 0;
    repository.addListener(() => notifications++);
    await repository.save(sampleDocument(id: 'doc_1'));
    notifications = 0;

    expect(await repository.delete('doc_1'), isTrue);
    expect(repository.documents, isEmpty);
    expect(notifications, 1);
    expect(await repository.delete('doc_1'), isFalse);
    expect(notifications, 1);
  });

  test('documents getter does not expose a mutable internal list', () async {
    await repository.save(sampleDocument());
    expect(
      () => repository.documents.add(sampleDocument(id: 'other')),
      throwsUnsupportedError,
    );
  });

  test('record renewal appends history and updates expiry only', () {
    final original = sampleDocument(
      expiryDate: DateTime(2027, 10, 5),
      actionDate: DateTime(2027, 9, 1),
    );
    final renewed = DocumentRenewal.record(
      document: original,
      renewedOn: DateTime(2026, 10, 1),
      newExpiryDate: DateTime(2032, 10, 5),
      note: 'Embassy visit',
    );

    expect(renewed.id, original.id);
    expect(renewed.expiryDate, DateTime(2032, 10, 5));
    expect(renewed.actionDate, original.actionDate);
    expect(renewed.renewalHistory, hasLength(1));
    expect(
      renewed.renewalHistory.single.previousExpiryDate,
      original.expiryDate,
    );
    expect(renewed.renewalHistory.single.note, 'Embassy visit');
    expect(
      DocumentRenewal.isNewExpiryValid(
        previousExpiry: original.expiryDate,
        newExpiry: DateTime(2027, 10, 4),
      ),
      isFalse,
    );
  });
}
