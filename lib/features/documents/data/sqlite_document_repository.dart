import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:the_registry/core/persistence/document_attachment_store.dart';
import 'package:the_registry/core/persistence/persisted_values.dart';
import 'package:the_registry/features/documents/domain/document_field_value.dart';
import 'package:the_registry/features/documents/domain/document_repository.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/domain/renewal_history_entry.dart';

class SqliteDocumentRepository extends ChangeNotifier
    implements DocumentRepository {
  SqliteDocumentRepository._(this._database, this._attachments);

  final Database _database;
  final DocumentAttachmentStore _attachments;
  final List<RegistryDocument> _documents = [];
  final Map<String, String> _attachmentNames = {};
  final Map<String, int> _attachmentLengths = {};

  static Future<SqliteDocumentRepository> load(
    Database database,
    DocumentAttachmentStore attachments,
  ) async {
    final repository = SqliteDocumentRepository._(database, attachments);
    await repository._readAll();
    return repository;
  }

  Set<String> get attachmentFileNames => _attachmentNames.values.toSet();

  String? attachmentFileNameFor(String id) => _attachmentNames[id];

  int? attachmentByteLengthFor(String id) => _attachmentLengths[id];

  @override
  List<RegistryDocument> get documents => List.unmodifiable(_documents);

  @override
  RegistryDocument? findById(String id) {
    for (final document in _documents) {
      if (document.id == id) {
        return document;
      }
    }
    return null;
  }

  @override
  Future<void> save(RegistryDocument document) async {
    if (findById(document.id) != null) {
      throw StateError('A document with id ${document.id} already exists.');
    }
    String? written;
    var committed = false;
    try {
      final stored = await _writeAttachment(
        document.id,
        document.attachmentBytes,
      );
      written = stored.fileName;
      await _database.transaction((txn) async {
        final rank = await _nextRank(txn);
        await txn.insert('documents', _row(document, stored, rank));
        await _insertChildren(txn, document);
      });
      committed = true;
      _rememberAttachment(document.id, stored);
      _documents.insert(0, document);
      notifyListeners();
    } on Object {
      if (!committed) {
        await _attachments.deleteIfPresent(written);
      }
      rethrow;
    }
  }

  @override
  Future<bool> update(RegistryDocument document) async {
    final index = _documents.indexWhere((item) => item.id == document.id);
    if (index < 0) {
      return false;
    }
    final existing = _documents[index];
    final previousName = _attachmentNames[document.id];
    String? written;
    String? replacedName;
    var committed = false;
    try {
      final stored = await _attachmentForUpdate(
        existing: existing,
        nextBytes: document.attachmentBytes,
        previousName: previousName,
      );
      written = stored.writtenFileName;
      replacedName = stored.replacedFileName;
      await _database.transaction((txn) async {
        await txn.update(
          'documents',
          _row(document, stored.stored, null),
          where: 'id = ?',
          whereArgs: [document.id],
        );
        await txn.delete(
          'document_fields',
          where: 'document_id = ?',
          whereArgs: [document.id],
        );
        await txn.delete(
          'renewal_history',
          where: 'document_id = ?',
          whereArgs: [document.id],
        );
        await _insertChildren(txn, document);
      });
      committed = true;
      _rememberAttachment(document.id, stored.stored);
      _documents[index] = document;
      notifyListeners();
      if (replacedName != null && replacedName != stored.stored.fileName) {
        try {
          await _attachments.deleteIfPresent(replacedName);
        } on IOException {
          // The new row is already saved. The next open drops unreferenced files.
        }
      }
      return true;
    } on Object {
      if (!committed) {
        await _attachments.deleteIfPresent(written);
      }
      rethrow;
    }
  }

  @override
  Future<bool> delete(String id) async {
    final index = _documents.indexWhere((item) => item.id == id);
    if (index < 0) {
      return false;
    }
    final fileName = _attachmentNames[id];
    await _database.transaction((txn) async {
      await txn.delete(
        'document_fields',
        where: 'document_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'renewal_history',
        where: 'document_id = ?',
        whereArgs: [id],
      );
      await txn.delete('documents', where: 'id = ?', whereArgs: [id]);
    });
    _attachmentNames.remove(id);
    _attachmentLengths.remove(id);
    _documents.removeAt(index);
    notifyListeners();
    try {
      await _attachments.deleteIfPresent(fileName);
    } on IOException {
      // The document row is gone. The next open drops the unreferenced file.
    }
    return true;
  }

  /// Writes replacement images before the database transaction.
  ///
  /// Names are generated inside the private attachment directory. A failure
  /// deletes any files this call created.
  Future<List<String?>> stageReplacementAttachments(
    List<RegistryDocument> documents,
  ) async {
    final staged = <String?>[];
    try {
      for (final document in documents) {
        final bytes = document.attachmentBytes;
        if (bytes == null || bytes.isEmpty) {
          staged.add(null);
          continue;
        }
        staged.add(
          await _attachments.writeAtomically(
            documentId: document.id,
            bytes: bytes,
          ),
        );
      }
      return staged;
    } catch (error) {
      await discardStagedAttachments(staged);
      rethrow;
    }
  }

  Future<void> discardStagedAttachments(List<String?> names) async {
    for (final name in names) {
      await _attachments.deleteIfPresent(name);
    }
  }

  Future<void> deleteAttachmentNames(Set<String> names) async {
    for (final name in names) {
      try {
        await _attachments.deleteIfPresent(name);
      } on IOException {
        // The restored rows are already committed. The next open drops leftovers.
      }
    }
  }

  Future<void> insertReplacement(
    DatabaseExecutor txn,
    List<RegistryDocument> documents,
    List<String?> fileNames,
  ) async {
    await txn.delete('document_fields');
    await txn.delete('renewal_history');
    await txn.delete('documents');
    final count = documents.length;
    for (var index = 0; index < count; index++) {
      final document = documents[index];
      final fileName = fileNames[index];
      final bytes = document.attachmentBytes;
      final stored = _StoredAttachment(
        fileName: fileName,
        byteLength: fileName == null || bytes == null ? null : bytes.length,
      );
      await txn.insert('documents', _row(document, stored, count - index));
      await _insertChildren(txn, document);
    }
  }

  void adoptReplacement(
    List<RegistryDocument> documents,
    List<String?> fileNames, {
    bool notify = true,
  }) {
    _documents
      ..clear()
      ..addAll(documents);
    _attachmentNames.clear();
    _attachmentLengths.clear();
    for (var index = 0; index < documents.length; index++) {
      final fileName = fileNames[index];
      final bytes = documents[index].attachmentBytes;
      if (fileName == null || bytes == null || bytes.isEmpty) {
        continue;
      }
      _attachmentNames[documents[index].id] = fileName;
      _attachmentLengths[documents[index].id] = bytes.length;
    }
    if (notify) {
      notifyListeners();
    }
  }

  void notifyReplacement() {
    notifyListeners();
  }

  Future<void> _readAll() async {
    final rows = await _database.query('documents', orderBy: 'sort_rank DESC');
    final fieldRows = await _database.query(
      'document_fields',
      orderBy: 'position ASC',
    );
    final historyRows = await _database.query(
      'renewal_history',
      orderBy: 'position ASC',
    );
    final fieldsByDocument = <String, List<DocumentFieldValue>>{};
    for (final row in fieldRows) {
      final documentId = PersistedValues.decodeString(row['document_id']);
      fieldsByDocument
          .putIfAbsent(documentId, () => [])
          .add(_fieldFromRow(row));
    }
    final historyByDocument = <String, List<RenewalHistoryEntry>>{};
    for (final row in historyRows) {
      final documentId = PersistedValues.decodeString(row['document_id']);
      historyByDocument
          .putIfAbsent(documentId, () => [])
          .add(_historyFromRow(row));
    }
    for (final row in rows) {
      final id = PersistedValues.decodeString(row['id']);
      final fileName = PersistedValues.decodeOptionalString(
        row['attachment_file_name'],
      );
      final byteLength = PersistedValues.decodeOptionalInt(
        row['attachment_byte_length'],
      );
      Uint8List? bytes;
      if (fileName != null) {
        _attachmentNames[id] = fileName;
        if (byteLength != null) {
          _attachmentLengths[id] = byteLength;
        }
        bytes = await _attachments.read(fileName);
      }
      _documents.add(
        _documentFromRow(
          row,
          fieldsByDocument[id] ?? const [],
          historyByDocument[id] ?? const [],
          bytes,
        ),
      );
    }
  }

  Future<_StoredAttachment> _writeAttachment(
    String documentId,
    Uint8List? bytes,
  ) async {
    if (bytes == null || bytes.isEmpty) {
      return const _StoredAttachment();
    }
    final fileName = await _attachments.writeAtomically(
      documentId: documentId,
      bytes: bytes,
    );
    return _StoredAttachment(fileName: fileName, byteLength: bytes.length);
  }

  Future<_AttachmentUpdate> _attachmentForUpdate({
    required RegistryDocument existing,
    required Uint8List? nextBytes,
    required String? previousName,
  }) async {
    if (_sameAttachment(existing.attachmentBytes, nextBytes)) {
      final length = existing.attachmentBytes == null
          ? _attachmentLengths[existing.id]
          : existing.attachmentBytes!.length;
      return _AttachmentUpdate(
        stored: _StoredAttachment(fileName: previousName, byteLength: length),
      );
    }
    if (nextBytes == null || nextBytes.isEmpty) {
      return _AttachmentUpdate(
        stored: const _StoredAttachment(),
        replacedFileName: previousName,
      );
    }
    final fileName = await _attachments.writeAtomically(
      documentId: existing.id,
      bytes: nextBytes,
    );
    return _AttachmentUpdate(
      stored: _StoredAttachment(
        fileName: fileName,
        byteLength: nextBytes.length,
      ),
      writtenFileName: fileName,
      replacedFileName: previousName,
    );
  }

  void _rememberAttachment(String id, _StoredAttachment stored) {
    final fileName = stored.fileName;
    if (fileName == null) {
      _attachmentNames.remove(id);
      _attachmentLengths.remove(id);
      return;
    }
    _attachmentNames[id] = fileName;
    final byteLength = stored.byteLength;
    if (byteLength == null) {
      _attachmentLengths.remove(id);
    } else {
      _attachmentLengths[id] = byteLength;
    }
  }

  Future<void> _insertChildren(
    DatabaseExecutor txn,
    RegistryDocument document,
  ) async {
    for (var index = 0; index < document.dynamicFields.length; index++) {
      final field = document.dynamicFields[index];
      await txn.insert('document_fields', {
        'document_id': document.id,
        'position': index,
        'field_id': field.id,
        'field_key': field.fieldKey,
        'custom_label': field.customLabel,
        'value': field.value,
        'sensitive': PersistedValues.encodeBool(field.sensitive),
        'is_date': PersistedValues.encodeBool(field.isDate),
        'is_custom': PersistedValues.encodeBool(field.isCustom),
      });
    }
    for (var index = 0; index < document.renewalHistory.length; index++) {
      final entry = document.renewalHistory[index];
      await txn.insert('renewal_history', {
        'document_id': document.id,
        'position': index,
        'entry_id': entry.id,
        'renewed_on': PersistedValues.encodeDate(entry.renewedOn),
        'previous_expiry_date': PersistedValues.encodeDate(
          entry.previousExpiryDate,
        ),
        'new_expiry_date': PersistedValues.encodeDate(entry.newExpiryDate),
        'note': entry.note,
      });
    }
  }

  Map<String, Object?> _row(
    RegistryDocument document,
    _StoredAttachment attachment,
    int? sortRank,
  ) {
    return {
      'id': document.id,
      'name': document.name,
      'category': document.category.name,
      'owner_name': document.ownerName,
      'issuing_authority': document.issuingAuthority,
      'document_number': document.documentNumber,
      'issue_date': PersistedValues.encodeOptionalDate(document.issueDate),
      'expiry_date': PersistedValues.encodeDate(document.expiryDate),
      'action_date': PersistedValues.encodeOptionalDate(document.actionDate),
      'impact': document.impact.name,
      'renewal_effort': document.renewalEffort?.name,
      'cost_of_lapsing': document.costOfLapsing,
      'dependency': document.dependency,
      'expected_changes': document.expectedChanges,
      'notes': document.notes,
      'reminders': PersistedValues.encodeEnumSet(document.reminders),
      'created_at': PersistedValues.encodeDate(document.createdAt),
      'updated_at': PersistedValues.encodeOptionalDate(document.updatedAt),
      'schema_id': document.schemaId,
      'country_code': document.countryCode,
      'sort_rank': ?sortRank,
      'attachment_file_name': attachment.fileName,
      'attachment_byte_length': attachment.byteLength,
    };
  }

  RegistryDocument _documentFromRow(
    Map<String, Object?> row,
    List<DocumentFieldValue> fields,
    List<RenewalHistoryEntry> history,
    Uint8List? bytes,
  ) {
    final effort = PersistedValues.decodeOptionalString(row['renewal_effort']);
    return RegistryDocument(
      id: PersistedValues.decodeString(row['id']),
      name: PersistedValues.decodeString(row['name']),
      category: PersistedValues.decodeEnum(
        DocumentCategory.values,
        row['category'],
      ),
      ownerName: PersistedValues.decodeOptionalString(row['owner_name']),
      issuingAuthority: PersistedValues.decodeOptionalString(
        row['issuing_authority'],
      ),
      documentNumber: PersistedValues.decodeOptionalString(
        row['document_number'],
      ),
      issueDate: PersistedValues.decodeOptionalDate(row['issue_date']),
      expiryDate: PersistedValues.decodeDate(row['expiry_date']),
      actionDate: PersistedValues.decodeOptionalDate(row['action_date']),
      impact: PersistedValues.decodeEnum(DocumentImpact.values, row['impact']),
      renewalEffort: effort == null
          ? null
          : PersistedValues.decodeEnum(RenewalEffort.values, effort),
      costOfLapsing: PersistedValues.decodeOptionalString(
        row['cost_of_lapsing'],
      ),
      dependency: PersistedValues.decodeOptionalString(row['dependency']),
      expectedChanges: PersistedValues.decodeOptionalString(
        row['expected_changes'],
      ),
      notes: PersistedValues.decodeOptionalString(row['notes']),
      reminders: PersistedValues.decodeEnumSet(
        ReminderPreference.values,
        row['reminders'],
      ),
      attachmentBytes: bytes,
      createdAt: PersistedValues.decodeDate(row['created_at']),
      updatedAt: PersistedValues.decodeOptionalDate(row['updated_at']),
      renewalHistory: history,
      schemaId: PersistedValues.decodeString(row['schema_id']),
      countryCode: PersistedValues.decodeOptionalString(row['country_code']),
      dynamicFields: fields,
    );
  }

  DocumentFieldValue _fieldFromRow(Map<String, Object?> row) {
    return DocumentFieldValue(
      id: PersistedValues.decodeString(row['field_id']),
      fieldKey: PersistedValues.decodeString(row['field_key']),
      customLabel: PersistedValues.decodeOptionalString(row['custom_label']),
      value: PersistedValues.decodeString(row['value']),
      sensitive: PersistedValues.decodeBool(row['sensitive']),
      isDate: PersistedValues.decodeBool(row['is_date']),
      isCustom: PersistedValues.decodeBool(row['is_custom']),
    );
  }

  RenewalHistoryEntry _historyFromRow(Map<String, Object?> row) {
    return RenewalHistoryEntry(
      id: PersistedValues.decodeString(row['entry_id']),
      renewedOn: PersistedValues.decodeDate(row['renewed_on']),
      previousExpiryDate: PersistedValues.decodeDate(
        row['previous_expiry_date'],
      ),
      newExpiryDate: PersistedValues.decodeDate(row['new_expiry_date']),
      note: PersistedValues.decodeOptionalString(row['note']),
    );
  }

  Future<int> _nextRank(DatabaseExecutor txn) async {
    final rows = await txn.rawQuery(
      'SELECT COALESCE(MAX(sort_rank), 0) AS max_rank FROM documents',
    );
    return PersistedValues.decodeInt(rows.first['max_rank']) + 1;
  }

  bool _sameAttachment(Uint8List? current, Uint8List? next) {
    final currentEmpty = current == null || current.isEmpty;
    final nextEmpty = next == null || next.isEmpty;
    if (currentEmpty && nextEmpty) {
      return true;
    }
    if (currentEmpty || nextEmpty) {
      return false;
    }
    return listEquals(current, next);
  }
}

class _StoredAttachment {
  const _StoredAttachment({this.fileName, this.byteLength});

  final String? fileName;
  final int? byteLength;
}

class _AttachmentUpdate {
  const _AttachmentUpdate({
    required this.stored,
    this.writtenFileName,
    this.replacedFileName,
  });

  final _StoredAttachment stored;
  final String? writtenFileName;
  final String? replacedFileName;
}
