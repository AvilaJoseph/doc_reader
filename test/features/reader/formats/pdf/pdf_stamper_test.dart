import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:doc_reader/core/errors/app_exception.dart';
import 'package:doc_reader/features/reader/formats/pdf/pdf_stamper.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfium_dart/pdfium_dart.dart';

/// PDFium que deja el build nativo de los tests (si existe).
PDFium? _loadPdfium() {
  final file = File('build/native_assets/linux/libpdfium.so');
  if (!file.existsSync()) return null;
  return getPdfium(modulePath: file.absolute.path)..FPDF_InitLibrary();
}

PdfStamp _stamp({int page = 0}) => PdfStamp(
  pageIndex: page,
  left: 0.6,
  top: 0.8,
  width: 0.3,
  height: 0.1,
  rgba: Uint8List.fromList([
    for (var i = 0; i < 4 * 2; i++) ...[20, 40, 200, 255],
  ]),
  pixelWidth: 4,
  pixelHeight: 2,
);

void main() {
  final pdfium = _loadPdfium();
  final skip = pdfium == null ? 'Sin PDFium nativo en este equipo' : null;
  final pdf = File('assets/samples/guia.pdf').readAsBytesSync();

  int countObjects(Uint8List bytes, int pageIndex) => using((arena) {
    final p = pdfium!;
    final data = arena<Uint8>(bytes.length)
      ..asTypedList(bytes.length).setAll(0, bytes);
    final doc = p.FPDF_LoadMemDocument64(data.cast(), bytes.length, nullptr);
    final page = p.FPDF_LoadPage(doc, pageIndex);
    final count = p.FPDFPage_CountObjects(page);
    p
      ..FPDF_ClosePage(page)
      ..FPDF_CloseDocument(doc);
    return count;
  });

  test('incrusta la firma como imagen en la página elegida', () {
    final before = countObjects(pdf, 1);
    final out = stampPdfWith(pdfium!, pdf, [_stamp(page: 1)]);
    expect(String.fromCharCodes(out.take(5)), '%PDF-');
    expect(countObjects(out, 1), before + 1);
    expect(countObjects(out, 0), countObjects(pdf, 0));
  }, skip: skip);

  test('ignora páginas que no existen', () {
    final out = stampPdfWith(pdfium!, pdf, [_stamp(page: 99)]);
    expect(countObjects(out, 0), countObjects(pdf, 0));
  }, skip: skip);

  test('rechaza bytes que no son PDF', () {
    expect(
      () => stampPdfWith(pdfium!, Uint8List.fromList([1, 2, 3]), [_stamp()]),
      throwsA(isA<DocumentParseException>()),
    );
  }, skip: skip);
}
