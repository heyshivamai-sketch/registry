import 'package:flutter/foundation.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';

abstract class DocumentRepository implements Listenable {
  List<RegistryDocument> get documents;

  RegistryDocument? findById(String id);

  Future<void> save(RegistryDocument document);

  Future<bool> update(RegistryDocument document);

  Future<bool> delete(String id);
}
