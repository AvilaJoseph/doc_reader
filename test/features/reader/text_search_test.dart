import 'package:doc_reader/features/reader/search/text_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normaliza tildes y mayúsculas sin cambiar la longitud', () {
    const text = 'Canción ÁRBOL Niño';
    final normalized = normalizeForSearch(text);
    expect(normalized, 'cancion arbol nino');
    expect(normalized.length, text.length);
  });

  test('encuentra todas las coincidencias en orden de lectura', () {
    final index = SearchIndex(['La canción', '', 'cancion y CANCIÓN']);
    expect(index.find('Canción'), const [
      SearchMatch(blockIndex: 0, start: 3, end: 10),
      SearchMatch(blockIndex: 2, start: 0, end: 7),
      SearchMatch(blockIndex: 2, start: 10, end: 17),
    ]);
  });

  test('consulta vacía o sin resultados', () {
    final index = SearchIndex(['hola']);
    expect(index.find('  '), isEmpty);
    expect(index.find('adiós'), isEmpty);
  });

  test('respeta el límite de resultados', () {
    final index = SearchIndex(['a a a a a']);
    expect(index.find('a', limit: 3), hasLength(3));
  });

  test('el patrón para PDF ignora tildes y mayúsculas', () {
    final pattern = accentInsensitivePattern('cancion (2)');
    expect(pattern.hasMatch('La CANCIÓN (2) suena'), isTrue);
    expect(pattern.hasMatch('cancion 2'), isFalse);
  });
}
