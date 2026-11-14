import 'dart:async';

import 'package:collection/collection.dart';
import 'package:doc_reader/core/storage/preferences.dart';
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

/// Solo favoritos (excluye el filtro por tipo: es una píldora más).
final libraryFavoritesOnlyProvider =
    NotifierProvider<LibraryFavoritesOnly, bool>(LibraryFavoritesOnly.new);

class LibraryFavoritesOnly extends Notifier<bool> {
  @override
  bool build() => false;

  bool get enabled => state;
  set enabled(bool value) => state = value;
}

/// Orden de la biblioteca.
enum LibrarySort { recent, title, added, progress }

final librarySortProvider =
    NotifierProvider<LibrarySortController, LibrarySort>(
      LibrarySortController.new,
    );

/// Orden elegido, recordado entre sesiones.
class LibrarySortController extends Notifier<LibrarySort> {
  static const _key = 'library.sort';

  @override
  LibrarySort build() {
    final name = ref.watch(sharedPreferencesProvider).getString(_key);
    return LibrarySort.values.firstWhere(
      (s) => s.name == name,
      orElse: () => LibrarySort.recent,
    );
  }

  void select(LibrarySort sort) {
    state = sort;
    unawaited(ref.read(sharedPreferencesProvider).setString(_key, sort.name));
  }
}

/// Ordena [docs] según [sort] (sin modificar la lista original).
List<LibraryDocument> sortDocuments(
  List<LibraryDocument> docs,
  LibrarySort sort,
) => switch (sort) {
  LibrarySort.recent => docs,
  LibrarySort.title => docs.sorted(
    (a, b) => _normalize(a.title).compareTo(_normalize(b.title)),
  ),
  LibrarySort.added => docs.sorted((a, b) => b.addedAt.compareTo(a.addedAt)),
  LibrarySort.progress => docs.sorted(
    (a, b) => b.progress.compareTo(a.progress),
  ),
};

/// Biblioteca filtrada por búsqueda y tipo.
final filteredLibraryProvider = Provider<AsyncValue<List<LibraryDocument>>>((
  ref,
) {
  final query = _normalize(ref.watch(librarySearchProvider));
  final kind = ref.watch(libraryKindFilterProvider);
  final favorites = ref.watch(libraryFavoritesOnlyProvider);
  final sort = ref.watch(librarySortProvider);
  return ref
      .watch(libraryControllerProvider)
      .whenData(
        (docs) => sortDocuments([
          for (final doc in docs)
            if ((kind == null || doc.kind == kind) &&
                (!favorites || doc.favorite) &&
                (query.isEmpty ||
                    _normalize(doc.title).contains(query) ||
                    _normalize(doc.fileName).contains(query)))
              doc,
        ], sort),
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
