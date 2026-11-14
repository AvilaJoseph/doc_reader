import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:doc_reader/core/errors/app_exception.dart';
import 'package:doc_reader/features/reader/formats/flow/flow_document.dart';
import 'package:xml/xml.dart';

/// Espacio de nombres principal de WordprocessingML.
const _w = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';
const _r =
    'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
const _a = 'http://schemas.openxmlformats.org/drawingml/2006/main';
const _v = 'urn:schemas-microsoft-com:vml';

const _imageExtensions = {'png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'};

/// Convierte un archivo .docx en un [FlowDocument].
///
/// Es una función pura de nivel superior para poder usarla con `compute()`.
/// Lanza [DocumentParseException] si el archivo no es un .docx válido.
FlowDocument parseDocx(Uint8List bytes) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } on Object catch (e) {
    throw DocumentParseException('No es un archivo ZIP válido: $e');
  }

  final documentXml = _readXml(archive, 'word/document.xml');
  if (documentXml == null) {
    throw const DocumentParseException('Falta word/document.xml');
  }

  final styles = _readXml(archive, 'word/styles.xml');
  final parser = _DocxParser(
    archive: archive,
    relationships: _parseRelationships(
      _readXml(archive, 'word/_rels/document.xml.rels'),
    ),
    headingStyles: _parseHeadingStyles(styles),
    styleNumbering: _parseStyleNumbering(styles),
    numbering: _Numbering.parse(_readXml(archive, 'word/numbering.xml')),
  );

  final body = documentXml.rootElement.childElements.firstWhere(
    (e) => _isW(e, 'body'),
    orElse: () => throw const DocumentParseException('Falta w:body'),
  );
  parser.parseContainer(body);

  final title = parser.firstHeading ?? _coreTitle(archive);
  return FlowDocument(blocks: parser.blocks, title: title);
}

// ---------------------------------------------------------------------------
// Utilidades XML

bool _isW(XmlElement e, String local) =>
    e.name.local == local && (e.name.namespaceUri ?? _w) == _w;

XmlDocument? _readXml(Archive archive, String path) {
  final file = archive.findFile(path);
  if (file == null) return null;
  final data = file.readBytes();
  if (data == null) return null;
  try {
    return XmlDocument.parse(utf8.decode(data, allowMalformed: true));
  } on XmlException catch (e) {
    throw DocumentParseException('XML inválido en $path: $e');
  }
}

/// Lee un atributo `w:xxx` (con o sin prefijo resuelto).
String? _wAttr(XmlElement e, String local) =>
    e.getAttribute(local, namespaceUri: _w) ?? e.getAttribute('w:$local');

XmlElement? _wChild(XmlElement? e, String local) {
  if (e == null) return null;
  for (final c in e.childElements) {
    if (_isW(c, local)) return c;
  }
  return null;
}

/// Propiedad booleana (`<w:b/>`, `<w:b w:val="0"/>`…).
bool _toggle(XmlElement? props, String local) {
  final el = _wChild(props, local);
  if (el == null) return false;
  final val = _wAttr(el, 'val');
  return val == null || !(val == '0' || val == 'false' || val == 'off');
}

Map<String, String> _parseRelationships(XmlDocument? doc) {
  final result = <String, String>{};
  if (doc == null) return result;
  for (final rel in doc.rootElement.childElements) {
    final id = rel.getAttribute('Id');
    final target = rel.getAttribute('Target');
    if (id != null && target != null) result[id] = target;
  }
  return result;
}

/// styleId → nivel de encabezado.
Map<String, int> _parseHeadingStyles(XmlDocument? doc) {
  final result = <String, int>{};
  if (doc == null) return result;
  final headingRe = RegExp(r'^heading\s*(\d)$', caseSensitive: false);
  for (final style in doc.rootElement.childElements) {
    if (!_isW(style, 'style')) continue;
    final id = _wAttr(style, 'styleId');
    if (id == null) continue;
    final nameEl = _wChild(style, 'name');
    final name = (nameEl == null ? null : _wAttr(nameEl, 'val')) ?? '';
    final match = headingRe.firstMatch(name.trim());
    int? level;
    if (match != null) {
      level = int.parse(match.group(1)!);
    } else if (name.toLowerCase() == 'title') {
      level = 1;
    } else if (name.toLowerCase() == 'subtitle') {
      level = 2;
    } else {
      final outline = _wChild(_wChild(style, 'pPr'), 'outlineLvl');
      final val = outline == null
          ? null
          : int.tryParse(_wAttr(outline, 'val') ?? '');
      if (val != null && val < 9) level = val + 1;
    }
    if (level != null && level > 0) result[id] = level.clamp(1, 6);
  }
  return result;
}

/// styleId → `w:numPr` definido en el estilo (p. ej. "List Number").
Map<String, XmlElement> _parseStyleNumbering(XmlDocument? doc) {
  final result = <String, XmlElement>{};
  if (doc == null) return result;
  for (final style in doc.rootElement.childElements) {
    if (!_isW(style, 'style')) continue;
    final id = _wAttr(style, 'styleId');
    final numPr = _wChild(_wChild(style, 'pPr'), 'numPr');
    if (id != null && numPr != null) result[id] = numPr;
  }
  return result;
}

String? _coreTitle(Archive archive) {
  final doc = _readXml(archive, 'docProps/core.xml');
  if (doc == null) return null;
  for (final e in doc.rootElement.childElements) {
    if (e.name.local == 'title') {
      final t = e.innerText.trim();
      return t.isEmpty ? null : t;
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// Numeración (listas)

class _Level {
  const new(this.format, this.text, this.start);
  final String format;
  final String text;
  final int start;
}

class _Numbering {
  new(this._levels);

  factory parse(XmlDocument? doc) {
    final levels = <String, Map<int, _Level>>{};
    if (doc == null) return _Numbering(levels);
    final abstracts = <String, Map<int, _Level>>{};
    for (final e in doc.rootElement.childElements) {
      if (!_isW(e, 'abstractNum')) continue;
      final id = _wAttr(e, 'abstractNumId');
      if (id == null) continue;
      final map = <int, _Level>{};
      for (final lvl in e.childElements.where((c) => _isW(c, 'lvl'))) {
        final ilvl = int.tryParse(_wAttr(lvl, 'ilvl') ?? '') ?? 0;
        final fmtEl = _wChild(lvl, 'numFmt');
        final textEl = _wChild(lvl, 'lvlText');
        final startEl = _wChild(lvl, 'start');
        map[ilvl] = _Level(
          (fmtEl == null ? null : _wAttr(fmtEl, 'val')) ?? 'decimal',
          (textEl == null ? null : _wAttr(textEl, 'val')) ?? '',
          int.tryParse(
                (startEl == null ? null : _wAttr(startEl, 'val')) ?? '',
              ) ??
              1,
        );
      }
      abstracts[id] = map;
    }
    for (final e in doc.rootElement.childElements) {
      if (!_isW(e, 'num')) continue;
      final numId = _wAttr(e, 'numId');
      final absEl = _wChild(e, 'abstractNumId');
      final absId = absEl == null ? null : _wAttr(absEl, 'val');
      if (numId != null && absId != null && abstracts[absId] != null) {
        levels[numId] = abstracts[absId]!;
      }
    }
    return _Numbering(levels);
  }

  final Map<String, Map<int, _Level>> _levels;
  final Map<String, List<int>> _counters = {};

  /// Devuelve el marcador ya resuelto y avanza los contadores.
  String marker(String numId, int ilvl) {
    final defs = _levels[numId];
    final level = defs?[ilvl];
    if (level == null) return '•';
    final counters = _counters.putIfAbsent(numId, () => List.filled(9, 0));
    final i = ilvl.clamp(0, 8);
    counters[i] = counters[i] == 0 ? level.start : counters[i] + 1;
    for (var j = i + 1; j < counters.length; j++) {
      counters[j] = 0;
    }
    if (level.format == 'bullet' || level.format == 'none') {
      return level.format == 'none' ? '' : '•';
    }
    var text = level.text.isEmpty ? '%${i + 1}.' : level.text;
    for (var k = 0; k <= i; k++) {
      final fmt = defs![k]?.format ?? 'decimal';
      final value = counters[k] == 0 ? (defs[k]?.start ?? 1) : counters[k];
      text = text.replaceAll('%${k + 1}', _formatNumber(value, fmt));
    }
    return text;
  }
}

String _formatNumber(int n, String format) {
  switch (format) {
    case 'lowerLetter':
      return _letters(n).toLowerCase();
    case 'upperLetter':
      return _letters(n);
    case 'lowerRoman':
      return _roman(n).toLowerCase();
    case 'upperRoman':
      return _roman(n);
    default:
      return '$n';
  }
}

String _letters(int n) {
  if (n <= 0) return '$n';
  final letter = String.fromCharCode(65 + (n - 1) % 26);
  return letter * ((n - 1) ~/ 26 + 1);
}

String _roman(int n) {
  if (n <= 0 || n >= 4000) return '$n';
  const values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
  const symbols = [
    'M', 'CM', 'D', 'CD', 'C', 'XC', 'L', 'XL', 'X', 'IX', 'V', 'IV', 'I', //
  ];
  var rest = n;
  final buffer = StringBuffer();
  for (var i = 0; i < values.length; i++) {
    while (rest >= values[i]) {
      buffer.write(symbols[i]);
      rest -= values[i];
    }
  }
  return buffer.toString();
}

// ---------------------------------------------------------------------------
// Recorrido del documento

class _RunStyle {
  const new({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.link,
  });

  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final String? link;
}

class _DocxParser {
  new({
    required this.archive,
    required this.relationships,
    required this.headingStyles,
    required this.styleNumbering,
    required this.numbering,
  });

  final Archive archive;
  final Map<String, String> relationships;
  final Map<String, int> headingStyles;
  final Map<String, XmlElement> styleNumbering;
  final _Numbering numbering;

  final List<FlowBlock> blocks = [];
  String? firstHeading;

  void parseContainer(XmlElement container) {
    for (final child in container.childElements) {
      if (_isW(child, 'p')) {
        _parseParagraph(child);
      } else if (_isW(child, 'tbl')) {
        blocks.add(_parseTable(child));
      } else if (_isW(child, 'sdt')) {
        final content = _wChild(child, 'sdtContent');
        if (content != null) parseContainer(content);
      } else if (_isW(child, 'customXml') || _isW(child, 'ins')) {
        parseContainer(child);
      }
    }
  }

  void _parseParagraph(XmlElement p) {
    final pPr = _wChild(p, 'pPr');
    final runs = <TextRun>[];
    final images = <ImageBlock>[];
    var pageBreak = false;

    void addText(String text, _RunStyle style) {
      if (text.isEmpty) return;
      final run = TextRun(
        text,
        bold: style.bold,
        italic: style.italic,
        underline: style.underline,
        strike: style.strike,
        link: style.link,
      );
      if (runs.isNotEmpty && runs.last.sameStyleAs(run)) {
        runs[runs.length - 1] = runs.last.copyWithText(runs.last.text + text);
      } else {
        runs.add(run);
      }
    }

    void visit(XmlElement node, String? link) {
      for (final c in node.childElements) {
        if (_isW(c, 'r')) {
          final rPr = _wChild(c, 'rPr');
          final u = _wChild(rPr, 'u');
          final style = _RunStyle(
            bold: _toggle(rPr, 'b'),
            italic: _toggle(rPr, 'i'),
            underline: u != null && _wAttr(u, 'val') != 'none',
            strike: _toggle(rPr, 'strike') || _toggle(rPr, 'dstrike'),
            link: link,
          );
          for (final part in c.childElements) {
            if (_isW(part, 't')) {
              addText(part.innerText, style);
            } else if (_isW(part, 'tab')) {
              addText('\t', style);
            } else if (_isW(part, 'br')) {
              if (_wAttr(part, 'type') == 'page') {
                pageBreak = true;
              } else {
                addText('\n', style);
              }
            } else if (_isW(part, 'cr')) {
              addText('\n', style);
            } else if (_isW(part, 'noBreakHyphen')) {
              addText('-', style);
            } else if (_isW(part, 'drawing') || _isW(part, 'pict')) {
              images.addAll(_extractImages(part));
            }
          }
        } else if (_isW(c, 'hyperlink')) {
          final id =
              c.getAttribute('id', namespaceUri: _r) ?? c.getAttribute('r:id');
          final anchor = _wAttr(c, 'anchor');
          visit(c, id != null ? relationships[id] : (anchor ?? link));
        } else if (_isW(c, 'ins') ||
            _isW(c, 'smartTag') ||
            _isW(c, 'fldSimple') ||
            _isW(c, 'customXml')) {
          visit(c, link);
        } else if (_isW(c, 'sdt')) {
          final content = _wChild(c, 'sdtContent');
          if (content != null) visit(content, link);
        }
        // w:del, w:instrText, w:pPr… se ignoran.
      }
    }

    visit(p, null);

    // Recorta saltos de línea sobrantes al final.
    while (runs.isNotEmpty && runs.last.text.trimRight().isEmpty) {
      runs.removeLast();
    }
    final hasText = runs.any((r) => r.text.trim().isNotEmpty);

    if (hasText) {
      blocks.add(_buildParagraph(pPr, runs));
    }
    blocks.addAll(images);
    if (pageBreak && blocks.isNotEmpty && blocks.last is! DividerBlock) {
      blocks.add(const DividerBlock());
    }
  }

  ParagraphBlock _buildParagraph(XmlElement? pPr, List<TextRun> runs) {
    var heading = 0;
    final styleEl = _wChild(pPr, 'pStyle');
    final styleId = styleEl == null ? null : _wAttr(styleEl, 'val');
    if (styleId != null) heading = headingStyles[styleId] ?? 0;
    final outline = _wChild(pPr, 'outlineLvl');
    if (heading == 0 && outline != null) {
      final val = int.tryParse(_wAttr(outline, 'val') ?? '');
      if (val != null && val < 9) heading = (val + 1).clamp(1, 6);
    }

    final jc = _wChild(pPr, 'jc');
    final alignment = switch (jc == null ? null : _wAttr(jc, 'val')) {
      'center' => FlowAlignment.center,
      'right' || 'end' => FlowAlignment.end,
      'both' || 'distribute' => FlowAlignment.justify,
      _ => FlowAlignment.start,
    };

    ListInfo? list;
    final numPr =
        _wChild(pPr, 'numPr') ??
        (styleId == null ? null : styleNumbering[styleId]);
    if (numPr != null && heading == 0) {
      final ilvlEl = _wChild(numPr, 'ilvl');
      final numIdEl = _wChild(numPr, 'numId');
      final ilvl =
          int.tryParse((ilvlEl == null ? null : _wAttr(ilvlEl, 'val')) ?? '') ??
          0;
      final numId = numIdEl == null ? null : _wAttr(numIdEl, 'val');
      if (numId != null && numId != '0') {
        list = ListInfo(level: ilvl, marker: numbering.marker(numId, ilvl));
      }
    }

    final block = ParagraphBlock(
      runs: List.unmodifiable(runs),
      headingLevel: heading,
      alignment: alignment,
      list: list,
    );
    if (heading == 1 && firstHeading == null) {
      firstHeading = block.plainText.trim();
    }
    return block;
  }

  TableBlock _parseTable(XmlElement tbl) {
    final rows = <List<String>>[];
    for (final tr in tbl.childElements.where((e) => _isW(e, 'tr'))) {
      final cells = <String>[];
      for (final tc in tr.childElements.where((e) => _isW(e, 'tc'))) {
        cells.add(_cellText(tc).trim());
      }
      if (cells.isNotEmpty) rows.add(cells);
    }
    // Normaliza el número de columnas.
    final width = rows.fold<int>(0, (m, r) => r.length > m ? r.length : m);
    return TableBlock(
      rows: [
        for (final r in rows) [...r, for (var i = r.length; i < width; i++) ''],
      ],
    );
  }

  /// Texto de una celda: párrafos unidos por '\n' (tablas anidadas incluidas).
  String _cellText(XmlElement tc) {
    final lines = <String>[];
    for (final p in tc.descendantElements.where((e) => _isW(e, 'p'))) {
      final buffer = StringBuffer();
      for (final e in p.descendantElements) {
        if (_isW(e, 't') && !_insideDeletion(e, p)) {
          buffer.write(e.innerText);
        } else if (_isW(e, 'tab')) {
          buffer.write('\t');
        }
      }
      lines.add(buffer.toString());
    }
    return lines.join('\n');
  }

  bool _insideDeletion(XmlElement e, XmlElement stop) {
    var node = e.parent;
    while (node != null && node != stop) {
      if (node is XmlElement && _isW(node, 'del')) return true;
      node = node.parent;
    }
    return false;
  }

  List<ImageBlock> _extractImages(XmlElement element) {
    final result = <ImageBlock>[];
    for (final e in element.descendantElements) {
      String? id;
      if (e.name.local == 'blip' && e.name.namespaceUri == _a) {
        id = e.getAttribute('embed', namespaceUri: _r);
      } else if (e.name.local == 'imagedata' && e.name.namespaceUri == _v) {
        id = e.getAttribute('id', namespaceUri: _r);
      }
      if (id == null) continue;
      final target = relationships[id];
      if (target == null) continue;
      final ext = target.split('.').last.toLowerCase();
      if (!_imageExtensions.contains(ext)) continue;
      final path = _resolvePath(target);
      final data = archive.findFile(path)?.readBytes();
      if (data == null || data.isEmpty) continue;
      result.add(ImageBlock(bytes: data, description: _altText(element)));
    }
    return result;
  }

  String? _altText(XmlElement drawing) {
    for (final e in drawing.descendantElements) {
      if (e.name.local == 'docPr') {
        final d = e.getAttribute('descr');
        if (d != null && d.trim().isNotEmpty) return d.trim();
      }
    }
    return null;
  }
}

/// Resuelve una ruta relativa a `word/` ("media/x.png", "../media/x.png").
String _resolvePath(String target) {
  if (target.startsWith('/')) return target.substring(1);
  final parts = <String>['word'];
  for (final segment in target.split('/')) {
    if (segment == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else if (segment.isNotEmpty && segment != '.') {
      parts.add(segment);
    }
  }
  return parts.join('/');
}
