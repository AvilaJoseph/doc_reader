import 'dart:convert';
import 'dart:typed_data';

import 'package:doc_reader/core/errors/app_exception.dart';
import 'package:doc_reader/features/reader/formats/flow/flow_document.dart';
import 'package:doc_reader/features/reader/formats/flow/rtf_parser.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _rtf(String body) => Uint8List.fromList(latin1.encode(body));

List<ParagraphBlock> _paragraphs(FlowDocument doc) =>
    doc.blocks.whereType<ParagraphBlock>().toList();

void main() {
  test('lee párrafos con estilos e ignora tablas de fuentes', () {
    final doc = parseRtf(
      _rtf(
        [
          r'{\rtf1\ansi\deff0{\fonttbl{\f0 Times;}}',
          r'{\colortbl;\red0\green0\blue0;}',
          r'\pard Hola {\b negrita} y \i cursiva\i0 .\par',
          r' Segundo \ul p\u225?rrafo\ulnone\par}',
        ].join(),
      ),
    );
    final paragraphs = _paragraphs(doc);
    expect(paragraphs.map((p) => p.plainText), [
      'Hola negrita y cursiva.',
      'Segundo párrafo',
    ]);
    final first = paragraphs.first.runs;
    expect(first.firstWhere((r) => r.text == 'negrita').bold, isTrue);
    expect(first.firstWhere((r) => r.text == 'cursiva').italic, isTrue);
    expect(paragraphs.last.runs.last.underline, isTrue);
  });

  test(r"decodifica \'hh en Windows-1252 y comillas tipográficas", () {
    final doc = parseRtf(
      _rtf(r"{\rtf1\ansi Caf\'e9 \'93s\'ed\'94 \emdash fin\par}"),
    );
    expect(_paragraphs(doc).single.plainText, 'Café “sí” —fin');
  });

  test(r'ignora destinos {\* ...} desconocidos', () {
    final doc = parseRtf(
      _rtf(r'{\rtf1{\*\generator Riched20;}{\*\xyz oculto}Visible\par}'),
    );
    expect(_paragraphs(doc).single.plainText, 'Visible');
  });

  test('rechaza bytes que no son RTF', () {
    expect(
      () => parseRtf(_rtf('hola')),
      throwsA(isA<DocumentParseException>()),
    );
  });
}
