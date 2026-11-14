import 'dart:typed_data';

import 'package:doc_reader/core/errors/app_exception.dart';
import 'package:doc_reader/features/reader/formats/flow/flow_document.dart';

/// Lee un documento RTF (WordPad, TextEdit, exportaciones antiguas) como
/// texto con negrita, cursiva, subrayado y tachado. Ignora tablas de
/// fuentes, colores, imágenes y metadatos.
FlowDocument parseRtf(Uint8List bytes) {
  if (bytes.length < 5 ||
      String.fromCharCodes(bytes.sublist(0, 5)) != r'{\rtf') {
    throw const DocumentParseException('No es un documento RTF');
  }
  return _RtfReader(bytes).read();
}

/// Destinos cuyo contenido no es texto visible.
const _skipped = {
  'fonttbl',
  'colortbl',
  'stylesheet',
  'info',
  'pict',
  'header',
  'footer',
  'headerl',
  'headerr',
  'headerf',
  'footerl',
  'footerr',
  'footerf',
  'listtable',
  'listoverridetable',
  'themedata',
  'colorschememapping',
  'latentstyles',
  'datastore',
  'xmlnstbl',
  'rsidtbl',
  'generator',
  'fldinst',
  'object',
  'filetbl',
  'revtbl',
  'mmathPr',
  'pgdsctbl',
  'operator',
  'author',
  'title',
  'company',
  'nonshppict',
  'bkmkstart',
  'bkmkend',
};

/// Caracteres de Windows-1252 entre 0x80 y 0x9F (el resto coincide con
/// Latin-1).
const _cp1252 = {
  0x80: 0x20AC,
  0x82: 0x201A,
  0x83: 0x0192,
  0x84: 0x201E,
  0x85: 0x2026,
  0x86: 0x2020,
  0x87: 0x2021,
  0x88: 0x02C6,
  0x89: 0x2030,
  0x8A: 0x0160,
  0x8B: 0x2039,
  0x8C: 0x0152,
  0x8E: 0x017D,
  0x91: 0x2018,
  0x92: 0x2019,
  0x93: 0x201C,
  0x94: 0x201D,
  0x95: 0x2022,
  0x96: 0x2013,
  0x97: 0x2014,
  0x98: 0x02DC,
  0x99: 0x2122,
  0x9A: 0x0161,
  0x9B: 0x203A,
  0x9C: 0x0153,
  0x9E: 0x017E,
  0x9F: 0x0178,
};

class _State {
  bool bold = false;
  bool italic = false;
  bool underline = false;
  bool strike = false;
  bool skip = false;

  /// Caracteres de reemplazo tras `\uN` (`\ucN`).
  int unicodeSkip = 1;

  _State copy() => _State()
    ..bold = bold
    ..italic = italic
    ..underline = underline
    ..strike = strike
    ..skip = skip
    ..unicodeSkip = unicodeSkip;

  void reset() {
    bold = italic = underline = strike = false;
  }
}

class _RtfReader {
  new(this._bytes);

  final Uint8List _bytes;
  int _pos = 0;
  final _stack = <_State>[];
  _State _state = _State();

  final _blocks = <FlowBlock>[];
  final _runs = <TextRun>[];
  final _text = StringBuffer();

  /// Caracteres de reemplazo pendientes de saltar tras `\uN`.
  int _pendingSkip = 0;

  FlowDocument read() {
    while (_pos < _bytes.length) {
      final c = _bytes[_pos];
      if (c == 0x7B) {
        // {
        _stack.add(_state);
        _state = _state.copy();
        _pos++;
        // Grupos `{\* \destino ...}` desconocidos: se ignoran.
        if (_peekIs(r'\*')) _state.skip = true;
      } else if (c == 0x7D) {
        // }
        _flushRun();
        if (_stack.isNotEmpty) _state = _stack.removeLast();
        _pos++;
      } else if (c == 0x5C) {
        // \
        _control();
      } else if (c == 0x0D || c == 0x0A) {
        _pos++;
      } else {
        _pos++;
        _emit(String.fromCharCode(c));
      }
    }
    _paragraph();
    return FlowDocument(blocks: _blocks);
  }

  bool _peekIs(String s) {
    for (var i = 0; i < s.length; i++) {
      if (_pos + i >= _bytes.length || _bytes[_pos + i] != s.codeUnitAt(i)) {
        return false;
      }
    }
    return true;
  }

  void _control() {
    _pos++; // la barra
    if (_pos >= _bytes.length) return;
    final c = _bytes[_pos];
    if (!_isLetter(c)) {
      _pos++;
      switch (c) {
        case 0x27: // \'hh
          final hex = String.fromCharCodes(
            _bytes.sublist(_pos, (_pos + 2).clamp(0, _bytes.length)),
          );
          _pos += 2;
          final code = int.tryParse(hex, radix: 16);
          if (code != null) _emit(String.fromCharCode(_cp1252[code] ?? code));
        case 0x7E: // \~ espacio duro
          _emit(' ');
        case 0x5F: // \_ guion duro
          _emit('-');
        case 0x7B || 0x7D || 0x5C: // \{ \} \\
          _emit(String.fromCharCode(c));
        case 0x0D || 0x0A: // barra + salto = \par
          _paragraph();
      }
      return;
    }
    final start = _pos;
    while (_pos < _bytes.length && _isLetter(_bytes[_pos])) {
      _pos++;
    }
    final word = String.fromCharCodes(_bytes.sublist(start, _pos));
    int? param;
    final numStart = _pos;
    if (_pos < _bytes.length && _bytes[_pos] == 0x2D) _pos++; // -
    while (_pos < _bytes.length && _isDigit(_bytes[_pos])) {
      _pos++;
    }
    if (_pos > numStart) {
      param = int.tryParse(
        String.fromCharCodes(_bytes.sublist(numStart, _pos)),
      );
    }
    // Un espacio tras la palabra de control es parte de ella.
    if (_pos < _bytes.length && _bytes[_pos] == 0x20) _pos++;
    _word(word, param);
  }

  void _word(String word, int? param) {
    if (_skipped.contains(word)) {
      _state.skip = true;
      return;
    }
    final on = param != 0;
    switch (word) {
      case 'par' || 'sect' || 'page':
        _paragraph();
      case 'line':
        _emit('\n');
      case 'tab':
        _emit('\t');
      case 'cell':
        _emit('\t');
      case 'row':
        _paragraph();
      case 'emdash':
        _emit('—');
      case 'endash':
        _emit('–');
      case 'bullet':
        _emit('•');
      case 'lquote':
        _emit('‘');
      case 'rquote':
        _emit('’');
      case 'ldblquote':
        _emit('“');
      case 'rdblquote':
        _emit('”');
      case 'b':
        _style(() => _state.bold = on);
      case 'i':
        _style(() => _state.italic = on);
      case 'ul':
        _style(() => _state.underline = on);
      case 'ulnone':
        _style(() => _state.underline = false);
      case 'strike':
        _style(() => _state.strike = on);
      case 'plain':
        _style(_state.reset);
      case 'uc':
        _state.unicodeSkip = param ?? 1;
      case 'u':
        if (param != null) {
          _emit(String.fromCharCode(param < 0 ? param + 65536 : param));
          _pendingSkip = _state.unicodeSkip;
        }
    }
  }

  void _style(void Function() change) {
    _flushRun();
    change();
  }

  void _emit(String text) {
    if (_pendingSkip > 0) {
      // El carácter de reemplazo que sigue a `\uN` no se muestra.
      _pendingSkip--;
      return;
    }
    if (_state.skip) return;
    _text.write(text);
  }

  void _flushRun() {
    if (_text.isEmpty) return;
    final run = TextRun(
      _text.toString(),
      bold: _state.bold,
      italic: _state.italic,
      underline: _state.underline,
      strike: _state.strike,
    );
    _text.clear();
    if (_runs.isNotEmpty && _runs.last.sameStyleAs(run)) {
      final last = _runs.removeLast();
      _runs.add(last.copyWithText(last.text + run.text));
    } else {
      _runs.add(run);
    }
  }

  void _paragraph() {
    if (_state.skip) return;
    _flushRun();
    final text = _runs.map((r) => r.text).join();
    if (text.trim().isNotEmpty) {
      _blocks.add(ParagraphBlock(runs: List.of(_runs)));
    }
    _runs.clear();
  }

  static bool _isLetter(int c) =>
      (c >= 0x61 && c <= 0x7A) || (c >= 0x41 && c <= 0x5A);
  static bool _isDigit(int c) => c >= 0x30 && c <= 0x39;
}
