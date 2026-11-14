import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/features/highlights/domain/highlight.dart';
import 'package:doc_reader/features/reader/formats/flow/flow_document.dart';
import 'package:doc_reader/features/reader/formats/flow/highlight_spans.dart';
import 'package:flutter_test/flutter_test.dart';

Highlight h(
  int start,
  int end, {
  int color = 0,
  HighlightStyle style = HighlightStyle.highlight,
  String? note,
}) => Highlight(
  id: '$start-$end',
  documentId: 'd',
  blockIndex: 0,
  start: start,
  end: end,
  colorIndex: color,
  text: '',
  createdAt: DateTime(2026),
  style: style,
  note: note,
);

void main() {
  const red = Color(0xFFFF0000);
  const blue = Color(0xFF0000FF);
  List<TextSpan> build(List<TextRun> runs, List<Highlight> highlights) =>
      buildHighlightedSpans(
        runs: runs,
        highlights: highlights,
        styleFor: (run) => TextStyle(
          fontWeight: run.bold ? FontWeight.bold : FontWeight.normal,
        ),
        colorFor: (_) => red,
        underlineColor: blue,
      );

  test('sin subrayados conserva los runs', () {
    final spans = build(const [TextRun('Hola '), TextRun('mundo')], []);
    expect(spans.map((s) => s.text), ['Hola ', 'mundo']);
  });

  test('parte los runs en los bordes del subrayado', () {
    final spans = build(
      const [TextRun('Hola '), TextRun('mundo', bold: true)],
      [h(2, 8)],
    );
    expect(spans.map((s) => s.text).join(), 'Hola mundo');
    expect(spans.map((s) => s.text), ['Ho', 'la ', 'mun', 'do']);
    expect(spans[0].style?.backgroundColor, isNull);
    expect(spans[1].style?.backgroundColor, red);
    expect(spans[2].style?.backgroundColor, red);
    expect(spans[2].style?.fontWeight, FontWeight.bold);
    expect(spans[3].style?.backgroundColor, isNull);
  });

  test('el estilo subrayado pinta una línea en vez de fondo', () {
    final spans = build(
      const [TextRun('Hola mundo')],
      [h(0, 4, style: HighlightStyle.underline)],
    );
    expect(spans.first.text, 'Hola');
    expect(spans.first.style?.backgroundColor, isNull);
    expect(spans.first.style?.decoration, TextDecoration.underline);
    expect(spans.first.style?.decorationColor, blue);
  });

  test('un resaltado con nota lleva línea punteada', () {
    final spans = build(const [TextRun('Hola')], [h(0, 4, note: 'ojo')]);
    expect(spans.single.style?.backgroundColor, red);
    expect(spans.single.style?.decorationStyle, TextDecorationStyle.dotted);
  });

  test('Highlight se serializa con estilo, nota y rectángulos', () {
    final original = Highlight(
      id: 'x',
      documentId: 'd',
      blockIndex: 3,
      start: 1,
      end: 9,
      colorIndex: 2,
      text: 'texto',
      createdAt: DateTime(2026),
      style: HighlightStyle.underline,
      note: 'Importante',
      rects: const [HighlightRect(10, 700, 200, 688)],
    );
    final copy = Highlight.fromJson(original.toJson());
    expect(copy, original);
    expect(copy.isPdf, isTrue);
    // JSON antiguo sin campos nuevos.
    final legacy = Highlight.fromJson(const {
      'id': 'y',
      'documentId': 'd',
      'blockIndex': 0,
      'start': 0,
      'end': 2,
      'colorIndex': 0,
      'text': 'ab',
      'createdAt': '2026-01-01T00:00:00.000',
    });
    expect(legacy.style, HighlightStyle.highlight);
    expect(legacy.note, isNull);
  });

  test('Highlight.overlaps detecta solapes', () {
    expect(h(2, 5).overlaps(4, 9), isTrue);
    expect(h(2, 5).overlaps(5, 9), isFalse);
  });
}
