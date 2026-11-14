import 'package:doc_reader/core/storage/preferences.dart';
import 'package:doc_reader/features/highlights/data/highlights_repository.dart';
import 'package:doc_reader/features/highlights/domain/highlight.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final highlightsRepositoryProvider = Provider<HighlightsRepository>(
  (ref) => PrefsHighlightsRepository(ref.watch(sharedPreferencesProvider)),
);

final highlightsControllerProvider =
    AsyncNotifierProvider<HighlightsController, List<Highlight>>(
      HighlightsController.new,
    );

/// Subrayados de un documento concreto, agrupados por bloque.
final documentHighlightsProvider =
    Provider.family<Map<int, List<Highlight>>, String>((ref, documentId) {
      final all = ref.watch(highlightsControllerProvider).value ?? const [];
      final byBlock = <int, List<Highlight>>{};
      for (final h in all) {
        if (h.documentId != documentId) continue;
        (byBlock[h.blockIndex] ??= []).add(h);
      }
      return byBlock;
    });

class HighlightsController extends AsyncNotifier<List<Highlight>> {
  static const _uuid = Uuid();

  @override
  Future<List<Highlight>> build() =>
      ref.read(highlightsRepositoryProvider).loadAll();

  List<Highlight> get _current => state.value ?? const [];

  /// Crea un subrayado. Los que se solapan en el mismo bloque se
  /// sustituyen, para no apilar colores.
  Future<Highlight> add({
    required String documentId,
    required int blockIndex,
    required int start,
    required int end,
    required int colorIndex,
    required String text,
  }) async {
    final highlight = Highlight(
      id: _uuid.v4(),
      documentId: documentId,
      blockIndex: blockIndex,
      start: start,
      end: end,
      colorIndex: colorIndex,
      text: text,
      createdAt: DateTime.now(),
    );
    final kept = _current.where(
      (h) =>
          !(h.documentId == documentId &&
              h.blockIndex == blockIndex &&
              h.overlaps(start, end)),
    );
    await _commit([...kept, highlight]);
    return highlight;
  }

  /// Quita los subrayados que tocan el rango indicado.
  Future<void> removeRange({
    required String documentId,
    required int blockIndex,
    required int start,
    required int end,
  }) => _commit([
    for (final h in _current)
      if (!(h.documentId == documentId &&
          h.blockIndex == blockIndex &&
          h.overlaps(start, end)))
        h,
  ]);

  Future<void> remove(String id) => _commit([
    for (final h in _current)
      if (h.id != id) h,
  ]);

  Future<void> restore(Highlight highlight) =>
      _commit([..._current, highlight]);

  Future<void> removeForDocument(String documentId) => _commit([
    for (final h in _current)
      if (h.documentId != documentId) h,
  ]);

  Future<void> _commit(List<Highlight> next) async {
    state = AsyncData(next);
    await ref.read(highlightsRepositoryProvider).saveAll(next);
  }
}
