import 'dart:convert';
import 'dart:io';

import 'package:doc_reader/features/library/application/library_controller.dart';
import 'package:doc_reader/features/library/application/library_filter.dart';
import 'package:doc_reader/features/library/application/library_providers.dart';
import 'package:doc_reader/features/library/data/cover_cache.dart';
import 'package:doc_reader/features/library/data/document_file_store.dart';
import 'package:doc_reader/features/library/data/prefs_library_repository.dart';
import 'package:doc_reader/features/library/domain/document_kind.dart';
import 'package:doc_reader/features/library/domain/document_source.dart';
import 'package:doc_reader/features/library/domain/library_document.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_app.dart';

ImportCandidate candidate(String name, String content) {
  final bytes = utf8.encode(content);
  return ImportCandidate(
    name: name,
    sizeBytes: bytes.length,
    openRead: () => Stream.value(bytes),
  );
}

void main() {
  late Directory tempDir;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('library_test');
    container = await createContainer(
      overrides: [
        documentFileStoreProvider.overrideWithValue(
          DocumentFileStore(baseDirectory: () async => tempDir),
        ),
        coverCacheProvider.overrideWithValue(
          CoverCache(baseDirectory: () async => tempDir),
        ),
      ],
    );
    await container.read(libraryControllerProvider.future);
  });

  tearDown(() async {
    container.dispose();
    await tempDir.delete(recursive: true);
  });

  LibraryController controller() =>
      container.read(libraryControllerProvider.notifier);
  List<LibraryDocument> docs() =>
      container.read(libraryControllerProvider).value!;

  test('importa archivos soportados y rechaza el resto', () async {
    final result = await controller().import([
      candidate('notas.txt', 'Hola'),
      candidate('viejo.doc', 'x'),
    ]);

    expect(result.added, hasLength(1));
    expect(result.unsupported, ['viejo.doc']);
    final doc = docs().single;
    expect(doc.title, 'notas');
    expect(doc.kind, DocumentKind.text);
    final path = (doc.source as FileSource).path;
    expect(File(path).readAsStringSync(), 'Hola');
  });

  test('no duplica el mismo archivo', () async {
    await controller().import([candidate('a.txt', 'uno')]);
    final again = await controller().import([candidate('a.txt', 'uno')]);
    expect(docs(), hasLength(1));
    expect(again.added.single.id, docs().single.id);
  });

  test('persiste la biblioteca en SharedPreferences', () async {
    await controller().import([candidate('a.md', '# Hola')]);
    final prefs = await SharedPreferences.getInstance();
    final restored = await PrefsLibraryRepository(prefs).loadAll();
    expect(restored.single.fileName, 'a.md');
  });

  test('guarda progreso y lo limita entre 0 y 1', () async {
    await controller().import([candidate('a.txt', 'x')]);
    final id = docs().single.id;
    await controller().saveProgress(id, progress: 1.4, position: 0.5);
    expect(docs().single.progress, 1);
    expect(docs().single.position, 0.5);
  });

  test('marca y desmarca páginas y favoritos', () async {
    await controller().import([candidate('a.txt', 'x')]);
    final id = docs().single.id;
    await controller().toggleBookmark(id, 7);
    await controller().toggleBookmark(id, 2);
    expect(docs().single.bookmarks, [2, 7]);
    await controller().toggleBookmark(id, 7);
    expect(docs().single.bookmarks, [2]);

    await controller().toggleFavorite(id);
    expect(docs().single.favorite, isTrue);
  });

  test('quitar permite deshacer y purgar borra el archivo', () async {
    await controller().import([candidate('a.txt', 'x')]);
    final doc = docs().single;
    final path = (doc.source as FileSource).path;

    await controller().remove(doc.id);
    expect(docs(), isEmpty);
    await controller().restore(doc);
    expect(docs(), hasLength(1));

    final cover = File('${tempDir.path}/covers/${doc.id}.png')
      ..createSync(recursive: true);
    await controller().remove(doc.id);
    await controller().purge(doc);
    expect(File(path).existsSync(), isFalse);
    expect(cover.existsSync(), isFalse);
  });

  test('añade los ejemplos una sola vez', () async {
    await controller().addSamples();
    final count = docs().length;
    await controller().addSamples();
    expect(docs(), hasLength(count));
    expect(docs().every((d) => d.source is AssetSource), isTrue);
  });

  test('filtra por búsqueda sin tildes y por tipo', () async {
    await controller().import([
      candidate('Guía práctica.txt', 'x'),
      candidate('Datos.csv', 'a,b'),
    ]);
    container.read(librarySearchProvider.notifier).query = 'guia';
    expect(
      container.read(filteredLibraryProvider).value!.single.title,
      'Guía práctica',
    );

    container.read(librarySearchProvider.notifier).query = '';
    container.read(libraryKindFilterProvider.notifier).kind =
        DocumentKind.spreadsheet;
    expect(
      container.read(filteredLibraryProvider).value!.single.fileName,
      'Datos.csv',
    );
  });
}
