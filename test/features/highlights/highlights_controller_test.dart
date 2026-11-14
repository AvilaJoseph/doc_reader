import 'package:doc_reader/features/highlights/application/highlights_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  test('añadir sustituye subrayados solapados del mismo bloque', () async {
    final container = await createContainer();
    addTearDown(container.dispose);
    await container.read(highlightsControllerProvider.future);
    final controller = container.read(highlightsControllerProvider.notifier);

    await controller.add(
      documentId: 'd',
      blockIndex: 1,
      start: 0,
      end: 5,
      colorIndex: 0,
      text: 'Hola ',
    );
    await controller.add(
      documentId: 'd',
      blockIndex: 1,
      start: 3,
      end: 8,
      colorIndex: 2,
      text: 'a mun',
    );
    await controller.add(
      documentId: 'd',
      blockIndex: 2,
      start: 0,
      end: 3,
      colorIndex: 1,
      text: 'Otro',
    );

    final byBlock = container.read(documentHighlightsProvider('d'));
    expect(byBlock[1], hasLength(1));
    expect(byBlock[1]!.single.colorIndex, 2);
    expect(byBlock[2], hasLength(1));

    await controller.removeForDocument('d');
    expect(container.read(documentHighlightsProvider('d')), isEmpty);
  });
}
