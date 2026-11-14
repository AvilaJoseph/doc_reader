import 'dart:ui';

/// Matriz de color para leer PDF de noche: invierte el brillo pero conserva
/// el tono (inversión + giro de tono de 180°), así una foto roja sigue
/// siendo rojiza. El blanco del papel pasa a [paper] y el negro de la tinta
/// a [ink], en vez de usar negro y blanco puros, que cansan la vista.
List<double> pdfNightMatrix({int paper = 0x1E, int ink = 0xDE}) {
  // Giro de tono de 180° (coeficientes de luminancia estándar).
  const hue = [
    [-0.574, 1.430, 0.144],
    [0.426, 0.430, 0.144],
    [0.426, 1.430, -0.856],
  ];
  final k = (ink - paper) / 255;
  return [
    for (final row in hue) ...[for (final c in row) -k * c, 0, ink.toDouble()],
    0,
    0,
    0,
    1,
    0,
  ];
}

/// Filtro listo para `PdfViewerParams.pageImageColorFilter`.
final ColorFilter pdfNightFilter = ColorFilter.matrix(pdfNightMatrix());
