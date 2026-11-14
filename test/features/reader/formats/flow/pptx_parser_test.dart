import 'dart:io';
import 'dart:typed_data';

import 'package:doc_reader/core/errors/app_exception.dart';
import 'package:doc_reader/features/reader/formats/flow/flow_document.dart';
import 'package:doc_reader/features/reader/formats/flow/pptx_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lee las diapositivas en orden con título, viñetas y estilos', () {
    final bytes = File('test/fixtures/sample.pptx').readAsBytesSync();
    final blocks = parsePptx(bytes).blocks;
    final paragraphs = blocks.whereType<ParagraphBlock>().toList();

    expect(paragraphs.map((p) => p.plainText), [
      'Plan de lectura',
      'Subtítulo',
      'Objetivos',
      'Leer más',
      'Sin distracciones',
      'Importante',
      '3',
      'Nota suelta',
    ]);
    expect(blocks.whereType<DividerBlock>(), hasLength(2));
    expect(paragraphs[0].headingLevel, 2);
    expect(paragraphs[3].list?.level, 0);
    expect(paragraphs[4].list?.level, 1);
    expect(paragraphs[5].runs.single.bold, isTrue);
    // Diapositiva sin título: se numera.
    expect(paragraphs[6].headingLevel, 3);
    expect(paragraphs[7].list, isNull);
  });

  test('rechaza bytes que no son pptx', () {
    expect(
      () => parsePptx(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<DocumentParseException>()),
    );
  });
}
