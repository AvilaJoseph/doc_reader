import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:doc_reader/core/errors/app_exception.dart';
import 'package:doc_reader/features/reader/formats/flow/flow_document.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

const _rel =
    'http://schemas.openxmlformats.org/officeDocument/2006/relationships';

/// Convierte una presentación .pptx en un [FlowDocument] legible: cada
/// diapositiva es un título seguido de su texto (con viñetas y estilos) y
/// sus imágenes, separadas por una línea.
///
/// Función pura de nivel superior para usarla con `compute()`.
FlowDocument parsePptx(Uint8List bytes) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } on Object catch (e) {
    throw DocumentParseException('No es un archivo ZIP válido: $e');
  }
  final slides = _slideOrder(archive);
  if (slides.isEmpty) {
    throw const DocumentParseException('La presentación no tiene diapositivas');
  }

  final blocks = <FlowBlock>[];
  for (final (index, path) in slides.indexed) {
    final xml = _readXml(archive, path);
    if (xml == null) continue;
    if (blocks.isNotEmpty) blocks.add(const DividerBlock());
    _slide(archive, path, xml, index + 1, blocks);
  }
  return FlowDocument(blocks: blocks);
}

XmlDocument? _readXml(Archive archive, String path) {
  final data = archive.findFile(path)?.readBytes();
  if (data == null) return null;
  try {
    return XmlDocument.parse(utf8.decode(data, allowMalformed: true));
  } on XmlException {
    return null;
  }
}

/// Relaciones `rId → ruta` de una parte del paquete.
Map<String, String> _relationships(Archive archive, String part) {
  final dir = p.posix.dirname(part);
  final rels = _readXml(
    archive,
    p.posix.join(dir, '_rels', '${p.posix.basename(part)}.rels'),
  );
  if (rels == null) return const {};
  return {
    for (final r in rels.findAllElements('Relationship', namespaceUri: '*'))
      if ((r.getAttribute('Id'), r.getAttribute('Target')) case (
        final id?,
        final target?,
      ))
        id: p.posix.normalize(p.posix.join(dir, target)),
  };
}

/// Diapositivas en el orden de la presentación (o por número si falta).
List<String> _slideOrder(Archive archive) {
  const presentation = 'ppt/presentation.xml';
  final xml = _readXml(archive, presentation);
  if (xml != null) {
    final rels = _relationships(archive, presentation);
    final ordered = [
      for (final id in xml.findAllElements('sldId', namespaceUri: '*'))
        ?rels[id.getAttribute('id', namespaceUri: _rel)],
    ];
    if (ordered.isNotEmpty) return ordered;
  }
  final number = RegExp(r'ppt/slides/slide(\d+)\.xml$');
  final found = [
    for (final file in archive.files)
      if (number.firstMatch(file.name) case final m?)
        (int.parse(m.group(1)!), file.name),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final (_, name) in found) name];
}

void _slide(
  Archive archive,
  String path,
  XmlDocument xml,
  int number,
  List<FlowBlock> blocks,
) {
  final rels = _relationships(archive, path);
  // El título va primero aunque su forma esté después en el XML.
  final title = <FlowBlock>[];
  final body = <FlowBlock>[];
  for (final shape in xml.findAllElements('sp', namespaceUri: '*')) {
    final placeholder = shape
        .findAllElements('ph', namespaceUri: '*')
        .firstOrNull;
    // Un marcador sin tipo es, por norma, el cuadro de contenido ("body").
    final type = placeholder == null
        ? null
        : placeholder.getAttribute('type') ?? 'body';
    final isTitle = type == 'title' || type == 'ctrTitle';
    for (final para in shape.findAllElements('p', namespaceUri: '*')) {
      final runs = _runs(para);
      if (runs.map((r) => r.text).join().trim().isEmpty) continue;
      final props = para.findElements('pPr', namespaceUri: '*').firstOrNull;
      final level = int.tryParse(props?.getAttribute('lvl') ?? '') ?? 0;
      final noBullet =
          props?.findElements('buNone', namespaceUri: '*').isNotEmpty ?? false;
      (isTitle ? title : body).add(
        ParagraphBlock(
          runs: runs,
          headingLevel: isTitle ? 2 : 0,
          // Las viñetas solo en el cuadro de contenido principal.
          list: type == 'body' && !noBullet
              ? ListInfo(level: level, marker: '•')
              : null,
        ),
      );
    }
  }
  if (title.isEmpty) {
    // Sin título propio: se numera para poder orientarse.
    title.add(ParagraphBlock(runs: [TextRun('$number')], headingLevel: 3));
  }
  blocks
    ..addAll(title)
    ..addAll(body);
  for (final blip in xml.findAllElements('blip', namespaceUri: '*')) {
    final target = rels[blip.getAttribute('embed', namespaceUri: _rel)];
    final data = target == null ? null : archive.findFile(target)?.readBytes();
    if (data != null) blocks.add(ImageBlock(bytes: data));
  }
}

List<TextRun> _runs(XmlElement para) {
  final runs = <TextRun>[];
  for (final node in para.childElements) {
    switch (node.name.local) {
      case 'r':
        final text = node.findElements('t', namespaceUri: '*').firstOrNull;
        if (text == null) continue;
        final props = node.findElements('rPr', namespaceUri: '*').firstOrNull;
        runs.add(
          TextRun(
            text.innerText,
            bold: props?.getAttribute('b') == '1',
            italic: props?.getAttribute('i') == '1',
            underline: (props?.getAttribute('u') ?? 'none') != 'none',
            strike: (props?.getAttribute('strike') ?? 'noStrike') != 'noStrike',
          ),
        );
      case 'br':
        runs.add(const TextRun('\n'));
      case 'fld':
        final text = node.findElements('t', namespaceUri: '*').firstOrNull;
        if (text != null) runs.add(TextRun(text.innerText));
    }
  }
  return runs;
}
