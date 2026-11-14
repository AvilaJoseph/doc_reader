import 'dart:convert';
import 'dart:typed_data';

import 'package:doc_reader/features/reader/formats/spreadsheet/csv_parser.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _bytes(String text) => Uint8List.fromList(utf8.encode(text));

void main() {
  group('parseCsv', () {
    test('separa por comas y rellena filas cortas', () {
      final sheet = parseCsv(_bytes('a,b,c\n1,2\n')).sheets.single;
      expect(sheet.name, 'CSV');
      expect(sheet.rows, [
        ['a', 'b', 'c'],
        ['1', '2', ''],
      ]);
    });

    test('detecta punto y coma y quita el BOM', () {
      final sheet = parseCsv(
        _bytes('﻿nombre;precio\r\nCafé;2,50\r\n'),
        sheetName: 'precios',
      ).sheets.single;
      expect(sheet.name, 'precios');
      expect(sheet.rows, [
        ['nombre', 'precio'],
        ['Café', '2,50'],
      ]);
    });

    test('respeta comillas, comillas escapadas y saltos de línea', () {
      final sheet = parseCsv(
        _bytes('id,nota\n1,"Dijo ""hola"", y se fue"\n2,"línea 1\nlínea 2"'),
      ).sheets.single;
      expect(sheet.rows, [
        ['id', 'nota'],
        ['1', 'Dijo "hola", y se fue'],
        ['2', 'línea 1\nlínea 2'],
      ]);
    });

    test('detecta tabuladores', () {
      expect(detectDelimiter('a\tb\tc\n1\t2\t3'), '\t');
    });

    test('un archivo vacío produce una hoja vacía', () {
      expect(parseCsv(_bytes('')).sheets.single.isEmpty, isTrue);
    });
  });
}
