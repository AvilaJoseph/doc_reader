import 'dart:convert';
import 'dart:typed_data';

import 'package:doc_reader/features/reader/formats/flow/flow_document.dart';

/// Decodifica bytes de texto detectando BOM; UTF-8 por defecto y Latin-1
/// como respaldo si el UTF-8 parece corrupto.
String decodeText(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF) {
    return utf8.decode(bytes.sublist(3), allowMalformed: true);
  }
  if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
    return _decodeUtf16(bytes.sublist(2), littleEndian: true);
  }
  if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
    return _decodeUtf16(bytes.sublist(2), littleEndian: false);
  }
  final text = utf8.decode(bytes, allowMalformed: true);
  final bad = '�'.allMatches(text).length;
  if (bad > 0 && bad * 100 > text.length) {
    return latin1.decode(bytes);
  }
  return text;
}

String _decodeUtf16(Uint8List bytes, {required bool littleEndian}) {
  final units = <int>[];
  for (var i = 0; i + 1 < bytes.length; i += 2) {
    units.add(
      littleEndian
          ? bytes[i] | (bytes[i + 1] << 8)
          : (bytes[i] << 8) | bytes[i + 1],
    );
  }
  return String.fromCharCodes(units);
}

List<String> _lines(String text) =>
    text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');

/// Texto plano: un párrafo por cada bloque separado por líneas en blanco.
FlowDocument parsePlainText(Uint8List bytes) {
  final blocks = <FlowBlock>[];
  final current = <String>[];

  void flush() {
    if (current.isEmpty) return;
    blocks.add(ParagraphBlock(runs: [TextRun(current.join('\n'))]));
    current.clear();
  }

  for (final line in _lines(decodeText(bytes))) {
    if (line.trim().isEmpty) {
      flush();
    } else {
      current.add(line.trimRight());
    }
  }
  flush();
  return FlowDocument(blocks: blocks);
}

// ---------------------------------------------------------------------------
// Markdown (subconjunto pragmático)

final _heading = RegExp(r'^(#{1,6})\s+(.*?)\s*#*\s*$');
final _bullet = RegExp(r'^(\s*)[-*+]\s+(.*)$');
final _ordered = RegExp(r'^(\s*)(\d+)[.)]\s+(.*)$');
final _divider = RegExp(r'^\s*([-*_])(\s*\1){2,}\s*$');
final _fence = RegExp(r'^\s*(```|~~~)');

/// Markdown básico: encabezados, listas, separadores, código y énfasis.
FlowDocument parseMarkdown(Uint8List bytes) {
  final blocks = <FlowBlock>[];
  final paragraph = <String>[];
  String? title;

  void flushParagraph() {
    if (paragraph.isEmpty) return;
    blocks.add(ParagraphBlock(runs: parseInlineMarkdown(paragraph.join(' '))));
    paragraph.clear();
  }

  final lines = _lines(decodeText(bytes));
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];

    if (_fence.hasMatch(line)) {
      flushParagraph();
      final code = <String>[];
      i++;
      while (i < lines.length && !_fence.hasMatch(lines[i])) {
        code.add(lines[i]);
        i++;
      }
      if (code.isNotEmpty) {
        blocks.add(
          ParagraphBlock(runs: [TextRun(code.join('\n'), code: true)]),
        );
      }
      continue;
    }

    if (line.trim().isEmpty) {
      flushParagraph();
      continue;
    }

    final h = _heading.firstMatch(line);
    if (h != null) {
      flushParagraph();
      final level = h.group(1)!.length;
      final runs = parseInlineMarkdown(h.group(2)!);
      if (level == 1 && title == null) {
        title = runs.map((r) => r.text).join();
      }
      blocks.add(ParagraphBlock(runs: runs, headingLevel: level));
      continue;
    }

    if (_divider.hasMatch(line)) {
      flushParagraph();
      blocks.add(const DividerBlock());
      continue;
    }

    final b = _bullet.firstMatch(line);
    final o = b == null ? _ordered.firstMatch(line) : null;
    if (b != null || o != null) {
      flushParagraph();
      final indent = (b ?? o)!.group(1)!.replaceAll('\t', '  ').length;
      final marker = b != null ? '•' : '${o!.group(2)}.';
      final text = b != null ? b.group(2)! : o!.group(3)!;
      blocks.add(
        ParagraphBlock(
          runs: parseInlineMarkdown(text),
          list: ListInfo(level: indent ~/ 2, marker: marker),
        ),
      );
      continue;
    }

    // Cita: se trata como texto en cursiva.
    if (line.trimLeft().startsWith('>')) {
      flushParagraph();
      final text = line.trimLeft().substring(1).trim();
      blocks.add(
        ParagraphBlock(
          runs: [
            for (final r in parseInlineMarkdown(text))
              TextRun(
                r.text,
                bold: r.bold,
                italic: true,
                code: r.code,
                link: r.link,
                strike: r.strike,
              ),
          ],
        ),
      );
      continue;
    }

    paragraph.add(line.trim());
  }
  flushParagraph();
  return FlowDocument(blocks: blocks, title: title);
}

final _inline = RegExp(
  r'(`[^`]+`)|(\[[^\]]+\]\([^)\s]+\))|(\*\*[^*]+\*\*|__[^_]+__)'
  r'|(~~[^~]+~~)|(\*[^*\s][^*]*\*|_[^_\s][^_]*_)',
);

/// Convierte énfasis, código y enlaces en [TextRun]s.
List<TextRun> parseInlineMarkdown(
  String text, {
  bool bold = false,
  bool italic = false,
  bool strike = false,
}) {
  final runs = <TextRun>[];

  void add(TextRun run) {
    if (run.text.isEmpty) return;
    if (runs.isNotEmpty && runs.last.sameStyleAs(run)) {
      runs[runs.length - 1] = runs.last.copyWithText(runs.last.text + run.text);
    } else {
      runs.add(run);
    }
  }

  var pos = 0;
  for (final m in _inline.allMatches(text)) {
    if (m.start > pos) {
      add(
        TextRun(
          text.substring(pos, m.start),
          bold: bold,
          italic: italic,
          strike: strike,
        ),
      );
    }
    final token = m.group(0)!;
    if (m.group(1) != null) {
      add(TextRun(token.substring(1, token.length - 1), code: true));
    } else if (m.group(2) != null) {
      final close = token.indexOf('](');
      final label = token.substring(1, close);
      final url = token.substring(close + 2, token.length - 1);
      for (final r in parseInlineMarkdown(
        label,
        bold: bold,
        italic: italic,
        strike: strike,
      )) {
        add(
          TextRun(
            r.text,
            bold: r.bold,
            italic: r.italic,
            strike: r.strike,
            code: r.code,
            link: url,
          ),
        );
      }
    } else if (m.group(3) != null) {
      parseInlineMarkdown(
        token.substring(2, token.length - 2),
        bold: true,
        italic: italic,
        strike: strike,
      ).forEach(add);
    } else if (m.group(4) != null) {
      parseInlineMarkdown(
        token.substring(2, token.length - 2),
        bold: bold,
        italic: italic,
        strike: true,
      ).forEach(add);
    } else {
      parseInlineMarkdown(
        token.substring(1, token.length - 1),
        bold: bold,
        italic: true,
        strike: strike,
      ).forEach(add);
    }
    pos = m.end;
  }
  if (pos < text.length) {
    add(
      TextRun(text.substring(pos), bold: bold, italic: italic, strike: strike),
    );
  }
  return runs;
}
