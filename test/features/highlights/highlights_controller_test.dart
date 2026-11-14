import 'package:doc_reader/features/highlights/application/highlights_controller.dart';
import 'package:doc_reader/features/highlights/domain/highlight.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

HighlightDraft draft(int block, int start, int end) => HighlightDraft(
  blockIndex: block,
  start: start,
  end: end,
  text: 'x' * (end - start),
);

void main() {
  late ProviderContainer container;
  late HighlightsController controller;

  setUp(() async {
    container = await createContainer();
    await container.read(highlightsControllerProvider.future);
    controller = container.read(highlightsControllerProvider.notifier);
  });

  tearDown(() => container.dispose());

  Map<int, List<Highlight>> byBlock() =>
      container.read(documentHighlightsProvider('d'));

  test('marcar sustituye marcas solapadas del mismo bloque', () async {
    await controller.mark(
      documentId: 'd',
      drafts: [draft(1, 0, 5)],
      colorIndex: 0,
    );
    await controller.mark(
      documentId: 'd',
      drafts: [draft(1, 3, 8)],
      colorIndex: 2,
      style: HighlightStyle.underline,
    );
    await controller.mark(
      documentId: 'd',
      drafts: [draft(2, 0, 3)],
      colorIndex: 1,
    );

    expect(byBlock()[1], hasLength(1));
    expect(byBlock()[1]!.single.style, HighlightStyle.underline);
    expect(byBlock()[2], hasLength(1));

    await controller.removeForDocument('d');
    expect(byBlock(), isEmpty);
  });

  test('varias páginas crean una marca por página', () async {
    await controller.mark(
      documentId: 'd',
      drafts: [draft(3, 10, 40), draft(4, 0, 12)],
      colorIndex: 1,
    );
    expect(byBlock().keys, containsAll([3, 4]));
  });

  test('la nota se añade a la marca existente o crea una nueva', () async {
    await controller.mark(
      documentId: 'd',
      drafts: [draft(0, 0, 10)],
      colorIndex: 3,
    );
    await controller.annotate(
      documentId: 'd',
      drafts: [draft(0, 2, 4)],
      note: 'Clave',
    );
    final existing = byBlock()[0]!.single;
    expect(existing.note, 'Clave');
    expect(existing.colorIndex, 3);

    await controller.annotate(
      documentId: 'd',
      drafts: [draft(5, 0, 4)],
      note: 'Otra',
    );
    expect(byBlock()[5]!.single.note, 'Otra');

    // Re-marcar conserva la nota.
    await controller.mark(
      documentId: 'd',
      drafts: [draft(0, 0, 10)],
      colorIndex: 1,
    );
    expect(byBlock()[0]!.single.note, 'Clave');

    await controller.updateNote(byBlock()[0]!.single.id, '  ');
    expect(byBlock()[0]!.single.note, isNull);
  });

  test('quitar elimina solo lo que toca la selección', () async {
    await controller.mark(
      documentId: 'd',
      drafts: [draft(0, 0, 5), draft(0, 10, 15)],
      colorIndex: 0,
    );
    await controller.removeRanges(documentId: 'd', drafts: [draft(0, 2, 3)]);
    expect(byBlock()[0]!.single.start, 10);
  });
}
