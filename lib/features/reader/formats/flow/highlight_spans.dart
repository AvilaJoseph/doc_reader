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
  required Color underlineColor,
  List<TextRange> searchHits = const [],
  int? currentHit,
  Color? searchColor,
  Color? currentSearchColor,
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
    for (final hit in searchHits) {
      if (hit.start > runStart && hit.start < runEnd) cuts.add(hit.start);
      if (hit.end > runStart && hit.end < runEnd) cuts.add(hit.end);
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
      int? hit;
      for (var j = 0; j < searchHits.length; j++) {
        if (searchHits[j].start <= start && searchHits[j].end >= end) hit = j;
      }
      final marked = switch (active) {
        null => style,
        Highlight(style: HighlightStyle.underline) => style.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: underlineColor,
          decorationThickness: 1.8,
        ),
        final h => style.copyWith(
          backgroundColor: colorFor(h.colorIndex),
          // Las marcas con nota llevan una línea punteada discreta.
          decoration: h.hasNote ? TextDecoration.underline : null,
          decorationStyle: h.hasNote ? TextDecorationStyle.dotted : null,
          decorationColor: h.hasNote ? underlineColor : null,
        ),
      };
      spans.add(
        TextSpan(
          text: run.text.substring(start - runStart, end - runStart),
          // La búsqueda se pinta encima de cualquier marca.
          style: hit == null
              ? marked
              : marked.copyWith(
                  backgroundColor: hit == currentHit
                      ? currentSearchColor
                      : searchColor,
                ),
        ),
      );
    }
  }
  return spans;
}
