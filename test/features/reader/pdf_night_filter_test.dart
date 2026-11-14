import 'package:doc_reader/features/reader/formats/pdf/pdf_night_filter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Aplica la matriz a un color RGB (0–255).
List<double> _apply(List<double> m, List<double> rgb) => [
  for (var row = 0; row < 3; row++)
    m[row * 5] * rgb[0] +
        m[row * 5 + 1] * rgb[1] +
        m[row * 5 + 2] * rgb[2] +
        m[row * 5 + 4],
];

void main() {
  final m = pdfNightMatrix();

  test('el papel blanco pasa a gris muy oscuro', () {
    for (final v in _apply(m, [255, 255, 255])) {
      expect(v, closeTo(0x1E, 1));
    }
  });

  test('la tinta negra pasa a gris claro', () {
    for (final v in _apply(m, [0, 0, 0])) {
      expect(v, closeTo(0xDE, 1));
    }
  });

  test('conserva el tono dominante de un color', () {
    final red = _apply(m, [200, 30, 30]);
    expect(red[0], greaterThan(red[1]));
    expect(red[0], greaterThan(red[2]));
  });
}
