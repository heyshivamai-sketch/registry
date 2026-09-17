import 'package:flutter/foundation.dart';
import 'package:the_registry/features/documents/domain/document_repository.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';

class InMemoryDocumentRepository extends ChangeNotifier
    implements DocumentRepository {
  final List<RegistryDocument> _documents = [];

  @override
  List<RegistryDocument> get documents => List.unmodifiable(_documents);

  @override
  Future<void> save(RegistryDocument document) async {
    _documents.insert(0, document);
    notifyListeners();
  }
}
