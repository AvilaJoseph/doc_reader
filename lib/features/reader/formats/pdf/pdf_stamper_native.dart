import 'dart:ffi';
import 'dart:typed_data';

import 'package:doc_reader/core/errors/app_exception.dart';
import 'package:doc_reader/features/reader/formats/pdf/pdf_stamper.dart';
import 'package:ffi/ffi.dart';
import 'package:pdfium_dart/pdfium_dart.dart';
import 'package:pdfrx/pdfrx.dart';

/// Devuelve una copia de [pdf] con [stamps] incrustadas como imágenes.
///
/// Corre en el hilo de PDFium de pdfrx, para no pisarse con el visor.
Future<Uint8List> stampPdf(Uint8List pdf, List<PdfStamp> stamps) async {
  await pdfrxFlutterInitialize();
  await PdfrxEntryFunctions.instance.init();
  return await PdfrxEntryFunctions.instance.compute(_stampTask, (
    pdf: pdf,
    stamps: stamps,
    module: Pdfrx.pdfiumModulePath,
  ));
}

Uint8List _stampTask(
  ({Uint8List pdf, List<PdfStamp> stamps, String? module}) message,
) => stampPdfWith(
  getPdfium(modulePath: message.module),
  message.pdf,
  message.stamps,
);

/// Versión síncrona de [stampPdf]; PDFium ya debe estar inicializado.
Uint8List stampPdfWith(PDFium pdfium, Uint8List pdf, List<PdfStamp> stamps) {
  return using((arena) {
    final data = arena<Uint8>(pdf.length)
      ..asTypedList(pdf.length).setAll(0, pdf);
    final doc = pdfium.FPDF_LoadMemDocument64(data.cast(), pdf.length, nullptr);
    if (doc == nullptr) {
      throw const DocumentParseException('PDF ilegible o protegido');
    }
    try {
      final pageCount = pdfium.FPDF_GetPageCount(doc);
      final byPage = <int, List<PdfStamp>>{};
      for (final stamp in stamps) {
        if (stamp.pageIndex < 0 || stamp.pageIndex >= pageCount) continue;
        (byPage[stamp.pageIndex] ??= []).add(stamp);
      }
      for (final MapEntry(key: index, value: pageStamps) in byPage.entries) {
        final page = pdfium.FPDF_LoadPage(doc, index);
        if (page == nullptr) continue;
        try {
          for (final stamp in pageStamps) {
            _insert(pdfium, arena, doc, page, stamp);
          }
          pdfium.FPDFPage_GenerateContent(page);
        } finally {
          pdfium.FPDF_ClosePage(page);
        }
      }
      return _save(pdfium, arena, doc);
    } finally {
      pdfium.FPDF_CloseDocument(doc);
    }
  });
}

void _insert(
  PDFium pdfium,
  Arena arena,
  FPDF_DOCUMENT doc,
  FPDF_PAGE page,
  PdfStamp stamp,
) {
  // Un "dispositivo" virtual del tamaño de la página visible: PDFium
  // traduce sus esquinas a coordenadas PDF teniendo en cuenta el giro y el
  // recorte de la página.
  const size = 10000;
  final w = pdfium.FPDF_GetPageWidthF(page);
  final h = pdfium.FPDF_GetPageHeightF(page);
  final sizeY = (size * h / w).round();
  final px = arena<Double>();
  final py = arena<Double>();
  (double, double) toPage(double fx, double fy) {
    pdfium.FPDF_DeviceToPage(
      page,
      0,
      0,
      size,
      sizeY,
      0,
      (fx * size).round(),
      (fy * sizeY).round(),
      px,
      py,
    );
    return (px.value, py.value);
  }

  final right = stamp.left + stamp.width;
  final bottom = stamp.top + stamp.height;
  final (blx, bly) = toPage(stamp.left, bottom);
  final (brx, bry) = toPage(right, bottom);
  final (tlx, tly) = toPage(stamp.left, stamp.top);

  // PDFium espera BGRA.
  final count = stamp.pixelWidth * stamp.pixelHeight * 4;
  final pixels = arena<Uint8>(count);
  final bgra = pixels.asTypedList(count)..setAll(0, stamp.rgba);
  for (var i = 0; i < count; i += 4) {
    final r = bgra[i];
    bgra[i] = bgra[i + 2];
    bgra[i + 2] = r;
  }
  final bitmap = pdfium.FPDFBitmap_CreateEx(
    stamp.pixelWidth,
    stamp.pixelHeight,
    FPDFBitmap_BGRA,
    pixels.cast(),
    stamp.pixelWidth * 4,
  );
  final image = pdfium.FPDFPageObj_NewImageObj(doc);
  try {
    pdfium
      ..FPDFImageObj_SetBitmap(nullptr, 0, image, bitmap)
      ..FPDFImageObj_SetMatrix(
        image,
        brx - blx,
        bry - bly,
        tlx - blx,
        tly - bly,
        blx,
        bly,
      )
      ..FPDFPage_InsertObject(page, image);
  } finally {
    pdfium.FPDFBitmap_Destroy(bitmap);
  }
}

Uint8List _save(PDFium pdfium, Arena arena, FPDF_DOCUMENT doc) {
  final out = BytesBuilder(copy: false);
  int write(Pointer<FPDF_FILEWRITE> self, Pointer<Void> data, int size) {
    out.add(Uint8List.fromList(data.cast<Uint8>().asTypedList(size)));
    return 1;
  }

  final callable =
      NativeCallable<
        Int Function(Pointer<FPDF_FILEWRITE>, Pointer<Void>, UnsignedLong)
      >.isolateLocal(write, exceptionalReturn: 0);
  try {
    final fw = arena<FPDF_FILEWRITE>();
    fw.ref
      ..version = 1
      ..WriteBlock = callable.nativeFunction;
    if (pdfium.FPDF_SaveAsCopy(doc, fw, FPDF_NO_INCREMENTAL) == 0) {
      throw const DocumentParseException('No se pudo guardar el PDF');
    }
    return out.takeBytes();
  } finally {
    callable.close();
  }
}
