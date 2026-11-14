import 'package:flutter/foundation.dart';

/// Coincidencia de una búsqueda dentro de un bloque de texto.
@immutable
class SearchMatch {
  const new({required this.blockIndex, required this.start, required this.end});

  final int blockIndex;
  final int start;
  final int end;

  @override
  bool operator ==(Object other) =>
      other is SearchMatch &&
      other.blockIndex == blockIndex &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(blockIndex, start, end);

  @override
  String toString() => 'SearchMatch($blockIndex, $start–$end)';
}

const _accents = 'áàäâãåéèëêíìïîóòöôõúùüûñçÁÀÄÂÃÅÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛÑÇ';
const _plain = 'aaaaaaeeeeiiiiooooouuuuncaaaaaaeeeeiiiiooooouuuunc';

/// Pasa a minúsculas y quita tildes conservando la longitud, para que los
/// índices de la coincidencia sirvan sobre el texto original.
String normalizeForSearch(String text) {
  final out = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    final accent = _accents.indexOf(char);
    if (accent >= 0) {
      out.write(_plain[accent]);
      continue;
    }
    final lower = char.toLowerCase();
    out.write(lower.length == 1 ? lower : char);
  }
  return out.toString();
}

/// Índice de búsqueda: los textos ya normalizados, calculados una vez.
class SearchIndex {
  new(List<String> texts)
    : _texts = [for (final t in texts) normalizeForSearch(t)];

  final List<String> _texts;

  /// Todas las coincidencias de [query] en orden de lectura. Ignora
  /// mayúsculas y tildes. Una consulta vacía no devuelve nada.
  List<SearchMatch> find(String query, {int limit = 2000}) {
    final needle = normalizeForSearch(query.trim());
    if (needle.isEmpty) return const [];
    final matches = <SearchMatch>[];
    for (var block = 0; block < _texts.length; block++) {
      final text = _texts[block];
      var from = 0;
      while (true) {
        final at = text.indexOf(needle, from);
        if (at < 0) break;
        matches.add(
          SearchMatch(blockIndex: block, start: at, end: at + needle.length),
        );
        if (matches.length >= limit) return matches;
        from = at + needle.length;
      }
    }
    return matches;
  }
}

const _variants = {
  'a': 'aáàäâãå',
  'e': 'eéèëê',
  'i': 'iíìïî',
  'o': 'oóòöôõ',
  'u': 'uúùüû',
  'n': 'nñ',
  'c': 'cç',
};

/// Expresión que encuentra [query] ignorando mayúsculas y tildes, para
/// buscadores que reciben un patrón (el de PDF).
RegExp accentInsensitivePattern(String query) {
  final buffer = StringBuffer();
  for (final char in normalizeForSearch(query.trim()).split('')) {
    final variants = _variants[char];
    buffer.write(variants == null ? RegExp.escape(char) : '[$variants]');
  }
  return RegExp(buffer.toString(), caseSensitive: false, unicode: true);
}
