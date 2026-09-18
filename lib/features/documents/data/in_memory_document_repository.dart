import 'package:flutter/foundation.dart';
import 'package:the_registry/features/documents/domain/document_repository.dart';
import 'package:the_registry/features/documents/domain/registry_document.dart';

class InMemoryDocumentRepository extends ChangeNotifier
    implements DocumentRepository {
  final List<RegistryDocument> _documents = [];

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
    _documents.insert(0, document);
    notifyListeners();
  }

  @override
  Future<bool> update(RegistryDocument document) async {
    final index = _documents.indexWhere((item) => item.id == document.id);
    if (index < 0) {
      return false;
    }
    _documents[index] = document;
    notifyListeners();
    return true;
  }

  @override
  Future<bool> delete(String id) async {
    final index = _documents.indexWhere((item) => item.id == id);
    if (index < 0) {
      return false;
    }
    _documents.removeAt(index);
    notifyListeners();
    return true;
  }
}
