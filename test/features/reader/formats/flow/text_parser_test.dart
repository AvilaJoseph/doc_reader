import 'dart:convert';
import 'dart:typed_data';

import 'package:doc_reader/features/reader/formats/flow/flow_document.dart';
import 'package:doc_reader/features/reader/formats/flow/text_parser.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _utf8(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  group('decodeText', () {
    test('quita el BOM UTF-8', () {
      expect(decodeText(Uint8List.fromList([0xEF, 0xBB, 0xBF, 0x61])), 'a');
    });

    test('decodifica UTF-16 LE y BE', () {
      expect(
        decodeText(Uint8List.fromList([0xFF, 0xFE, 0x68, 0x00, 0xF1, 0x00])),
        'hñ',
      );
      expect(
        decodeText(Uint8List.fromList([0xFE, 0xFF, 0x00, 0x68, 0x00, 0xF1])),
        'hñ',
      );
    });

    test('usa Latin-1 si el UTF-8 es inválido', () {
      expect(decodeText(Uint8List.fromList(latin1.encode('añoñó'))), 'añoñó');
    });
  });

  test('parsePlainText separa párrafos por líneas en blanco', () {
    final doc = parsePlainText(_utf8('uno\ndos\r\n\r\n\ntres\n'));
    final texts = doc.blocks.cast<ParagraphBlock>().map((b) => b.plainText);
    expect(texts, ['uno\ndos', 'tres']);
  });

  group('parseMarkdown', () {
    test('encabezados, listas y separador', () {
      final doc = parseMarkdown(
        _utf8(
          '# Título\n\nTexto **fuerte** y *suave*.\n\n'
          '- a\n  - b\n1. uno\n\n---\n## Sub',
        ),
      );
      expect(doc.title, 'Título');
      final b = doc.blocks;
      expect((b[0] as ParagraphBlock).headingLevel, 1);
      expect((b[1] as ParagraphBlock).runs, const [
        TextRun('Texto '),
        TextRun('fuerte', bold: true),
        TextRun(' y '),
        TextRun('suave', italic: true),
        TextRun('.'),
      ]);
      expect(
        (b[2] as ParagraphBlock).list,
        const ListInfo(level: 0, marker: '•'),
      );
      expect(
        (b[3] as ParagraphBlock).list,
        const ListInfo(level: 1, marker: '•'),
      );
      expect(
        (b[4] as ParagraphBlock).list,
        const ListInfo(level: 0, marker: '1.'),
      );
      expect(b[5], isA<DividerBlock>());
      expect((b[6] as ParagraphBlock).headingLevel, 2);
    });

    test('código y enlaces', () {
      final doc = parseMarkdown(
        _utf8(
          'Usa `flutter` y [docs](https://x.dev)\n\n```\nlinea1\nlinea2\n```',
        ),
      );
      final p = doc.blocks[0] as ParagraphBlock;
      expect(p.runs, const [
        TextRun('Usa '),
        TextRun('flutter', code: true),
        TextRun(' y '),
        TextRun('docs', link: 'https://x.dev'),
      ]);
      final code = doc.blocks[1] as ParagraphBlock;
      expect(code.runs.single, const TextRun('linea1\nlinea2', code: true));
    });
  });
}
