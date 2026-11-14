import 'package:doc_reader/core/storage/preferences.dart';
import 'package:doc_reader/features/library/data/cover_cache.dart';
import 'package:doc_reader/features/library/data/document_file_store.dart';
import 'package:doc_reader/features/library/data/prefs_library_repository.dart';
import 'package:doc_reader/features/library/domain/document_source.dart';
import 'package:doc_reader/features/library/domain/library_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dependencias de la biblioteca. Sobreescríbelas en tests.
final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => PrefsLibraryRepository(ref.watch(sharedPreferencesProvider)),
);

final documentFileStoreProvider = Provider<DocumentFileStore>(
  (ref) => DocumentFileStore(),
);

final coverCacheProvider = Provider<CoverCache>((ref) => CoverCache());

/// Portada PNG de un PDF por id; queda en memoria durante la sesión para
/// que la biblioteca no vuelva a leer ni decodificar nada al redibujarse.
final pdfCoverProvider =
    FutureProvider.family<Uint8List?, (String, DocumentSource)>(
      (ref, key) => ref.watch(coverCacheProvider).pdfCover(key.$1, key.$2),
    );
