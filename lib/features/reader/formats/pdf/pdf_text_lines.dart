import 'package:doc_reader/features/highlights/domain/highlight.dart';

/// Une los rectángulos de cada carácter en un rectángulo por línea.
///
/// Los rectángulos están en coordenadas de página PDF (`top > bottom`). Dos
/// caracteres están en la misma línea si se solapan verticalmente más de la
/// mitad de la altura del más bajo. Los rectángulos vacíos (espacios, saltos
/// de línea) se ignoran.
List<HighlightRect> mergeCharRectsIntoLines(List<HighlightRect> chars) {
  final lines = <HighlightRect>[];
  HighlightRect? current;
  for (final r in chars) {
    if (r.right <= r.left || r.top <= r.bottom) continue;
    final line = current;
    if (line != null && _sameLine(line, r)) {
      current = HighlightRect(
        r.left < line.left ? r.left : line.left,
        r.top > line.top ? r.top : line.top,
        r.right > line.right ? r.right : line.right,
        r.bottom < line.bottom ? r.bottom : line.bottom,
      );
    } else {
      if (line != null) lines.add(line);
      current = r;
    }
  }
  if (current != null) lines.add(current);
  return lines;
}

bool _sameLine(HighlightRect a, HighlightRect b) {
  final overlap =
      (a.top < b.top ? a.top : b.top) -
      (a.bottom > b.bottom ? a.bottom : b.bottom);
  final minHeight = a.height < b.height ? a.height : b.height;
  return overlap > minHeight * 0.5;
}
