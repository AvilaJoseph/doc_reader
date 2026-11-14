import 'dart:async';
import 'dart:io';

import 'package:doc_reader/features/library/data/document_file_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Archivo recibido de otra app, ya copiado a la caché por la plataforma.
@immutable
class IncomingFile {
  const new({required this.path, required this.name, this.sizeBytes});

  factory fromMap(Map<Object?, Object?> map) => IncomingFile(
    path: map['path']! as String,
    name: map['name']! as String,
    sizeBytes: (map['size'] as num?)?.toInt(),
  );

  final String path;
  final String name;
  final int? sizeBytes;

  ImportCandidate toCandidate() => ImportCandidate(
    name: name,
    sizeBytes: sizeBytes,
    openRead: () => File(path).openRead(),
  );

  /// Borra la copia temporal una vez importada.
  Future<void> discard() async {
    final file = File(path);
    if (file.existsSync()) await file.delete();
  }
}

/// Puente con "Abrir con…" / "Compartir" de Android (ver MainActivity.kt).
class OpenWithChannel {
  new([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel('folio/open_with');

  final MethodChannel _channel;

  /// Archivo con el que se abrió la app, si lo hay (solo una vez).
  Future<IncomingFile?> takeInitialFile() async {
    if (kIsWeb) return null;
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'takeInitialFile',
      );
      return map == null ? null : IncomingFile.fromMap(map);
    } on MissingPluginException {
      return null; // Plataforma sin soporte (tests, escritorio).
    }
  }

  /// Archivos que llegan con la app ya abierta.
  Stream<IncomingFile> get files {
    final controller = StreamController<IncomingFile>();
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onFile' && call.arguments is Map) {
        controller.add(
          IncomingFile.fromMap(call.arguments as Map<Object?, Object?>),
        );
      }
    });
    controller.onCancel = () => _channel.setMethodCallHandler(null);
    return controller.stream;
  }
}
