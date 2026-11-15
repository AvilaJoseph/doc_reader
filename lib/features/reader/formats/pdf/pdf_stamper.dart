import 'package:flutter/foundation.dart';

export 'pdf_stamper_native.dart'
    if (dart.library.js_interop) 'pdf_stamper_web.dart';

/// Imagen (firma o texto) colocada sobre una página de un PDF.
///
/// La posición va en fracciones de la página tal como se ve (0 a 1, desde
/// arriba a la izquierda), así no depende del zoom ni del giro.
@immutable
class PdfStamp {
  const new({
    required this.pageIndex,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.rgba,
    required this.pixelWidth,
    required this.pixelHeight,
  });

  final int pageIndex;
  final double left;
  final double top;
  final double width;
  final double height;

  /// Píxeles RGBA sin premultiplicar, fila a fila.
  final Uint8List rgba;
  final int pixelWidth;
  final int pixelHeight;
}
