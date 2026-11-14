import 'dart:convert';
import 'dart:typed_data';

import 'package:doc_reader/features/reader/formats/spreadsheet/workbook.dart';

const _candidateDelimiters = [',', ';', '\t', '|'];

/// Convierte un CSV (o TSV) en un [Workbook] de una sola hoja.
///
/// Detecta el delimitador automáticamente y respeta comillas RFC 4180.
Workbook parseCsv(Uint8List bytes, {String sheetName = 'CSV'}) {
  var text = utf8.decode(bytes, allowMalformed: true);
  if (text.startsWith('﻿')) text = text.substring(1);
  final delimiter = detectDelimiter(text);

  final rows = <List<String>>[];
  var truncated = false;
  var maxCols = 0;

  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var i = 0;

  void endField() {
    if (row.length < SheetLimits.maxColumns) {
      row.add(field.toString());
    } else {
      truncated = true;
    }
    field.clear();
  }

  void endRow() {
    endField();
    if (row.length > maxCols) maxCols = row.length;
    rows.add(row);
    row = <String>[];
  }

  while (i < text.length) {
    final char = text[i];
    if (inQuotes) {
      if (char == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(char);
      }
    } else if (char == '"' && field.isEmpty) {
      inQuotes = true;
    } else if (char == delimiter) {
      endField();
    } else if (char == '\r' || char == '\n') {
      if (char == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      endRow();
      if (rows.length >= SheetLimits.maxRows) {
        truncated = i + 1 < text.length;
        break;
      }
    } else {
      field.write(char);
    }
    i++;
  }
  if (field.isNotEmpty || row.isNotEmpty) endRow();

  // Quita filas vacías al final.
  while (rows.isNotEmpty && rows.last.every((c) => c.isEmpty)) {
    rows.removeLast();
  }
  if (rows.isEmpty) {
    return Workbook(
      sheets: [Sheet(name: sheetName, rows: const [])],
    );
  }
  final padded = [
    for (final r in rows) [...r, ...List.filled(maxCols - r.length, '')],
  ];
  return Workbook(
    sheets: [Sheet(name: sheetName, rows: padded, truncated: truncated)],
  );
}

/// Elige el delimitador más consistente en las primeras líneas.
String detectDelimiter(String text) {
  final lines = const LineSplitter()
      .convert(text.length > 8192 ? text.substring(0, 8192) : text)
      .where((l) => l.trim().isNotEmpty)
      .take(10)
      .toList();
  if (lines.isEmpty) return ',';

  var best = ',';
  var bestScore = 0.0;
  for (final d in _candidateDelimiters) {
    final counts = lines.map((l) => _countOutsideQuotes(l, d)).toList();
    final first = counts.first;
    if (first == 0) continue;
    final consistent = counts.where((c) => c == first).length / counts.length;
    final score = first * consistent;
    if (score > bestScore) {
      bestScore = score;
      best = d;
    }
  }
  return best;
}

int _countOutsideQuotes(String line, String delimiter) {
  var count = 0;
  var inQuotes = false;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (c == '"') {
      inQuotes = !inQuotes;
    } else if (c == delimiter && !inQuotes) {
      count++;
    }
  }
  return count;
}
