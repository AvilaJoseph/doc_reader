import 'package:flutter/foundation.dart';

/// Fragmento subrayado dentro de un documento de texto fluido.
///
/// Se ancla por índice de bloque y desplazamientos de carácter dentro del
/// texto plano del bloque, que son estables mientras el archivo no cambie.
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
  );

  final String id;
  final String documentId;
  final int blockIndex;
  final int start;
  final int end;
  final int colorIndex;
  final String text;
  final DateTime createdAt;

  bool overlaps(int otherStart, int otherEnd) =>
      start < otherEnd && otherStart < end;

  Map<String, Object?> toJson() => {
    'id': id,
    'documentId': documentId,
    'blockIndex': blockIndex,
    'start': start,
    'end': end,
    'colorIndex': colorIndex,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) => other is Highlight && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
