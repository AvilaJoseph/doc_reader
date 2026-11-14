import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/features/highlights/domain/highlight.dart';
import 'package:doc_reader/features/reader/formats/flow/flow_document.dart';
import 'package:doc_reader/features/reader/formats/flow/highlight_spans.dart';
import 'package:flutter_test/flutter_test.dart';

Highlight h(int start, int end, [int color = 0]) => Highlight(
  id: '$start-$end',
  documentId: 'd',
  blockIndex: 0,
  start: start,
  end: end,
  colorIndex: color,
  text: '',
  createdAt: DateTime(2026),
);

void main() {
  const red = Color(0xFFFF0000);
  List<TextSpan> build(List<TextRun> runs, List<Highlight> highlights) =>
      buildHighlightedSpans(
        runs: runs,
        highlights: highlights,
        styleFor: (run) => TextStyle(
          fontWeight: run.bold ? FontWeight.bold : FontWeight.normal,
        ),
        colorFor: (_) => red,
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

  test('Highlight.overlaps detecta solapes', () {
    expect(h(2, 5).overlaps(4, 9), isTrue);
    expect(h(2, 5).overlaps(5, 9), isFalse);
  });
}
