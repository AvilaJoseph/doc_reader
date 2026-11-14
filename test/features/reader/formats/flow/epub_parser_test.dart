import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:doc_reader/core/errors/app_exception.dart';
import 'package:doc_reader/features/reader/formats/flow/epub_parser.dart';
import 'package:doc_reader/features/reader/formats/flow/flow_document.dart';
import 'package:flutter_test/flutter_test.dart';

/// Construye un EPUB mínimo en memoria.
Uint8List _epub(Map<String, Object> files) {
  final archive = Archive();
  for (final MapEntry(:key, :value) in files.entries) {
    final data = value is String ? utf8.encode(value) : value as List<int>;
    archive.add(ArchiveFile.bytes(key, data));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

const _container = '''
<?xml version="1.0"?>
<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
  <rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles>
</container>''';

const _opf = '''
<?xml version="1.0"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>Mi libro</dc:title></metadata>
  <manifest>
    <item id="c1" href="text/cap1.xhtml" media-type="application/xhtml+xml"/>
    <item id="c2" href="text/cap%202.xhtml" media-type="application/xhtml+xml"/>
    <item id="img" href="img/foto.png" media-type="image/png"/>
  </manifest>
  <spine><itemref idref="c2"/><itemref idref="c1"/></spine>
</package>''';

const _cap1 = '''
<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml"><head><title>x</title><style>p{}</style></head>
<body>
  <h1>Capítulo uno</h1>
  <p>Texto con <b>negrita</b>,&nbsp;<em>cursiva</em> y
     un <a href="https://ejemplo.com">enlace</a>.</p>
  <ol><li>Primero</li><li>Segundo</li></ol>
  <img src="../img/foto.png" alt="Una foto"/>
</body></html>''';

const _cap2 = '''
<?xml version="1.0"?>
<html xmlns="http://www.w3.org/1999/xhtml"><body><p>Prólogo</p></body></html>''';

void main() {
  test(
    'lee capítulos en el orden del spine con estilos, listas e imágenes',
    () {
      final doc = parseEpub(
        _epub({
          'mimetype': 'application/epub+zip',
          'META-INF/container.xml': _container,
          'OEBPS/content.opf': _opf,
          'OEBPS/text/cap1.xhtml': _cap1,
          'OEBPS/text/cap 2.xhtml': _cap2,
          'OEBPS/img/foto.png': [1, 2, 3],
        }),
      );

      expect(doc.title, 'Mi libro');
      final blocks = doc.blocks;
      expect((blocks[0] as ParagraphBlock).plainText, 'Prólogo');
      expect(blocks[1], isA<DividerBlock>());
      final heading = blocks[2] as ParagraphBlock;
      expect(heading.headingLevel, 1);
      expect(heading.plainText, 'Capítulo uno');

      final paragraph = blocks[3] as ParagraphBlock;
      expect(paragraph.plainText, 'Texto con negrita, cursiva y un enlace.');
      expect(
        paragraph.runs.firstWhere((r) => r.text == 'negrita').bold,
        isTrue,
      );
      expect(
        paragraph.runs.firstWhere((r) => r.text == 'enlace').link,
        'https://ejemplo.com',
      );

      final items = blocks.whereType<ParagraphBlock>().where(
        (b) => b.list != null,
      );
      expect(items.map((b) => (b.list!.marker, b.plainText)), [
        ('1.', 'Primero'),
        ('2.', 'Segundo'),
      ]);
      final image = blocks.whereType<ImageBlock>().single;
      expect(image.bytes, [1, 2, 3]);
      expect(image.description, 'Una foto');
    },
  );

  test('rechaza archivos sin container.xml', () {
    expect(
      () => parseEpub(_epub({'mimetype': 'application/epub+zip'})),
      throwsA(isA<DocumentParseException>()),
    );
  });

  test('rechaza bytes que no son ZIP', () {
    expect(
      () => parseEpub(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<DocumentParseException>()),
    );
  });
}
