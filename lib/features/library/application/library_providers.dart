import 'package:doc_reader/core/storage/preferences.dart';
import 'package:doc_reader/features/library/data/document_file_store.dart';
import 'package:doc_reader/features/library/data/prefs_library_repository.dart';
import 'package:doc_reader/features/library/domain/library_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dependencias de la biblioteca. Sobreescríbelas en tests.
final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => PrefsLibraryRepository(ref.watch(sharedPreferencesProvider)),
);

final documentFileStoreProvider = Provider<DocumentFileStore>(
  (ref) => DocumentFileStore(),
);
