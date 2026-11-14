import 'package:doc_reader/core/errors/app_exception.dart';
import 'package:doc_reader/features/library/application/library_controller.dart';
import 'package:doc_reader/features/library/application/library_providers.dart';
import 'package:doc_reader/features/library/domain/document_kind.dart';
import 'package:doc_reader/features/library/domain/library_document.dart';
import 'package:doc_reader/features/reader/formats/flow/docx_parser.dart';
import 'package:doc_reader/features/reader/formats/flow/flow_document.dart';
import 'package:doc_reader/features/reader/formats/flow/rtf_parser.dart';
import 'package:doc_reader/features/reader/formats/flow/text_parser.dart';
import 'package:doc_reader/features/reader/formats/spreadsheet/csv_parser.dart';
import 'package:doc_reader/features/reader/formats/spreadsheet/workbook.dart';
import 'package:doc_reader/features/reader/formats/spreadsheet/xlsx_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Documento de la biblioteca por id (o `null` si se quitó).
final libraryDocumentProvider = Provider.family<LibraryDocument?, String>((
  ref,
  id,
) {
  final docs = ref.watch(libraryControllerProvider).value ?? const [];
  for (final doc in docs) {
    if (doc.id == id) return doc;
  }
  return null;
});

/// Bytes del documento. Solo depende de la fuente, no del progreso, para
/// no recargar el archivo cada vez que se guarda la posición.
final documentBytesProvider = FutureProvider.autoDispose
    .family<Uint8List, String>((ref, id) async {
      final source = ref.watch(
        libraryDocumentProvider(id).select((doc) => doc?.source),
      );
      if (source == null) throw DocumentNotFoundException(id);
      return await ref.read(documentFileStoreProvider).readBytes(source);
    });

/// Documento de texto fluido ya interpretado (Word, TXT, Markdown).
///
/// El parseo corre en un isolate aparte para no congelar la interfaz.
final flowDocumentProvider = FutureProvider.autoDispose
    .family<FlowDocument, String>((ref, id) async {
      final fileName = ref.watch(
        libraryDocumentProvider(id).select((doc) => doc?.fileName),
      );
      if (fileName == null) throw DocumentNotFoundException(id);
      final bytes = await ref.watch(documentBytesProvider(id).future);
      final ext = DocumentKind.extensionOf(fileName);
      return await switch (ext) {
        'docx' => compute(parseDocx, bytes),
        'rtf' => compute(parseRtf, bytes),
        'md' || 'markdown' => compute(parseMarkdown, bytes),
        _ => compute(parsePlainText, bytes),
      };
    });

/// Libro de hojas de cálculo ya interpretado (XLSX, CSV, TSV).
final workbookProvider = FutureProvider.autoDispose.family<Workbook, String>((
  ref,
  id,
) async {
  final fileName = ref.watch(
    libraryDocumentProvider(id).select((doc) => doc?.fileName),
  );
  if (fileName == null) throw DocumentNotFoundException(id);
  final bytes = await ref.watch(documentBytesProvider(id).future);
  return await switch (DocumentKind.extensionOf(fileName)) {
    'xlsx' => compute(parseXlsx, bytes),
    'csv' || 'tsv' => compute(_parseCsv, bytes),
    final ext => throw UnsupportedFormatException(ext),
  };
});

Workbook _parseCsv(Uint8List bytes) => parseCsv(bytes);
