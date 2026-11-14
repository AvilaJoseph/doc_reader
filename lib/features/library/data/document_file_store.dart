import 'dart:io';

import 'package:doc_reader/core/errors/app_exception.dart';
import 'package:doc_reader/features/library/domain/document_source.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Archivo entrante que se quiere añadir a la biblioteca, venga de donde
/// venga (selector de archivos, "Abrir con…", compartir…).
class ImportCandidate {
  const new({required this.name, required this.openRead, this.sizeBytes});

  final String name;
  final Stream<List<int>> Function() openRead;
  final int? sizeBytes;
}

/// Lee y guarda los bytes de los documentos.
///
/// Los archivos importados se copian a la carpeta privada de la app para
/// que sigan disponibles aunque el original se mueva o se borre.
class DocumentFileStore {
  new({Future<Directory> Function()? baseDirectory, AssetBundle? bundle})
    : _baseDirectory = baseDirectory ?? getApplicationDocumentsDirectory,
      _bundle = bundle ?? rootBundle;

  final Future<Directory> Function() _baseDirectory;
  final AssetBundle _bundle;

  Future<Directory> _libraryDir() async {
    final base = await _baseDirectory();
    final dir = Directory(p.join(base.path, 'library'));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// Copia [candidate] a la carpeta de la app con el nombre `<id>.<ext>`.
  Future<({FileSource source, int sizeBytes})> store(
    ImportCandidate candidate, {
    required String id,
  }) async {
    final dir = await _libraryDir();
    final ext = p.extension(candidate.name).toLowerCase();
    final file = File(p.join(dir.path, '$id$ext'));
    final sink = file.openWrite();
    try {
      await sink.addStream(candidate.openRead());
    } finally {
      await sink.close();
    }
    return (source: FileSource(file.path), sizeBytes: await file.length());
  }

  Future<Uint8List> readBytes(DocumentSource source) async {
    switch (source) {
      case FileSource(:final path):
        final file = File(path);
        if (!file.existsSync()) throw DocumentNotFoundException(path);
        return await file.readAsBytes();
      case AssetSource(:final assetPath):
        final data = await _bundle.load(assetPath);
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    }
  }

  /// Borra la copia local. Los ejemplos empaquetados no se tocan.
  Future<void> delete(DocumentSource source) async {
    if (source case FileSource(:final path)) {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    }
  }
}
