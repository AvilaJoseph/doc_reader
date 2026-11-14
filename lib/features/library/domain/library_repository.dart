import 'package:doc_reader/features/library/domain/library_document.dart';

/// Persistencia de la biblioteca. La UI nunca habla con el almacenamiento
/// directamente: siempre a través de este contrato.
abstract interface class LibraryRepository {
  Future<List<LibraryDocument>> loadAll();

  Future<void> saveAll(List<LibraryDocument> documents);
}
