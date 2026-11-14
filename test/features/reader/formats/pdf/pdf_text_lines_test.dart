import 'package:doc_reader/features/highlights/domain/highlight.dart';
import 'package:doc_reader/features/reader/formats/pdf/pdf_text_lines.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('une caracteres de la misma línea y separa líneas', () {
    final lines = mergeCharRectsIntoLines(const [
      HighlightRect(10, 700, 16, 688),
      HighlightRect(16, 701, 22, 689),
      HighlightRect(22, 700, 22, 700), // espacio vacío
      HighlightRect(24, 700, 30, 688),
      HighlightRect(10, 680, 16, 668), // siguiente línea
      HighlightRect(16, 680, 40, 668),
    ]);
    expect(lines, const [
      HighlightRect(10, 701, 30, 688),
      HighlightRect(10, 680, 40, 668),
    ]);
  });

  test('sin caracteres no hay líneas', () {
    expect(mergeCharRectsIntoLines(const []), isEmpty);
  });
}
