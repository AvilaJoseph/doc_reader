import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:doc_reader/core/errors/app_exception.dart';
import 'package:doc_reader/features/reader/formats/flow/flow_document.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

/// Convierte un libro EPUB (2 o 3) en un [FlowDocument]: capítulos en el
/// orden de lectura, con títulos, párrafos, listas, citas e imágenes.
///
/// Función pura de nivel superior para usarla con `compute()`.
FlowDocument parseEpub(Uint8List bytes) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } on Object catch (e) {
    throw DocumentParseException('No es un archivo ZIP válido: $e');
  }

  final container = _readXml(archive, 'META-INF/container.xml');
  final opfPath = container
      ?.findAllElements('rootfile', namespaceUri: '*')
      .firstOrNull
      ?.getAttribute('full-path');
  if (opfPath == null) {
    throw const DocumentParseException('Falta META-INF/container.xml');
  }
  final opf = _readXml(archive, opfPath);
  if (opf == null) throw DocumentParseException('Falta $opfPath');
  final base = p.posix.dirname(opfPath);

  final manifest = <String, String>{
    for (final item in opf.findAllElements('item', namespaceUri: '*'))
      if (item.getAttribute('id') case final id?)
        if (item.getAttribute('href') case final href?)
          id: _join(base, Uri.decodeFull(href)),
  };
  final spine = [
    for (final ref in opf.findAllElements('itemref', namespaceUri: '*'))
      ?manifest[ref.getAttribute('idref')],
  ];
  final title = opf
      .findAllElements('title', namespaceUri: '*')
      .firstOrNull
      ?.innerText
      .trim();

  final reader = _HtmlReader(archive);
  for (final (i, path) in spine.indexed) {
    final html = _readXml(archive, path, html: true);
    final body = html?.findAllElements('body', namespaceUri: '*').firstOrNull;
    if (body == null) continue;
    if (i > 0 && reader.blocks.isNotEmpty) {
      reader.blocks.add(const DividerBlock());
    }
    reader.read(body, p.posix.dirname(path));
  }
  // Quita separadores al final o repetidos.
  final blocks = <FlowBlock>[];
  for (final block in reader.blocks) {
    if (block is DividerBlock &&
        (blocks.isEmpty || blocks.last is DividerBlock)) {
      continue;
    }
    blocks.add(block);
  }
  if (blocks.isNotEmpty && blocks.last is DividerBlock) blocks.removeLast();
  return FlowDocument(
    blocks: blocks,
    title: title == null || title.isEmpty ? null : title,
  );
}

String _join(String base, String href) =>
    p.posix.normalize(base == '.' ? href : p.posix.join(base, href));

XmlDocument? _readXml(Archive archive, String path, {bool html = false}) {
  final data = archive.findFile(path)?.readBytes();
  if (data == null) return null;
  try {
    return XmlDocument.parse(
      utf8.decode(data, allowMalformed: true),
      // Los libros usan entidades HTML (&nbsp;, &mdash;…).
      entityMapping: html ? const XmlDefaultEntityMapping.html5() : null,
    );
  } on XmlException {
    if (html) return null; // Un capítulo roto no tumba el libro entero.
    throw DocumentParseException('XML inválido en $path');
  }
}

const _blockTags = {
  'p',
  'div',
  'section',
  'article',
  'blockquote',
  'li',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'pre',
  'figcaption',
  'dd',
  'dt',
  'td',
  'th',
  'caption',
};
const _skipTags = {'script', 'style', 'head', 'nav', 'svg', 'math'};

class _Style {
  const new({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.code = false,
    this.link,
  });

  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final bool code;
  final String? link;

  _Style apply(String tag, XmlElement e) => _Style(
    bold: bold || tag == 'b' || tag == 'strong',
    italic: italic || tag == 'i' || tag == 'em' || tag == 'cite',
    underline: underline || tag == 'u' || tag == 'ins',
    strike: strike || tag == 's' || tag == 'strike' || tag == 'del',
    code: code || tag == 'code' || tag == 'tt' || tag == 'kbd',
    link: tag == 'a' ? (e.getAttribute('href') ?? link) : link,
  );
}

class _HtmlReader {
  new(this.archive);

  final Archive archive;
  final blocks = <FlowBlock>[];
  final _runs = <TextRun>[];
  int _heading = 0;
  ListInfo? _list;
  final _counters = <int>[];

  void read(XmlElement body, String dir) =>
      _children(body, dir, const _Style());

  void _children(XmlElement parent, String dir, _Style style) {
    for (final node in parent.children) {
      switch (node) {
        case XmlText(:final value) || XmlCDATA(:final value):
          _text(value, style);
        case final XmlElement e:
          _element(e, dir, style);
      }
    }
  }

  void _element(XmlElement e, String dir, _Style style) {
    final tag = e.name.local.toLowerCase();
    if (_skipTags.contains(tag)) return;
    switch (tag) {
      case 'br':
        _runs.add(TextRun('\n', bold: style.bold, italic: style.italic));
        return;
      case 'hr':
        _flush();
        blocks.add(const DividerBlock());
        return;
      case 'img' || 'image':
        _flush();
        final src =
            e.getAttribute('src') ??
            e.getAttribute('href', namespaceUri: '*') ??
            e.getAttribute('xlink:href');
        if (src != null) {
          final data = archive
              .findFile(_join(dir, Uri.decodeFull(src)))
              ?.readBytes();
          if (data != null) {
            blocks.add(
              ImageBlock(bytes: data, description: e.getAttribute('alt')),
            );
          }
        }
        return;
      case 'ul' || 'ol':
        _flush();
        _counters.add(0);
        final level = _counters.length - 1;
        for (final child in e.childElements) {
          if (child.name.local.toLowerCase() == 'li') {
            _counters[level]++;
            final previous = _list;
            _list = ListInfo(
              level: level,
              marker: tag == 'ol' ? '${_counters[level]}.' : '•',
            );
            _children(child, dir, style);
            _flush();
            _list = previous;
          } else {
            _element(child, dir, style);
          }
        }
        _counters.removeLast();
        return;
      case 'table':
        _flush();
        final rows = [
          for (final tr in e.findAllElements('tr', namespaceUri: '*'))
            [
              for (final cell in tr.childElements)
                if (cell.name.local == 'td' || cell.name.local == 'th')
                  cell.innerText.replaceAll(RegExp(r'\s+'), ' ').trim(),
            ],
        ];
        if (rows.isNotEmpty) blocks.add(TableBlock(rows: rows));
        return;
    }

    final isBlock = _blockTags.contains(tag);
    if (isBlock) _flush();
    final previousHeading = _heading;
    if (tag.length == 2 && tag[0] == 'h' && '123456'.contains(tag[1])) {
      _heading = int.parse(tag[1]);
    }
    _children(e, dir, style.apply(tag, e));
    if (isBlock) _flush();
    _heading = previousHeading;
  }

  void _text(String raw, _Style style) {
    // Espacios de HTML: cualquier secuencia cuenta como uno.
    // (Sin tocar &nbsp;, que es un espacio duro a propósito.)
    final text = raw.replaceAll(RegExp(r'[ \t\r\n\f]+'), ' ');
    if (text.isEmpty) return;
    final run = TextRun(
      text,
      bold: style.bold,
      italic: style.italic,
      underline: style.underline,
      strike: style.strike,
      code: style.code,
      link: style.link,
    );
    if (_runs.isNotEmpty && _runs.last.sameStyleAs(run)) {
      final last = _runs.removeLast();
      _runs.add(last.copyWithText(last.text + text));
    } else {
      _runs.add(run);
    }
  }

  void _flush() {
    if (_runs.isEmpty) return;
    // Recorta espacios al principio y al final del párrafo.
    final runs = List.of(_runs);
    _runs.clear();
    runs[0] = runs[0].copyWithText(runs[0].text.trimLeft());
    runs[runs.length - 1] = runs.last.copyWithText(runs.last.text.trimRight());
    final cleaned = [
      for (final r in runs)
        if (r.text.isNotEmpty) r,
    ];
    if (cleaned.isEmpty) return;
    blocks.add(
      ParagraphBlock(runs: cleaned, headingLevel: _heading, list: _list),
    );
  }
}
