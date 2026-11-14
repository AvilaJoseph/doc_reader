import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

/// Modelo intermedio para documentos de texto "fluido" (Word, TXT, Markdown).
///
/// Los parsers convierten cada formato a este modelo y un único visor
/// lo pinta. Así, añadir un formato nuevo de texto solo
/// requiere escribir un parser. Lo pinta `FlowReaderScreen`.
@immutable
class FlowDocument {
  const new({required this.blocks, this.title});

  /// Título detectado dentro del documento (si lo hay).
  final String? title;
  final List<FlowBlock> blocks;

  bool get isEmpty => blocks.isEmpty;
}

@immutable
/// Bloque de contenido. El índice del bloque en [FlowDocument.blocks] es la
/// referencia estable que usan los subrayados.
sealed class FlowBlock {
  const new();
}

enum FlowAlignment { start, center, end, justify }

/// Párrafo o encabezado con texto enriquecido.
final class ParagraphBlock extends FlowBlock {
  const new({
    required this.runs,
    this.headingLevel = 0,
    this.alignment = FlowAlignment.start,
    this.list,
  });

  /// Fragmentos de texto con estilo. Su concatenación es [plainText].
  final List<TextRun> runs;

  /// 0 = párrafo normal, 1..6 = encabezado.
  final int headingLevel;
  final FlowAlignment alignment;

  /// Información de lista si el párrafo es un elemento de lista.
  final ListInfo? list;

  bool get isHeading => headingLevel > 0;

  String get plainText => runs.map((r) => r.text).join();

  @override
  bool operator ==(Object other) =>
      other is ParagraphBlock &&
      other.headingLevel == headingLevel &&
      other.alignment == alignment &&
      other.list == list &&
      const ListEquality<TextRun>().equals(other.runs, runs);

  @override
  int get hashCode => Object.hash(
    headingLevel,
    alignment,
    list,
    const ListEquality<TextRun>().hash(runs),
  );

  @override
  String toString() =>
      'ParagraphBlock(h$headingLevel, ${list ?? ''} "$plainText")';
}

/// Elemento de una lista con viñetas o numerada.
@immutable
class ListInfo {
  const new({required this.level, required this.marker});

  /// Nivel de sangría, empezando en 0.
  final int level;

  /// Texto del marcador ya resuelto: "•", "1.", "a)", …
  final String marker;

  @override
  bool operator ==(Object other) =>
      other is ListInfo && other.level == level && other.marker == marker;

  @override
  int get hashCode => Object.hash(level, marker);

  @override
  String toString() => 'ListInfo($level, $marker)';
}

/// Fragmento de texto con un estilo uniforme.
@immutable
class TextRun {
  const new(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.code = false,
    this.link,
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;

  /// Texto monoespaciado (código en Markdown).
  final bool code;

  /// URL si el fragmento es un enlace.
  final String? link;

  bool sameStyleAs(TextRun other) =>
      bold == other.bold &&
      italic == other.italic &&
      underline == other.underline &&
      strike == other.strike &&
      code == other.code &&
      link == other.link;

  TextRun copyWithText(String newText) => TextRun(
    newText,
    bold: bold,
    italic: italic,
    underline: underline,
    strike: strike,
    code: code,
    link: link,
  );

  @override
  bool operator ==(Object other) =>
      other is TextRun && other.text == text && sameStyleAs(other);

  @override
  int get hashCode =>
      Object.hash(text, bold, italic, underline, strike, code, link);

  @override
  String toString() =>
      'TextRun("$text"${bold ? ' b' : ''}${italic ? ' i' : ''})';
}

/// Tabla simple: filas de celdas de texto plano.
final class TableBlock extends FlowBlock {
  const new({required this.rows});

  final List<List<String>> rows;

  int get columnCount =>
      rows.fold(0, (max, row) => row.length > max ? row.length : max);
}

/// Imagen incrustada (PNG, JPEG, GIF, WebP, BMP).
final class ImageBlock extends FlowBlock {
  const new({required this.bytes, this.description});

  final Uint8List bytes;
  final String? description;
}

/// Separador horizontal / salto de página.
final class DividerBlock extends FlowBlock {
  const new();
}
