import 'package:doc_reader/features/library/domain/document_kind.dart';
import 'package:doc_reader/features/library/domain/document_source.dart';
import 'package:flutter/foundation.dart';

/// Un documento guardado en la biblioteca.
@immutable
class LibraryDocument {
  const new({
    required this.id,
    required this.title,
    required this.fileName,
    required this.kind,
    required this.source,
    required this.sizeBytes,
    required this.addedAt,
    this.lastOpenedAt,
    this.progress = 0,
    this.position = 0,
  });

  factory fromJson(Map<String, Object?> json) {
    return LibraryDocument(
      id: json['id']! as String,
      title: json['title']! as String,
      fileName: json['fileName']! as String,
      kind: DocumentKind.values.byName(json['kind']! as String),
      source: DocumentSource.decode(json['source']! as String),
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      addedAt: DateTime.parse(json['addedAt']! as String),
      lastOpenedAt: switch (json['lastOpenedAt']) {
        final String value => DateTime.parse(value),
        _ => null,
      },
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      position: (json['position'] as num?)?.toDouble() ?? 0,
    );
  }

  final String id;
  final String title;
  final String fileName;
  final DocumentKind kind;
  final DocumentSource source;
  final int sizeBytes;
  final DateTime addedAt;
  final DateTime? lastOpenedAt;

  /// Avance de lectura entre 0 y 1.
  final double progress;

  /// Posición para retomar la lectura. Su significado depende del visor:
  /// número de página (PDF), fracción de scroll (texto), hoja (Excel).
  final double position;

  String get extension => DocumentKind.extensionOf(fileName);

  bool get isStarted => progress > 0.005;
  bool get isFinished => progress >= 0.98;

  /// Fecha usada para ordenar: última apertura o, si no, alta.
  DateTime get recency => lastOpenedAt ?? addedAt;

  LibraryDocument copyWith({
    String? title,
    DateTime? lastOpenedAt,
    double? progress,
    double? position,
  }) {
    return LibraryDocument(
      id: id,
      title: title ?? this.title,
      fileName: fileName,
      kind: kind,
      source: source,
      sizeBytes: sizeBytes,
      addedAt: addedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      progress: progress ?? this.progress,
      position: position ?? this.position,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'fileName': fileName,
    'kind': kind.name,
    'source': source.encode(),
    'sizeBytes': sizeBytes,
    'addedAt': addedAt.toIso8601String(),
    'lastOpenedAt': lastOpenedAt?.toIso8601String(),
    'progress': progress,
    'position': position,
  };

  @override
  bool operator ==(Object other) =>
      other is LibraryDocument &&
      other.id == id &&
      other.title == title &&
      other.lastOpenedAt == lastOpenedAt &&
      other.progress == progress &&
      other.position == position;

  @override
  int get hashCode => Object.hash(id, title, lastOpenedAt, progress, position);
}
