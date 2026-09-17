import 'package:flutter/foundation.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';

abstract class DocumentRepository implements Listenable {
  List<RegistryDocument> get documents;

  Future<void> save(RegistryDocument document);
}
