import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:doc_reader/core/errors/app_exception.dart';
import 'package:doc_reader/features/reader/formats/spreadsheet/workbook.dart';
import 'package:xml/xml.dart';

/// Convierte un archivo `.xlsx` en un [Workbook].
///
/// Es una función pura y de nivel superior para poder usarse con `compute()`.
/// Lanza [DocumentParseException] si el archivo no es un XLSX válido.
Workbook parseXlsx(Uint8List bytes) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } on Object catch (e) {
    throw DocumentParseException('No es un archivo ZIP válido: $e');
  }
  try {
    return _XlsxReader(archive).read();
  } on DocumentParseException {
    rethrow;
  } on Object catch (e) {
    throw DocumentParseException('XLSX inválido: $e');
  }
}

class _SheetRef {
  const new(this.name, this.path);

  final String name;
  final String path;
}

class _XlsxReader {
  new(this.archive);

  final Archive archive;
  late final List<String> _sharedStrings = _readSharedStrings();
  late final _Styles _styles = _readStyles();

  Workbook read() {
    final workbookXml = _xml('xl/workbook.xml');
    if (workbookXml == null) {
      throw const DocumentParseException('Falta xl/workbook.xml');
    }
    final rels = _readRels('xl/_rels/workbook.xml.rels');
    final refs = <_SheetRef>[];
    var index = 0;
    for (final sheet in workbookXml.descendantElements.where(
      (e) => e.localName == 'sheet',
    )) {
      index++;
      if (sheet.getAttribute('state') == 'veryHidden') continue;
      final name = sheet.getAttribute('name') ?? 'Hoja $index';
      final relId = _attr(sheet, 'id');
      final target = relId == null ? null : rels[relId];
      final path = target == null
          ? 'xl/worksheets/sheet$index.xml'
          : _resolveTarget('xl', target);
      refs.add(_SheetRef(name, path));
    }
    if (refs.isEmpty) {
      throw const DocumentParseException('El libro no tiene hojas');
    }
    return Workbook(sheets: [for (final ref in refs) _readSheet(ref)]);
  }

  // --- Lectura de partes -------------------------------------------------

  XmlDocument? _xml(String path) {
    final file = archive.findFile(path);
    if (file == null) return null;
    return XmlDocument.parse(utf8.decode(file.content, allowMalformed: true));
  }

  Map<String, String> _readRels(String path) {
    final doc = _xml(path);
    if (doc == null) return const {};
    return {
      for (final rel in doc.descendantElements.where(
        (e) => e.localName == 'Relationship',
      ))
        if (rel.getAttribute('Id') != null &&
            rel.getAttribute('Target') != null)
          rel.getAttribute('Id')!: rel.getAttribute('Target')!,
    };
  }

  List<String> _readSharedStrings() {
    final doc = _xml('xl/sharedStrings.xml');
    if (doc == null) return const [];
    return [
      for (final si in doc.rootElement.childElements.where(
        (e) => e.localName == 'si',
      ))
        _richText(si),
    ];
  }

  _Styles _readStyles() {
    final doc = _xml('xl/styles.xml');
    if (doc == null) return const _Styles([], {});
    final custom = <int, String>{};
    for (final fmt in doc.descendantElements.where(
      (e) => e.localName == 'numFmt',
    )) {
      final id = int.tryParse(fmt.getAttribute('numFmtId') ?? '');
      final code = fmt.getAttribute('formatCode');
      if (id != null && code != null) custom[id] = code;
    }
    final xfIds = <int>[];
    final cellXfs = doc.descendantElements
        .where((e) => e.localName == 'cellXfs')
        .firstOrNull;
    if (cellXfs != null) {
      for (final xf in cellXfs.childElements.where(
        (e) => e.localName == 'xf',
      )) {
        xfIds.add(int.tryParse(xf.getAttribute('numFmtId') ?? '') ?? 0);
      }
    }
    return _Styles(xfIds, custom);
  }

  // --- Hojas ------------------------------------------------------------

  Sheet _readSheet(_SheetRef ref) {
    final doc = _xml(ref.path);
    if (doc == null) return Sheet(name: ref.name, rows: const []);

    final cells = <int, Map<int, String>>{};
    var truncated = false;
    var maxRow = -1;
    var maxCol = -1;
    var nextRow = 0;

    final sheetData = doc.descendantElements
        .where((e) => e.localName == 'sheetData')
        .firstOrNull;
    if (sheetData == null) return Sheet(name: ref.name, rows: const []);

    for (final row in sheetData.childElements.where(
      (e) => e.localName == 'row',
    )) {
      final rAttr = int.tryParse(row.getAttribute('r') ?? '');
      final rowIndex = rAttr != null ? rAttr - 1 : nextRow;
      nextRow = rowIndex + 1;
      if (rowIndex >= SheetLimits.maxRows) {
        truncated = true;
        break;
      }
      var nextCol = 0;
      for (final c in row.childElements.where((e) => e.localName == 'c')) {
        final ref = c.getAttribute('r');
        final colIndex = ref != null ? _columnIndex(ref) : nextCol;
        nextCol = colIndex + 1;
        if (colIndex >= SheetLimits.maxColumns) {
          truncated = true;
          continue;
        }
        final value = _cellValue(c);
        if (value.isEmpty) continue;
        (cells[rowIndex] ??= {})[colIndex] = value;
        if (rowIndex > maxRow) maxRow = rowIndex;
        if (colIndex > maxCol) maxCol = colIndex;
      }
    }

    final rows = <List<String>>[
      for (var r = 0; r <= maxRow; r++)
        [for (var c = 0; c <= maxCol; c++) cells[r]?[c] ?? ''],
    ];
    return Sheet(name: ref.name, rows: rows, truncated: truncated);
  }

  String _cellValue(XmlElement c) {
    final type = c.getAttribute('t') ?? 'n';
    if (type == 'inlineStr') {
      final inline = c.childElements
          .where((e) => e.localName == 'is')
          .firstOrNull;
      return inline == null ? '' : _richText(inline);
    }
    final v = c.childElements.where((e) => e.localName == 'v').firstOrNull;
    final raw = v?.innerText ?? '';
    if (raw.isEmpty) return '';
    switch (type) {
      case 's':
        final i = int.tryParse(raw);
        return i != null && i >= 0 && i < _sharedStrings.length
            ? _sharedStrings[i]
            : '';
      case 'b':
        return raw == '1' ? 'VERDADERO' : 'FALSO';
      case 'str':
      case 'e':
        return raw;
      default:
        final number = double.tryParse(raw);
        if (number == null) return raw;
        final style = int.tryParse(c.getAttribute('s') ?? '') ?? 0;
        final fmtId = _styles.numFmtIdFor(style);
        if (_styles.isDateFormat(fmtId)) return formatExcelDate(number);
        if (fmtId == 9 || fmtId == 10) {
          return '${formatNumber(number * 100)}%';
        }
        return formatNumber(number);
    }
  }
}

class _Styles {
  const new(this.xfNumFmtIds, this.customFormats);

  final List<int> xfNumFmtIds;
  final Map<int, String> customFormats;

  int numFmtIdFor(int styleIndex) =>
      styleIndex >= 0 && styleIndex < xfNumFmtIds.length
      ? xfNumFmtIds[styleIndex]
      : 0;

  bool isDateFormat(int id) {
    if ((id >= 14 && id <= 22) || (id >= 45 && id <= 47)) return true;
    final code = customFormats[id];
    return code != null && isDateFormatCode(code);
  }
}

// --- Utilidades públicas (testeables) -------------------------------------

/// `true` si un código de formato de Excel representa fecha u hora.
bool isDateFormatCode(String code) {
  // Quita textos entre comillas, corchetes ([Red], [$-409]) y escapes.
  final cleaned = code
      .replaceAll(RegExp('"[^"]*"'), '')
      .replaceAll(RegExp(r'\[[^\]]*\]'), '')
      .replaceAll(RegExp(r'\\.'), '')
      .toLowerCase();
  // Solo la primera sección (formato de positivos).
  final section = cleaned.split(';').first;
  return RegExp('[dmyhs]').hasMatch(section) &&
      !RegExp(r'^[#0.,%\s]*$').hasMatch(section);
}

/// Convierte un número de serie de Excel en "dd/MM/yyyy" o "dd/MM/yyyy HH:mm".
String formatExcelDate(double serial) {
  // Época de Excel (sistema 1900, con el falso 29/02/1900).
  final base = DateTime.utc(1899, 12, 30);
  final ms = (serial * Duration.millisecondsPerDay).round();
  final date = base.add(Duration(milliseconds: ms));
  String two(int n) => n.toString().padLeft(2, '0');
  final day = '${two(date.day)}/${two(date.month)}/${date.year}';
  final hasTime = serial - serial.floorToDouble() > 1e-9;
  if (serial < 1) {
    return '${two(date.hour)}:${two(date.minute)}';
  }
  return hasTime ? '$day ${two(date.hour)}:${two(date.minute)}' : day;
}

/// Formatea un número sin ".0" final ni ruido de coma flotante.
String formatNumber(double value) {
  if (value.isNaN || value.isInfinite) return value.toString();
  if (value == value.truncateToDouble() && value.abs() < 1e15) {
    return value.toInt().toString();
  }
  var text = double.parse(value.toStringAsPrecision(12)).toString();
  if (text.contains('e')) return text;
  if (text.contains('.')) {
    text = text
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
  return text;
}

// --- Utilidades internas ----------------------------------------------------

String? _attr(XmlElement element, String localName) {
  for (final attribute in element.attributes) {
    if (attribute.name.local == localName) return attribute.value;
  }
  return null;
}

String _richText(XmlElement element) {
  // Texto de <t> directos o dentro de <r>, ignorando la fonética (<rPh>).
  final buffer = StringBuffer();
  void visit(XmlElement e) {
    for (final child in e.childElements) {
      if (child.localName == 't') {
        buffer.write(child.innerText);
      } else if (child.localName == 'r') {
        visit(child);
      }
    }
  }

  visit(element);
  return buffer.toString();
}

String _resolveTarget(String baseDir, String target) {
  if (target.startsWith('/')) return target.substring(1);
  final parts = [...baseDir.split('/')];
  for (final segment in target.split('/')) {
    if (segment == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else if (segment.isNotEmpty && segment != '.') {
      parts.add(segment);
    }
  }
  return parts.join('/');
}

int _columnIndex(String cellRef) {
  var col = 0;
  for (final unit in cellRef.toUpperCase().codeUnits) {
    if (unit < 65 || unit > 90) break;
    col = col * 26 + (unit - 64);
  }
  return col - 1;
}
