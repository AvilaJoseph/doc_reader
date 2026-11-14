import 'dart:io';
import 'dart:typed_data';

import 'package:doc_reader/core/errors/app_exception.dart';
import 'package:doc_reader/features/reader/formats/spreadsheet/xlsx_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseXlsx', () {
    late Uint8List bytes;

    setUpAll(() {
      bytes = File('test/fixtures/sample.xlsx').readAsBytesSync();
    });

    test('lee las hojas en orden con sus nombres', () {
      final workbook = parseXlsx(bytes);
      expect(workbook.sheets.map((s) => s.name), ['Ventas', 'Notas']);
    });

    test('resuelve textos, números, fechas, booleanos y fórmulas', () {
      final sheet = parseXlsx(bytes).sheets.first;
      expect(sheet.rowCount, 3);
      expect(sheet.columnCount, 6);
      expect(sheet.rows[0], [
        'Producto',
        'Cantidad',
        'Precio',
        'Fecha',
        'Activo',
        '',
      ]);
      expect(sheet.rows[1], [
        'Café',
        '3',
        '2.5',
        '15/03/2024',
        'VERDADERO',
        '7.5',
      ]);
      expect(sheet.rows[2], [
        'Té',
        '10',
        '0.1',
        '02/01/2024 14:30',
        'FALSO',
        '',
      ]);
    });

    test('rellena celdas vacías hasta la primera con contenido', () {
      final sheet = parseXlsx(bytes).sheets[1];
      expect(sheet.rows, [
        ['', ''],
        ['', ''],
        ['', 'Hola'],
      ]);
      expect(sheet.truncated, isFalse);
    });

    test('lanza DocumentParseException con datos inválidos', () {
      expect(
        () => parseXlsx(Uint8List.fromList([1, 2, 3, 4])),
        throwsA(isA<DocumentParseException>()),
      );
    });
  });

  group('formatNumber', () {
    test('quita decimales sobrantes y ruido de coma flotante', () {
      expect(formatNumber(3), '3');
      expect(formatNumber(2.5), '2.5');
      expect(formatNumber(0.1 + 0.2), '0.3');
      expect(formatNumber(-12.75), '-12.75');
    });
  });

  group('isDateFormatCode', () {
    test('detecta fechas y descarta números', () {
      expect(isDateFormatCode('dd/mm/yyyy'), isTrue);
      expect(isDateFormatCode(r'[$-409]h:mm AM/PM'), isTrue);
      expect(isDateFormatCode('#,##0.00'), isFalse);
      expect(isDateFormatCode('0.00" días"'), isFalse);
      expect(isDateFormatCode('[Red]0.00'), isFalse);
    });
  });
}
