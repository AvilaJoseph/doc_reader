import 'dart:async';

import 'package:doc_reader/features/reader/read_aloud/read_aloud_controller.dart';
import 'package:doc_reader/features/reader/read_aloud/speech_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEngine implements SpeechEngine {
  final spoken = <String>[];
  Completer<void>? current;

  @override
  Future<void> speak(String text) {
    spoken.add(text);
    current = Completer<void>();
    return current!.future;
  }

  @override
  Future<void> stop() async {
    if (current case final c? when !c.isCompleted) c.complete();
  }

  void finish() => current?.complete();
}

void main() {
  test('lee fragmento a fragmento y salta los vacíos', () async {
    final engine = _FakeEngine();
    final container = ProviderContainer(
      overrides: [speechEngineProvider.overrideWithValue(engine)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(readAloudControllerProvider, (_, _) {});
    addTearDown(sub.close);
    final texts = ['Uno', '', 'Tres'];

    final playing = container
        .read(readAloudControllerProvider.notifier)
        .play(from: 0, count: texts.length, source: (i) => texts[i]);
    await pumpEventQueue();
    expect(container.read(readAloudControllerProvider).index, 0);

    engine.finish();
    await pumpEventQueue();
    expect(container.read(readAloudControllerProvider).index, 2);
    engine.finish();
    await playing;

    expect(engine.spoken, ['Uno', 'Tres']);
    expect(container.read(readAloudControllerProvider).isPlaying, isFalse);
  });

  test('detener corta la lectura', () async {
    final engine = _FakeEngine();
    final container = ProviderContainer(
      overrides: [speechEngineProvider.overrideWithValue(engine)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(readAloudControllerProvider, (_, _) {});
    addTearDown(sub.close);
    final controller = container.read(readAloudControllerProvider.notifier);

    final playing = controller.play(
      from: 0,
      count: 3,
      source: (i) => 'Frase $i',
    );
    await pumpEventQueue();
    await controller.stop();
    await playing;

    expect(engine.spoken, ['Frase 0']);
    expect(container.read(readAloudControllerProvider).isPlaying, isFalse);
  });

  test('parte textos largos por frases', () {
    final parts = splitForSpeech('Hola mundo. Adiós mundo. Fin.', 15);
    expect(parts, ['Hola mundo.', 'Adiós mundo.', 'Fin.']);
    expect(parts.every((p) => p.length <= 15), isTrue);
  });
}
