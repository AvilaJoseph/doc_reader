import 'package:doc_reader/features/highlights/application/highlights_export.dart';
import 'package:doc_reader/features/highlights/domain/highlight.dart';
import 'package:flutter_test/flutter_test.dart';

Highlight _h(
  String id,
  int block,
  int start,
  String text, {
  String? note,
  bool pdf = false,
}) => Highlight(
  id: id,
  documentId: 'd',
  blockIndex: block,
  start: start,
  end: start + text.length,
  colorIndex: 0,
  text: text,
  createdAt: DateTime(2026),
  note: note,
  rects: pdf ? const [HighlightRect(0, 0, 1, 1)] : const [],
);

void main() {
  test('exporta en orden de lectura con página y nota', () {
    final md = highlightsToMarkdown(
      title: 'Informe',
      highlights: [
        _h('b', 3, 0, 'Segundo', pdf: true, note: 'revisar'),
        _h('a', 1, 5, 'Primero\nen dos líneas', pdf: true),
      ],
      pageLabel: (p) => 'Pág. $p',
      noteLabel: 'Nota',
    );
    expect(
      md,
      '# Informe\n'
      '\n> Primero\n> en dos líneas\n'
      '\n— Pág. 1\n'
      '\n> Segundo\n'
      '\n— Pág. 3\n'
      '\n**Nota:** revisar\n',
    );
  });

  test('en documentos de texto no pone página', () {
    final md = highlightsToMarkdown(
      title: 'Notas',
      highlights: [_h('a', 0, 0, 'Hola')],
      pageLabel: (p) => 'Pág. $p',
      noteLabel: 'Nota',
    );
    expect(md, '# Notas\n\n> Hola\n');
  });
}
