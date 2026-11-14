import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Voz del sistema. Es una interfaz para poder probar sin plataforma.
abstract interface class SpeechEngine {
  /// Lee [text] y termina cuando acaba de hablar (o se detiene).
  Future<void> speak(String text);

  Future<void> stop();
}

/// Motor de Android/iOS: usa las voces instaladas en el teléfono, que
/// funcionan sin conexión.
class SystemSpeechEngine implements SpeechEngine {
  new() : _tts = FlutterTts() {
    unawaited(_tts.awaitSpeakCompletion(true));
  }

  /// Android no acepta textos muy largos de una vez (~4000 caracteres).
  static const int maxChunk = 3000;

  final FlutterTts _tts;
  late final Future<void> _ready;

  @override
  Future<void> speak(String text) async {
    await _ready;
    for (final part in splitForSpeech(text, maxChunk)) {
      await _tts.speak(part);
    }
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}

/// Parte [text] en trozos de como mucho [max] caracteres, cortando
/// preferentemente tras un punto o, si no, en un espacio.
@visibleForTesting
List<String> splitForSpeech(String text, int max) {
  final parts = <String>[];
  var rest = text.trim();
  while (rest.length > max) {
    var cut = rest.lastIndexOf(RegExp(r'[.!?;:]\s'), max);
    if (cut <= 0) cut = rest.lastIndexOf(' ', max);
    if (cut <= 0) cut = max - 1;
    parts.add(rest.substring(0, cut + 1).trim());
    rest = rest.substring(cut + 1).trim();
  }
  if (rest.isNotEmpty) parts.add(rest);
  return parts;
}
