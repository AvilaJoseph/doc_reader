import 'dart:convert';

import 'package:doc_reader/features/library/domain/library_document.dart';
import 'package:doc_reader/features/library/domain/library_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda la biblioteca como JSON en [SharedPreferences].
///
/// Suficiente para cientos de documentos. Si la biblioteca crece mucho
/// (carpetas, búsqueda de texto completo…), sustitúyelo por una base de
/// datos implementando el mismo [LibraryRepository].
class PrefsLibraryRepository implements LibraryRepository {
  new(this._prefs);

  static const storageKey = 'library.documents.v1';

  final SharedPreferences _prefs;

  @override
  Future<List<LibraryDocument>> loadAll() async {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<Object?>;
      return [
        for (final item in list)
          LibraryDocument.fromJson((item! as Map).cast<String, Object?>()),
      ];
    } on Object catch (error) {
      debugPrint('Biblioteca corrupta, se reinicia: $error');
      return const [];
    }
  }

  @override
  Future<void> saveAll(List<LibraryDocument> documents) async {
    final raw = jsonEncode([for (final doc in documents) doc.toJson()]);
    await _prefs.setString(storageKey, raw);
  }
}
