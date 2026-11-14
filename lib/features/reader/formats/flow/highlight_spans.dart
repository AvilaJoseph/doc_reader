import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/features/highlights/domain/highlight.dart';
import 'package:doc_reader/features/reader/formats/flow/flow_document.dart';

/// Convierte los [runs] de un párrafo en [TextSpan]s, partiendo los
/// fragmentos donde empieza o acaba un subrayado.
///
/// El texto resultante es idéntico a la concatenación de los runs, así que
/// los desplazamientos de la selección coinciden con los de [Highlight].
List<TextSpan> buildHighlightedSpans({
  required List<TextRun> runs,
  required List<Highlight> highlights,
  required TextStyle Function(TextRun run) styleFor,
  required Color Function(int colorIndex) colorFor,
}) {
  final sorted = [...highlights]..sort((a, b) => a.start.compareTo(b.start));
  final spans = <TextSpan>[];
  var offset = 0;

  for (final run in runs) {
    final runStart = offset;
    final runEnd = offset + run.text.length;
    offset = runEnd;
    if (run.text.isEmpty) continue;

    // Cortes dentro de este run.
    final cuts = <int>{runStart, runEnd};
    for (final h in sorted) {
      if (h.start > runStart && h.start < runEnd) cuts.add(h.start);
      if (h.end > runStart && h.end < runEnd) cuts.add(h.end);
    }
    final points = cuts.toList()..sort();
    final style = styleFor(run);

    for (var i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      Highlight? active;
      for (final h in sorted) {
        if (h.start <= start && h.end >= end) active = h;
      }
      spans.add(
        TextSpan(
          text: run.text.substring(start - runStart, end - runStart),
          style: active == null
              ? style
              : style.copyWith(backgroundColor: colorFor(active.colorIndex)),
        ),
      );
    }
  }
  return spans;
}
