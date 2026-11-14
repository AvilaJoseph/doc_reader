import 'dart:convert';

import 'package:doc_reader/features/highlights/domain/highlight.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class HighlightsRepository {
  Future<List<Highlight>> loadAll();

  Future<void> saveAll(List<Highlight> highlights);
}

class PrefsHighlightsRepository implements HighlightsRepository {
  new(this._prefs);

  static const storageKey = 'highlights.v1';

  final SharedPreferences _prefs;

  @override
  Future<List<Highlight>> loadAll() async {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return [
        for (final item in jsonDecode(raw) as List<Object?>)
          Highlight.fromJson((item! as Map).cast<String, Object?>()),
      ];
    } on Object catch (error) {
      debugPrint('Subrayados corruptos, se reinician: $error');
      return const [];
    }
  }

  @override
  Future<void> saveAll(List<Highlight> highlights) => _prefs.setString(
    storageKey,
    jsonEncode([for (final h in highlights) h.toJson()]),
  );
}
