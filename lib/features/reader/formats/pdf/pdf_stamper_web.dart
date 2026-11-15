import 'dart:typed_data';

import 'package:doc_reader/features/reader/formats/pdf/pdf_stamper.dart';

/// En web (solo capturas) no se puede escribir el PDF.
Future<Uint8List> stampPdf(Uint8List pdf, List<PdfStamp> stamps) =>
    throw UnsupportedError('Firmar PDF no está disponible en web');
