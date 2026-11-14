import 'package:doc_reader/features/library/application/library_controller.dart';
import 'package:doc_reader/features/library/domain/document_kind.dart';
import 'package:doc_reader/features/library/domain/library_document.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final librarySearchProvider = NotifierProvider<LibrarySearch, String>(
  LibrarySearch.new,
);

class LibrarySearch extends Notifier<String> {
  @override
  String build() => '';

  String get query => state;
  set query(String value) => state = value;
}

final libraryKindFilterProvider =
    NotifierProvider<LibraryKindFilter, DocumentKind?>(LibraryKindFilter.new);

class LibraryKindFilter extends Notifier<DocumentKind?> {
  @override
  DocumentKind? build() => null;

  DocumentKind? get kind => state;
  set kind(DocumentKind? value) => state = value;
}

/// Biblioteca filtrada por búsqueda y tipo.
final filteredLibraryProvider = Provider<AsyncValue<List<LibraryDocument>>>((
  ref,
) {
  final query = _normalize(ref.watch(librarySearchProvider));
  final kind = ref.watch(libraryKindFilterProvider);
  return ref
      .watch(libraryControllerProvider)
      .whenData(
        (docs) => [
          for (final doc in docs)
            if ((kind == null || doc.kind == kind) &&
                (query.isEmpty ||
                    _normalize(doc.title).contains(query) ||
                    _normalize(doc.fileName).contains(query)))
              doc,
        ],
      );
});

/// Minúsculas y sin tildes, para que "guia" encuentre "Guía".
String _normalize(String value) {
  const from = 'áàäâéèëêíìïîóòöôúùüûñç';
  const to = 'aaaaeeeeiiiioooouuuunc';
  final lower = value.toLowerCase().trim();
  final buffer = StringBuffer();
  for (final char in lower.split('')) {
    final index = from.indexOf(char);
    buffer.write(index >= 0 ? to[index] : char);
  }
  return buffer.toString();
}
