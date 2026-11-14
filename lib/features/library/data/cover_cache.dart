import 'dart:io';
import 'dart:ui' as ui;

import 'package:doc_reader/features/library/domain/document_source.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

/// Miniaturas de la primera página de los PDF, generadas una sola vez.
///
/// Abrir un PDF con PDFium para pintar su portada cada vez que se ve la
/// biblioteca es caro; aquí se renderiza una vez a un PNG pequeño en la
/// caché de la app y las siguientes veces solo se lee el archivo.
class CoverCache {
  new({Future<Directory> Function()? baseDirectory})
    : _baseDirectory = baseDirectory ?? getApplicationCacheDirectory;

  /// Ancho de la miniatura en píxeles: suficiente para una tarjeta.
  static const int width = 360;

  final Future<Directory> Function() _baseDirectory;

  Future<File> _fileFor(String id) async {
    final base = await _baseDirectory();
    final dir = Directory(p.join(base.path, 'covers'));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return File(p.join(dir.path, '$id.png'));
  }

  /// PNG de la primera página de [source], o null si no se puede pintar.
  Future<Uint8List?> pdfCover(String id, DocumentSource source) async {
    // En web (solo capturas) no hay sistema de archivos: no se cachea.
    final file = kIsWeb ? null : await _fileFor(id);
    if (file != null && file.existsSync()) return await file.readAsBytes();

    final png = await _render(source);
    if (png != null && file != null) await file.writeAsBytes(png);
    return png;
  }

  /// Borra la miniatura de un documento eliminado.
  Future<void> remove(String id) async {
    if (kIsWeb) return;
    final file = await _fileFor(id);
    if (file.existsSync()) await file.delete();
  }

  Future<Uint8List?> _render(DocumentSource source) async {
    await pdfrxFlutterInitialize();
    final pdf = switch (source) {
      FileSource(:final path) => await PdfDocument.openFile(path),
      AssetSource(:final assetPath) => await PdfDocument.openAsset(assetPath),
    };
    try {
      if (pdf.pages.isEmpty) return null;
      final page = pdf.pages.first;
      final height = (width * page.height / page.width).round();
      final image = await page.renderForDisplay(
        width: width,
        height: height,
        fullWidth: width.toDouble(),
        fullHeight: height.toDouble(),
        backgroundColor: 0xFFFFFFFF,
      );
      if (image == null) return null;
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data?.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } finally {
      await pdf.dispose();
    }
  }
}
