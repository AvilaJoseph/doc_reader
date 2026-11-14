import 'dart:async';

import 'package:doc_reader/features/reader/read_aloud/speech_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final speechEngineProvider = Provider<SpeechEngine>(
  (ref) => SystemSpeechEngine(),
);

/// Estado de "Escuchar": qué fragmento se está leyendo (o null si nada).
@immutable
class ReadAloudState {
  const new({this.index});

  /// Bloque (texto) o página (PDF) que suena ahora.
  final int? index;

  bool get isPlaying => index != null;

  @override
  bool operator ==(Object other) =>
      other is ReadAloudState && other.index == index;

  @override
  int get hashCode => index.hashCode;
}

/// Carga el texto del fragmento [index] (puede ser asíncrono, p. ej. PDF).
typedef SpeechSource = FutureOr<String?> Function(int index);

final readAloudControllerProvider =
    NotifierProvider.autoDispose<ReadAloudController, ReadAloudState>(
      ReadAloudController.new,
    );

/// Lee en voz alta fragmento a fragmento desde donde se está leyendo.
class ReadAloudController extends Notifier<ReadAloudState> {
  /// Cambia en cada play/stop para que una lectura vieja no siga.
  int _run = 0;

  @override
  ReadAloudState build() {
    final engine = ref.watch(speechEngineProvider);
    ref.onDispose(() {
      _run++;
      unawaited(engine.stop());
    });
    return const ReadAloudState();
  }

  /// Empieza en [from] y sigue hasta [count] o hasta que se detenga.
  Future<void> play({
    required int from,
    required int count,
    required SpeechSource source,
  }) async {
    final run = ++_run;
    final engine = ref.read(speechEngineProvider);
    await engine.stop();
    for (var i = from; i < count; i++) {
      if (run != _run) return;
      final text = (await source(i))?.trim() ?? '';
      if (run != _run) return;
      if (text.isEmpty) continue;
      state = ReadAloudState(index: i);
      try {
        await engine.speak(text);
      } on Object {
        // Sin voces instaladas o motor no disponible: se detiene sin más.
        if (run == _run) state = const ReadAloudState();
        return;
      }
    }
    if (run == _run) state = const ReadAloudState();
  }

  Future<void> stop() async {
    _run++;
    state = const ReadAloudState();
    await ref.read(speechEngineProvider).stop();
  }
}
