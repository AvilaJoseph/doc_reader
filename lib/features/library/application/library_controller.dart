import 'dart:async';

import 'package:collection/collection.dart';
import 'package:doc_reader/features/library/application/library_providers.dart';
import 'package:doc_reader/features/library/application/sample_documents.dart';
import 'package:doc_reader/features/library/data/document_file_store.dart';
import 'package:doc_reader/features/library/domain/document_kind.dart';
import 'package:doc_reader/features/library/domain/document_source.dart';
import 'package:doc_reader/features/library/domain/library_document.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Resultado de una importación para informar al usuario.
typedef ImportResult = ({
  List<LibraryDocument> added,
  List<String> unsupported,
  List<String> failed,
});

final libraryControllerProvider =
    AsyncNotifierProvider<LibraryController, List<LibraryDocument>>(
      LibraryController.new,
    );

/// Estado de la biblioteca: lista ordenada por uso reciente.
class LibraryController extends AsyncNotifier<List<LibraryDocument>> {
  static const _uuid = Uuid();

  @override
  Future<List<LibraryDocument>> build() async {
    final docs = await ref.read(libraryRepositoryProvider).loadAll();
    return _sorted(docs);
  }

  List<LibraryDocument> get _current => state.value ?? const [];

  LibraryDocument? byId(String id) =>
      _current.firstWhereOrNull((doc) => doc.id == id);

  Future<ImportResult> import(List<ImportCandidate> candidates) async {
    final store = ref.read(documentFileStoreProvider);
    final added = <LibraryDocument>[];
    final unsupported = <String>[];
    final failed = <String>[];

    for (final candidate in candidates) {
      final kind = DocumentKind.fromFileName(candidate.name);
      if (kind == null) {
        unsupported.add(candidate.name);
        continue;
      }
      final duplicate = _current.firstWhereOrNull(
        (doc) =>
            doc.fileName == candidate.name &&
            candidate.sizeBytes != null &&
            doc.sizeBytes == candidate.sizeBytes,
      );
      if (duplicate != null) {
        added.add(duplicate);
        continue;
      }
      try {
        final id = _uuid.v4();
        final stored = await store.store(candidate, id: id);
        added.add(
          LibraryDocument(
            id: id,
            title: p.basenameWithoutExtension(candidate.name),
            fileName: candidate.name,
            kind: kind,
            source: stored.source,
            sizeBytes: stored.sizeBytes,
            addedAt: DateTime.now(),
          ),
        );
      } on Object {
        failed.add(candidate.name);
      }
    }

    final newOnes = added.where((doc) => byId(doc.id) == null);
    await _commit([...newOnes, ..._current]);
    return (added: added, unsupported: unsupported, failed: failed);
  }

  /// Añade los documentos de ejemplo que aún no estén en la biblioteca.
  Future<void> addSamples() async {
    final existing = _current
        .map((doc) => doc.source)
        .whereType<AssetSource>()
        .map((source) => source.assetPath)
        .toSet();
    final now = DateTime.now();
    final samples = [
      for (final (index, sample) in SampleDocuments.all.indexed)
        if (!existing.contains(sample.asset))
          LibraryDocument(
            id: _uuid.v4(),
            title: sample.title,
            fileName: p.basename(sample.asset),
            kind: SampleDocuments.kindOf(sample.asset),
            source: AssetSource(sample.asset),
            sizeBytes: 0,
            // Orden estable: el primero de la lista queda arriba.
            addedAt: now.subtract(Duration(seconds: index)),
          ),
    ];
    await _commit([..._current, ...samples]);
  }

  Future<void> markOpened(String id) =>
      _update(id, (doc) => doc.copyWith(lastOpenedAt: DateTime.now()));

  Future<void> saveProgress(
    String id, {
    required double progress,
    required double position,
  }) => _update(
    id,
    (doc) => doc.copyWith(progress: progress.clamp(0, 1), position: position),
    resort: false,
  );

  /// Marca o desmarca [page] como marcador del documento.
  Future<void> toggleBookmark(String id, int page) => _update(id, (doc) {
    final pages = {...doc.bookmarks};
    if (!pages.remove(page)) pages.add(page);
    return doc.copyWith(bookmarks: pages.toList()..sort());
  }, resort: false);

  Future<void> toggleFavorite(String id) => _update(
    id,
    (doc) => doc.copyWith(favorite: !doc.favorite),
    resort: false,
  );

  Future<void> rename(String id, String title) =>
      _update(id, (doc) => doc.copyWith(title: title.trim()));

  /// Quita el documento de la lista sin borrar el archivo, para poder
  /// deshacer. Llama a [purge] cuando ya no se pueda deshacer.
  Future<LibraryDocument?> remove(String id) async {
    final doc = byId(id);
    if (doc == null) return null;
    await _commit(_current.where((d) => d.id != id).toList());
    return doc;
  }

  Future<void> restore(LibraryDocument doc) async {
    if (byId(doc.id) != null) return;
    await _commit([..._current, doc]);
  }

  /// Borra definitivamente la copia local de un documento ya quitado.
  Future<void> purge(LibraryDocument doc) async {
    if (byId(doc.id) != null) return;
    await ref.read(documentFileStoreProvider).delete(doc.source);
    await ref.read(coverCacheProvider).remove(doc.id);
  }

  Future<void> _update(
    String id,
    LibraryDocument Function(LibraryDocument doc) change, {
    bool resort = true,
  }) async {
    final docs = [
      for (final doc in _current)
        if (doc.id == id) change(doc) else doc,
    ];
    await _commit(docs, resort: resort);
  }

  Future<void> _commit(List<LibraryDocument> docs, {bool resort = true}) async {
    final next = resort ? _sorted(docs) : docs;
    state = AsyncData(next);
    await ref.read(libraryRepositoryProvider).saveAll(next);
  }

  static List<LibraryDocument> _sorted(List<LibraryDocument> docs) =>
      docs.sorted((a, b) => b.recency.compareTo(a.recency));
}
