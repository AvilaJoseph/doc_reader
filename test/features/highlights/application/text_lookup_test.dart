import 'package:doc_reader/features/highlights/application/text_lookup.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeService implements ProcessTextService {
  const new(this.actions);

  final List<ProcessTextAction>? actions;

  @override
  Future<List<ProcessTextAction>> queryTextActions() async =>
      actions ?? (throw MissingPluginException());

  @override
  Future<String?> processTextAction(
    String id,
    String text,
    bool readOnly,
  ) async => null;
}

ProviderContainer _container(List<ProcessTextAction>? actions) {
  final container = ProviderContainer(
    overrides: [
      processTextServiceProvider.overrideWithValue(_FakeService(actions)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('lista las apps del sistema para traducir o definir', () async {
    final container = _container(const [
      ProcessTextAction('translate', 'Traducir'),
    ]);
    final actions = await container.read(textLookupActionsProvider.future);
    expect(actions.map((a) => a.label), ['Traducir']);
  });

  test('sin soporte de la plataforma queda vacía', () async {
    final container = _container(null);
    expect(await container.read(textLookupActionsProvider.future), isEmpty);
  });
}
