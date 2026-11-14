import 'dart:io';

import 'package:doc_reader/features/library/data/open_with_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('folio/open_with');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('recibe el archivo inicial y lo convierte en candidato', () async {
    final dir = await Directory.systemTemp.createTemp('open_with');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/informe.pdf')..writeAsStringSync('%PDF');
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'takeInitialFile');
      return {'path': file.path, 'name': 'informe.pdf', 'size': 4};
    });

    final incoming = await OpenWithChannel().takeInitialFile();
    expect(incoming?.name, 'informe.pdf');
    final candidate = incoming!.toCandidate();
    expect(candidate.sizeBytes, 4);
    expect(await candidate.openRead().expand((b) => b).toList(), hasLength(4));

    await incoming.discard();
    expect(file.existsSync(), isFalse);
  });

  test('sin archivo inicial devuelve null', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);
    expect(await OpenWithChannel().takeInitialFile(), isNull);
  });
}
