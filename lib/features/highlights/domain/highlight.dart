import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

/// Cómo se marca el fragmento.
enum HighlightStyle {
  /// Fondo de color (resaltador).
  highlight,

  /// Línea bajo el texto.
  underline,
}

/// Rectángulo en coordenadas de página PDF (origen abajo a la izquierda,
/// `top > bottom`). Solo lo usan los subrayados de PDF.
@immutable
class HighlightRect {
  const new(this.left, this.top, this.right, this.bottom);

  factory fromJson(List<Object?> json) => HighlightRect(
    (json[0]! as num).toDouble(),
    (json[1]! as num).toDouble(),
    (json[2]! as num).toDouble(),
    (json[3]! as num).toDouble(),
  );

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get height => top - bottom;

  List<double> toJson() => [left, top, right, bottom];

  @override
  bool operator ==(Object other) =>
      other is HighlightRect &&
      other.left == left &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  @override
  String toString() => 'HighlightRect($left, $top, $right, $bottom)';
}

/// Fragmento marcado (resaltado o subrayado), con nota opcional.
///
/// Ancla:
/// - Texto fluido (Word, TXT, MD): [blockIndex] es el índice del bloque y
///   [start]/[end] desplazamientos en su texto plano.
/// - PDF: [blockIndex] es el número de página (desde 1), [start]/[end] son
///   índices en el texto de la página y [rects] las líneas a pintar.
@immutable
class Highlight {
  const new({
    required this.id,
    required this.documentId,
    required this.blockIndex,
    required this.start,
    required this.end,
    required this.colorIndex,
    required this.text,
    required this.createdAt,
    this.style = HighlightStyle.highlight,
    this.note,
    this.rects = const [],
  });

  factory fromJson(Map<String, Object?> json) => Highlight(
    id: json['id']! as String,
    documentId: json['documentId']! as String,
    blockIndex: (json['blockIndex']! as num).toInt(),
    start: (json['start']! as num).toInt(),
    end: (json['end']! as num).toInt(),
    colorIndex: (json['colorIndex']! as num).toInt(),
    text: json['text']! as String,
    createdAt: DateTime.parse(json['createdAt']! as String),
    style: switch (json['style']) {
      'underline' => HighlightStyle.underline,
      _ => HighlightStyle.highlight,
    },
    note: json['note'] as String?,
    rects: [
      for (final r in (json['rects'] as List<Object?>?) ?? const <Object?>[])
        HighlightRect.fromJson(r! as List<Object?>),
    ],
  );

  final String id;
  final String documentId;
  final int blockIndex;
  final int start;
  final int end;
  final int colorIndex;
  final String text;
  final DateTime createdAt;
  final HighlightStyle style;

  /// Nota escrita por el usuario (o `null`).
  final String? note;

  /// Líneas en coordenadas PDF; vacío en documentos de texto.
  final List<HighlightRect> rects;

  bool get isPdf => rects.isNotEmpty;
  bool get hasNote => note != null && note!.trim().isNotEmpty;

  bool overlaps(int otherStart, int otherEnd) =>
      start < otherEnd && otherStart < end;

  Highlight copyWith({
    int? colorIndex,
    HighlightStyle? style,
    String? note,
    bool clearNote = false,
  }) => Highlight(
    id: id,
    documentId: documentId,
    blockIndex: blockIndex,
    start: start,
    end: end,
    colorIndex: colorIndex ?? this.colorIndex,
    text: text,
    createdAt: createdAt,
    style: style ?? this.style,
    note: clearNote ? null : (note ?? this.note),
    rects: rects,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'documentId': documentId,
    'blockIndex': blockIndex,
    'start': start,
    'end': end,
    'colorIndex': colorIndex,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'style': style.name,
    if (note != null) 'note': note,
    if (rects.isNotEmpty) 'rects': [for (final r in rects) r.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is Highlight &&
      other.id == id &&
      other.colorIndex == colorIndex &&
      other.style == style &&
      other.note == note &&
      const ListEquality<HighlightRect>().equals(other.rects, rects);

  @override
  int get hashCode => Object.hash(id, colorIndex, style, note);
}

/// Datos de una marca nueva, antes de tener id.
@immutable
class HighlightDraft {
  const new({
    required this.blockIndex,
    required this.start,
    required this.end,
    required this.text,
    this.rects = const [],
  });

  final int blockIndex;
  final int start;
  final int end;
  final String text;
  final List<HighlightRect> rects;
}
