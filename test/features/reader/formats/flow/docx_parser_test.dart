// XML generado por concatenación: los espacios entre cadenas no aplican.
// ignore_for_file: missing_whitespace_between_adjacent_strings

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:doc_reader/core/errors/app_exception.dart';
import 'package:doc_reader/features/reader/formats/flow/docx_parser.dart';
import 'package:doc_reader/features/reader/formats/flow/flow_document.dart';
import 'package:flutter_test/flutter_test.dart';

const _ns =
    'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"';

Uint8List _docx(
  String body, {
  String? styles,
  String? numbering,
  String? rels,
}) {
  final archive = Archive()
    ..addFile(
      ArchiveFile.string(
        'word/document.xml',
        '<?xml version="1.0" encoding="UTF-8"?>'
            '<w:document $_ns><w:body>$body</w:body></w:document>',
      ),
    );
  if (styles != null) {
    archive.addFile(
      ArchiveFile.string(
        'word/styles.xml',
        '<w:styles $_ns>$styles</w:styles>',
      ),
    );
  }
  if (numbering != null) {
    archive.addFile(
      ArchiveFile.string(
        'word/numbering.xml',
        '<w:numbering $_ns>$numbering</w:numbering>',
      ),
    );
  }
  if (rels != null) {
    archive.addFile(
      ArchiveFile.string(
        'word/_rels/document.xml.rels',
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/'
            'relationships">$rels</Relationships>',
      ),
    );
  }
  return ZipEncoder().encodeBytes(archive);
}

String _p(String content, {String pPr = ''}) =>
    '<w:p>${pPr.isEmpty ? '' : '<w:pPr>$pPr</w:pPr>'}$content</w:p>';

String _r(String text, {String rPr = ''}) =>
    '<w:r>${rPr.isEmpty ? '' : '<w:rPr>$rPr</w:rPr>'}'
    '<w:t xml:space="preserve">$text</w:t></w:r>';

void main() {
  group('parseDocx', () {
    test('lee encabezados por estilo y título', () {
      final doc = parseDocx(
        _docx(
          _p(_r('Mi título'), pPr: '<w:pStyle w:val="Titulo1"/>') +
              _p(_r('Texto normal')),
          styles:
              '<w:style w:type="paragraph" w:styleId="Titulo1">'
              '<w:name w:val="heading 1"/></w:style>',
        ),
      );
      expect(doc.title, 'Mi título');
      final blocks = doc.blocks.cast<ParagraphBlock>();
      expect(blocks[0].headingLevel, 1);
      expect(blocks[1].headingLevel, 0);
      expect(blocks[1].plainText, 'Texto normal');
    });

    test('aplica negrita/cursiva y fusiona runs iguales', () {
      final doc = parseDocx(
        _docx(
          _p(
            _r('Hola ', rPr: '<w:b/>') +
                _r('mundo', rPr: '<w:b/>') +
                _r(' cursiva', rPr: '<w:i/><w:b w:val="0"/>'),
          ),
        ),
      );
      final p = doc.blocks.single as ParagraphBlock;
      expect(p.runs, const [
        TextRun('Hola mundo', bold: true),
        TextRun(' cursiva', italic: true),
      ]);
    });

    test('resuelve listas numeradas y con viñetas', () {
      const numbering =
          '<w:abstractNum w:abstractNumId="0">'
          '<w:lvl w:ilvl="0"><w:start w:val="1"/><w:numFmt w:val="decimal"/>'
          '<w:lvlText w:val="%1."/></w:lvl>'
          '<w:lvl w:ilvl="1"><w:start w:val="1"/>'
          '<w:numFmt w:val="lowerLetter"/><w:lvlText w:val="%2)"/></w:lvl>'
          '</w:abstractNum>'
          '<w:abstractNum w:abstractNumId="1">'
          '<w:lvl w:ilvl="0"><w:numFmt w:val="bullet"/>'
          '<w:lvlText w:val="·"/></w:lvl></w:abstractNum>'
          '<w:num w:numId="1"><w:abstractNumId w:val="0"/></w:num>'
          '<w:num w:numId="2"><w:abstractNumId w:val="1"/></w:num>';
      String item(String text, int numId, int lvl) => _p(
        _r(text),
        pPr:
            '<w:numPr><w:ilvl w:val="$lvl"/><w:numId w:val="$numId"/>'
            '</w:numPr>',
      );
      final doc = parseDocx(
        _docx(
          item('uno', 1, 0) +
              item('sub a', 1, 1) +
              item('sub b', 1, 1) +
              item('dos', 1, 0) +
              item('sub otra', 1, 1) +
              item('viñeta', 2, 0),
          numbering: numbering,
        ),
      );
      final markers = doc.blocks
          .cast<ParagraphBlock>()
          .map((b) => '${b.list!.level}${b.list!.marker}')
          .toList();
      expect(markers, ['01.', '1a)', '1b)', '02.', '1a)', '0•']);
    });

    test('usa la numeración definida en el estilo', () {
      final doc = parseDocx(
        _docx(
          _p(_r('uno'), pPr: '<w:pStyle w:val="ListNumber"/>') +
              _p(_r('dos'), pPr: '<w:pStyle w:val="ListNumber"/>'),
          styles:
              '<w:style w:type="paragraph" w:styleId="ListNumber">'
              '<w:name w:val="List Number"/><w:pPr><w:numPr>'
              '<w:numId w:val="3"/></w:numPr></w:pPr></w:style>',
          numbering:
              '<w:abstractNum w:abstractNumId="7"><w:lvl w:ilvl="0">'
              '<w:numFmt w:val="decimal"/><w:lvlText w:val="%1."/></w:lvl>'
              '</w:abstractNum>'
              '<w:num w:numId="3"><w:abstractNumId w:val="7"/></w:num>',
        ),
      );
      final markers = doc.blocks
          .cast<ParagraphBlock>()
          .map((b) => b.list?.marker)
          .toList();
      expect(markers, ['1.', '2.']);
    });

    test('convierte tablas', () {
      final doc = parseDocx(
        _docx(
          '<w:tbl>'
          '<w:tr><w:tc>${_p(_r('A'))}</w:tc><w:tc>${_p(_r('B'))}</w:tc></w:tr>'
          '<w:tr><w:tc>${_p(_r('1'))}${_p(_r('2'))}</w:tc></w:tr>'
          '</w:tbl>',
        ),
      );
      final table = doc.blocks.single as TableBlock;
      expect(table.rows, [
        ['A', 'B'],
        ['1\n2', ''],
      ]);
    });

    test('resuelve hipervínculos y salto de página', () {
      final doc = parseDocx(
        _docx(
          _p(
                '<w:hyperlink r:id="rId5">${_r('enlace')}</w:hyperlink>'
                '<w:r><w:br w:type="page"/></w:r>',
              ) +
              _p(_r('después')),
          rels:
              '<Relationship Id="rId5" Type="hyperlink" '
              'Target="https://example.com" TargetMode="External"/>',
        ),
      );
      final first = doc.blocks[0] as ParagraphBlock;
      expect(first.runs.single.link, 'https://example.com');
      expect(doc.blocks[1], isA<DividerBlock>());
      expect((doc.blocks[2] as ParagraphBlock).plainText, 'después');
    });

    test('ignora texto eliminado y párrafos vacíos', () {
      final doc = parseDocx(
        _docx(
          _p(
                '<w:del><w:r><w:delText>borrado</w:delText></w:r></w:del>'
                '${_r('queda')}',
              ) +
              _p(''),
        ),
      );
      expect(doc.blocks, hasLength(1));
      expect((doc.blocks.single as ParagraphBlock).plainText, 'queda');
    });

    test('lanza DocumentParseException con bytes inválidos', () {
      expect(
        () => parseDocx(Uint8List.fromList(utf8.encode('no es un zip'))),
        throwsA(isA<DocumentParseException>()),
      );
    });

    test('lanza si falta word/document.xml', () {
      final zip = ZipEncoder().encodeBytes(
        Archive()..addFile(ArchiveFile.string('otro.txt', 'x')),
      );
      expect(() => parseDocx(zip), throwsA(isA<DocumentParseException>()));
    });
  });
}
