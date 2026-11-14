import 'package:collection/collection.dart';
import 'package:doc_reader/features/highlights/domain/highlight.dart';

/// Convierte los subrayados de un documento en Markdown para compartir
/// (notas, correo, otra app de apuntes), en orden de lectura.
///
/// [pageLabel] y [noteLabel] llegan ya traducidos desde la UI.
String highlightsToMarkdown({
  required String title,
  required List<Highlight> highlights,
  required String Function(int page) pageLabel,
  required String noteLabel,
}) {
  final ordered = highlights.sorted((a, b) {
    final byBlock = a.blockIndex.compareTo(b.blockIndex);
    return byBlock != 0 ? byBlock : a.start.compareTo(b.start);
  });
  final buffer = StringBuffer('# $title\n');
  for (final h in ordered) {
    buffer.write('\n> ${h.text.trim().replaceAll('\n', '\n> ')}\n');
    if (h.isPdf) buffer.write('\n— ${pageLabel(h.blockIndex)}\n');
    if (h.hasNote) buffer.write('\n**$noteLabel:** ${h.note!.trim()}\n');
  }
  return buffer.toString();
}
