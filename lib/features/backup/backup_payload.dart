import 'dart:convert';
import 'dart:typed_data';

import 'package:the_registry/core/persistence/persisted_values.dart';
import 'package:the_registry/features/backup/backup_models.dart';
import 'package:the_registry/features/documents/domain/document_field_value.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';
import 'package:the_registry/features/documents/domain/renewal_history_entry.dart';
import 'package:the_registry/features/subscriptions/domain/money.dart';
import 'package:the_registry/features/subscriptions/domain/registry_subscription.dart';

/// Version 1 plaintext payload.
///
/// Big-endian, length-prefixed UTF-8. Attachment bytes are raw, not paths.
/// Dates use the same local/UTC microsecond encoding as the on-device rows.
abstract final class RegistryBackupPayload {
  static const magic = [0x52, 0x47, 0x50, 0x59]; // RGPY
  static const version = 1;

  static Uint8List encode(BackupSnapshot snapshot) {
    if (snapshot.documents.length > BackupLimits.maxDocuments ||
        snapshot.subscriptions.length > BackupLimits.maxSubscriptions) {
      throw const BackupOversized();
    }
    final writer = _Writer();
    writer.bytes(magic);
    writer.u16(version);
    writer.u32(snapshot.documents.length);
    writer.u32(snapshot.subscriptions.length);
    final seenDocuments = <String>{};
    for (final document in snapshot.documents) {
      _writeDocument(writer, document, seenDocuments);
    }
    final seenSubscriptions = <String>{};
    for (final subscription in snapshot.subscriptions) {
      _writeSubscription(writer, subscription, seenSubscriptions);
    }
    final encoded = writer.takeBytes();
    if (encoded.length > BackupLimits.maxPlaintextBytes) {
      encoded.fillRange(0, encoded.length, 0);
      throw const BackupOversized();
    }
    return encoded;
  }

  static BackupSnapshot decode(Uint8List bytes) {
    if (bytes.length > BackupLimits.maxPlaintextBytes) {
      throw const BackupOversized();
    }
    final reader = _Reader(bytes);
    final fileMagic = reader.bytes(4);
    for (var i = 0; i < magic.length; i++) {
      if (fileMagic[i] != magic[i]) {
        throw const BackupInvalid('magic');
      }
    }
    final version = reader.u16();
    if (version != RegistryBackupPayload.version) {
      throw const BackupUnsupportedVersion();
    }
    final documentCount = reader.u32();
    final subscriptionCount = reader.u32();
    if (documentCount > BackupLimits.maxDocuments ||
        subscriptionCount > BackupLimits.maxSubscriptions) {
      throw const BackupOversized();
    }
    final documents = <RegistryDocument>[];
    final seenDocuments = <String>{};
    for (var i = 0; i < documentCount; i++) {
      documents.add(_readDocument(reader, seenDocuments));
    }
    final subscriptions = <RegistrySubscription>[];
    final seenSubscriptions = <String>{};
    for (var i = 0; i < subscriptionCount; i++) {
      subscriptions.add(_readSubscription(reader, seenSubscriptions));
    }
    if (reader.remaining != 0) {
      throw const BackupInvalid('trailing');
    }
    return BackupSnapshot(documents: documents, subscriptions: subscriptions);
  }

  static void _writeDocument(
    _Writer writer,
    RegistryDocument document,
    Set<String> seenIds,
  ) {
    _writeId(writer, document.id, seenIds);
    _writeText(writer, document.name, required: true);
    writer.str(document.category.name);
    writer.optStr(document.ownerName);
    writer.optStr(document.issuingAuthority);
    writer.optStr(document.documentNumber);
    writer.optStr(_date(document.issueDate));
    writer.str(_date(document.expiryDate)!);
    writer.optStr(_date(document.actionDate));
    writer.str(document.impact.name);
    writer.optStr(document.renewalEffort?.name);
    writer.optStr(document.costOfLapsing);
    writer.optStr(document.dependency);
    writer.optStr(document.expectedChanges);
    writer.optStr(document.notes);
    writer.str(PersistedValues.encodeEnumSet(document.reminders));
    writer.str(_date(document.createdAt)!);
    writer.optStr(_date(document.updatedAt));
    _writeToken(writer, document.schemaId, maxLength: 64);
    writer.optStr(document.countryCode);
    if (document.countryCode != null) {
      _requireCountry(document.countryCode!);
    }
    if (document.dynamicFields.length > BackupLimits.maxFieldsPerDocument ||
        document.renewalHistory.length > BackupLimits.maxHistoryPerDocument) {
      throw const BackupOversized();
    }
    writer.u16(document.dynamicFields.length);
    final fieldIds = <String>{};
    for (final field in document.dynamicFields) {
      _writeId(writer, field.id, fieldIds);
      _writeToken(writer, field.fieldKey, maxLength: 64);
      writer.optStr(field.customLabel);
      _writeText(writer, field.value, required: false);
      writer.flag(field.sensitive);
      writer.flag(field.isDate);
      writer.flag(field.isCustom);
    }
    writer.u16(document.renewalHistory.length);
    final historyIds = <String>{};
    for (final entry in document.renewalHistory) {
      _writeId(writer, entry.id, historyIds);
      writer.str(_date(entry.renewedOn)!);
      writer.str(_date(entry.previousExpiryDate)!);
      writer.str(_date(entry.newExpiryDate)!);
      writer.optStr(entry.note);
    }
    final attachment = document.attachmentBytes;
    if (attachment == null || attachment.isEmpty) {
      writer.u8(0);
      return;
    }
    if (attachment.length > BackupLimits.maxAttachmentBytes) {
      throw const BackupOversized();
    }
    writer.u8(1);
    writer.u32(attachment.length);
    writer.bytes(attachment);
  }

  static RegistryDocument _readDocument(_Reader reader, Set<String> seenIds) {
    final id = _readId(reader, seenIds);
    final name = _readText(reader, required: true);
    final category = _enumValue(DocumentCategory.values, reader.str());
    final ownerName = reader.optStr();
    final issuingAuthority = reader.optStr();
    final documentNumber = reader.optStr();
    final issueDate = _readOptionalDate(reader);
    final expiryDate = _readDate(reader.str());
    final actionDate = _readOptionalDate(reader);
    final impact = _enumValue(DocumentImpact.values, reader.str());
    final effortName = reader.optStr();
    final renewalEffort = effortName == null
        ? null
        : _enumValue(RenewalEffort.values, effortName);
    final costOfLapsing = reader.optStr();
    final dependency = reader.optStr();
    final expectedChanges = reader.optStr();
    final notes = reader.optStr();
    final reminders = _enumSet(ReminderPreference.values, reader.str());
    final createdAt = _readDate(reader.str());
    final updatedAt = _readOptionalDate(reader);
    final schemaId = _readToken(reader, maxLength: 64);
    final countryCode = reader.optStr();
    if (countryCode != null) {
      _requireCountry(countryCode);
    }
    final fieldCount = reader.u16();
    if (fieldCount > BackupLimits.maxFieldsPerDocument) {
      throw const BackupOversized();
    }
    final fields = <DocumentFieldValue>[];
    final fieldIds = <String>{};
    for (var i = 0; i < fieldCount; i++) {
      fields.add(
        DocumentFieldValue(
          id: _readId(reader, fieldIds),
          fieldKey: _readToken(reader, maxLength: 64),
          customLabel: reader.optStr(),
          value: _readText(reader, required: false),
          sensitive: reader.flag(),
          isDate: reader.flag(),
          isCustom: reader.flag(),
        ),
      );
    }
    final historyCount = reader.u16();
    if (historyCount > BackupLimits.maxHistoryPerDocument) {
      throw const BackupOversized();
    }
    final history = <RenewalHistoryEntry>[];
    final historyIds = <String>{};
    for (var i = 0; i < historyCount; i++) {
      history.add(
        RenewalHistoryEntry(
          id: _readId(reader, historyIds),
          renewedOn: _readDate(reader.str()),
          previousExpiryDate: _readDate(reader.str()),
          newExpiryDate: _readDate(reader.str()),
          note: reader.optStr(),
        ),
      );
    }
    final hasAttachment = reader.u8();
    Uint8List? attachment;
    if (hasAttachment == 1) {
      final length = reader.u32();
      if (length == 0 || length > BackupLimits.maxAttachmentBytes) {
        throw const BackupOversized();
      }
      attachment = reader.byteCopy(length);
    } else if (hasAttachment != 0) {
      throw const BackupInvalid('attachment');
    }
    return RegistryDocument(
      id: id,
      name: name,
      category: category,
      ownerName: ownerName,
      issuingAuthority: issuingAuthority,
      documentNumber: documentNumber,
      issueDate: issueDate,
      expiryDate: expiryDate,
      actionDate: actionDate,
      impact: impact,
      renewalEffort: renewalEffort,
      costOfLapsing: costOfLapsing,
      dependency: dependency,
      expectedChanges: expectedChanges,
      notes: notes,
      reminders: reminders,
      attachmentBytes: attachment,
      createdAt: createdAt,
      updatedAt: updatedAt,
      renewalHistory: history,
      schemaId: schemaId,
      countryCode: countryCode,
      dynamicFields: fields,
    );
  }

  static void _writeSubscription(
    _Writer writer,
    RegistrySubscription subscription,
    Set<String> seenIds,
  ) {
    _writeId(writer, subscription.id, seenIds);
    writer.str(_date(subscription.createdAt)!);
    writer.optStr(_date(subscription.updatedAt));
    _writeText(writer, subscription.serviceName, required: true);
    writer.optStr(subscription.planName);
    writer.str(subscription.category.name);
    writer.i64(subscription.amount.minorUnits);
    _requireCurrency(subscription.amount.currencyCode);
    writer.str(subscription.amount.currencyCode);
    writer.str(subscription.billingCycle.name);
    writer.str(_date(subscription.nextPaymentDate)!);
    writer.optStr(_date(subscription.decideByDate));
    writer.flag(subscription.autoRenew);
    writer.str(subscription.lifecycle.name);
    writer.str(subscription.impact.name);
    writer.str(PersistedValues.encodeEnumSet(subscription.reminders));
    writer.optStr(subscription.notes);
  }

  static RegistrySubscription _readSubscription(
    _Reader reader,
    Set<String> seenIds,
  ) {
    final id = _readId(reader, seenIds);
    final createdAt = _readDate(reader.str());
    final updatedAt = _readOptionalDate(reader);
    final serviceName = _readText(reader, required: true);
    final planName = reader.optStr();
    final category = _enumValue(SubscriptionCategory.values, reader.str());
    final minorUnits = reader.i64();
    final currencyCode = reader.str();
    _requireCurrency(currencyCode);
    final billingCycle = _enumValue(BillingCycle.values, reader.str());
    final nextPaymentDate = _readDate(reader.str());
    final decideByDate = _readOptionalDate(reader);
    final autoRenew = reader.flag();
    final lifecycle = _enumValue(SubscriptionLifecycle.values, reader.str());
    final impact = _enumValue(DocumentImpact.values, reader.str());
    final reminders = _enumSet(SubscriptionReminder.values, reader.str());
    final notes = reader.optStr();
    return RegistrySubscription(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      serviceName: serviceName,
      planName: planName,
      category: category,
      amount: Money(minorUnits: minorUnits, currencyCode: currencyCode),
      billingCycle: billingCycle,
      nextPaymentDate: nextPaymentDate,
      decideByDate: decideByDate,
      autoRenew: autoRenew,
      lifecycle: lifecycle,
      impact: impact,
      reminders: reminders,
      notes: notes,
    );
  }

  static String? _date(DateTime? value) {
    return value == null ? null : PersistedValues.encodeDate(value);
  }

  static DateTime _readDate(String raw) {
    try {
      return PersistedValues.decodeDate(raw);
    } on FormatException {
      throw const BackupInvalid('date');
    }
  }

  static DateTime? _readOptionalDate(_Reader reader) {
    final raw = reader.optStr();
    if (raw == null) {
      return null;
    }
    return _readDate(raw);
  }

  static void _writeId(_Writer writer, String id, Set<String> seen) {
    _requireId(id);
    if (!seen.add(id)) {
      throw const BackupInvalid('duplicate-id');
    }
    writer.str(id);
  }

  static String _readId(_Reader reader, Set<String> seen) {
    final id = reader.str();
    _requireId(id);
    if (!seen.add(id)) {
      throw const BackupInvalid('duplicate-id');
    }
    return id;
  }

  static void _requireId(String id) {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,80}$').hasMatch(id)) {
      throw const BackupInvalid('id');
    }
  }

  static void _writeToken(
    _Writer writer,
    String value, {
    required int maxLength,
  }) {
    _requireToken(value, maxLength: maxLength);
    writer.str(value);
  }

  static String _readToken(_Reader reader, {required int maxLength}) {
    final value = reader.str();
    _requireToken(value, maxLength: maxLength);
    return value;
  }

  static void _requireToken(String value, {required int maxLength}) {
    if (value.length > maxLength ||
        !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value)) {
      throw const BackupInvalid('token');
    }
  }

  static void _requireCountry(String value) {
    if (!RegExp(r'^[A-Z]{2,3}$').hasMatch(value)) {
      throw const BackupInvalid('country');
    }
  }

  static void _requireCurrency(String value) {
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(value)) {
      throw const BackupInvalid('currency');
    }
  }

  static void _writeText(
    _Writer writer,
    String value, {
    required bool required,
  }) {
    _checkText(value, required: required);
    writer.str(value);
  }

  static String _readText(_Reader reader, {required bool required}) {
    final value = reader.str();
    _checkText(value, required: required);
    return value;
  }

  static void _checkText(String value, {required bool required}) {
    if (value.contains('\u0000')) {
      throw const BackupInvalid('text');
    }
    if (required && value.trim().isEmpty) {
      throw const BackupInvalid('text');
    }
    if (utf8.encode(value).length > BackupLimits.maxStringBytes) {
      throw const BackupOversized();
    }
  }

  static T _enumValue<T extends Enum>(List<T> values, String name) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    throw const BackupInvalid('value');
  }

  static Set<T> _enumSet<T extends Enum>(List<T> values, String raw) {
    try {
      return PersistedValues.decodeEnumSet(values, raw);
    } on FormatException {
      throw const BackupInvalid('value');
    }
  }
}

class _Writer {
  final _builder = BytesBuilder(copy: false);

  void u8(int value) {
    _range(value, 0, 0xFF);
    _builder.addByte(value);
    _guardSize();
  }

  void u16(int value) {
    _range(value, 0, 0xFFFF);
    _builder.addByte(value >> 8);
    _builder.addByte(value & 0xFF);
    _guardSize();
  }

  void u32(int value) {
    _range(value, 0, 0xFFFFFFFF);
    _builder.addByte((value >> 24) & 0xFF);
    _builder.addByte((value >> 16) & 0xFF);
    _builder.addByte((value >> 8) & 0xFF);
    _builder.addByte(value & 0xFF);
    _guardSize();
  }

  void i64(int value) {
    const min = -9223372036854775808;
    const max = 9223372036854775807;
    if (value < min || value > max) {
      throw const BackupInvalid('integer');
    }
    final unsigned = value < 0 ? value + (1 << 64) : value;
    u32(unsigned >> 32);
    u32(unsigned & 0xFFFFFFFF);
  }

  void flag(bool value) => u8(value ? 1 : 0);

  void str(String value) {
    final encoded = utf8.encode(value);
    if (encoded.length > BackupLimits.maxStringBytes) {
      throw const BackupOversized();
    }
    u32(encoded.length);
    bytes(encoded);
  }

  void optStr(String? value) {
    if (value == null) {
      u8(0);
      return;
    }
    u8(1);
    str(value);
  }

  void bytes(List<int> value) {
    _builder.add(value);
    _guardSize();
  }

  Uint8List takeBytes() => _builder.takeBytes();

  void _guardSize() {
    if (_builder.length > BackupLimits.maxPlaintextBytes) {
      throw const BackupOversized();
    }
  }

  void _range(int value, int min, int max) {
    if (value < min || value > max) {
      throw const BackupInvalid('integer');
    }
  }
}

class _Reader {
  _Reader(this._bytes);

  final Uint8List _bytes;
  var _offset = 0;

  int get remaining => _bytes.length - _offset;

  int u8() {
    _need(1);
    return _bytes[_offset++];
  }

  int u16() {
    _need(2);
    final value = (_bytes[_offset] << 8) | _bytes[_offset + 1];
    _offset += 2;
    return value;
  }

  int u32() {
    _need(4);
    final value =
        (_bytes[_offset] << 24) |
        (_bytes[_offset + 1] << 16) |
        (_bytes[_offset + 2] << 8) |
        _bytes[_offset + 3];
    _offset += 4;
    return value;
  }

  int i64() {
    final unsigned = (u32() << 32) | u32();
    const span = 1 << 64;
    const limit = 1 << 63;
    if (unsigned >= limit) {
      return unsigned - span;
    }
    return unsigned;
  }

  bool flag() {
    final value = u8();
    if (value == 1) {
      return true;
    }
    if (value == 0) {
      return false;
    }
    throw const BackupInvalid('flag');
  }

  String str() {
    final length = u32();
    if (length > BackupLimits.maxStringBytes) {
      throw const BackupOversized();
    }
    final data = byteCopy(length);
    try {
      final value = utf8.decode(data, allowMalformed: false);
      if (value.contains('\u0000')) {
        throw const BackupInvalid('text');
      }
      return value;
    } on FormatException {
      throw const BackupInvalid('text');
    }
  }

  String? optStr() {
    final flag = u8();
    if (flag == 0) {
      return null;
    }
    if (flag == 1) {
      return str();
    }
    throw const BackupInvalid('text');
  }

  Uint8List bytes(int length) {
    _need(length);
    final view = Uint8List.sublistView(_bytes, _offset, _offset + length);
    _offset += length;
    return view;
  }

  Uint8List byteCopy(int length) {
    return Uint8List.fromList(bytes(length));
  }

  void _need(int length) {
    if (length < 0 || _offset + length > _bytes.length) {
      throw const BackupInvalid('truncated');
    }
  }
}
