import 'package:flutter/foundation.dart';

/// Modelo intermedio para hojas de cálculo (XLSX, CSV).
@immutable
class Workbook {
  const new({required this.sheets});

  final List<Sheet> sheets;
}

/// Una hoja: matriz densa de celdas ya formateadas como texto.
@immutable
class Sheet {
  const new({required this.name, required this.rows, this.truncated = false});

  final String name;

  /// Filas de celdas. Todas las filas tienen [columnCount] celdas.
  final List<List<String>> rows;

  /// `true` si el archivo superaba los límites de filas/columnas y se cortó.
  final bool truncated;

  int get rowCount => rows.length;
  int get columnCount => rows.isEmpty ? 0 : rows.first.length;
  bool get isEmpty => rows.isEmpty;
}

/// Límites para no bloquear la app con archivos gigantes.
abstract final class SheetLimits {
  static const int maxRows = 10000;
  static const int maxColumns = 256;
}

/// Convierte un índice de columna (0) en letras ("A"), como en Excel.
String columnLabel(int index) {
  var n = index + 1;
  final buffer = StringBuffer();
  while (n > 0) {
    final rem = (n - 1) % 26;
    buffer.write(String.fromCharCode(65 + rem));
    n = (n - 1) ~/ 26;
  }
  return buffer.toString().split('').reversed.join();
}
