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

  /// Marca uno o varios fragmentos (uno por bloque o página). Las marcas
  /// que se solapan en el mismo bloque se sustituyen, conservando su nota.
  Future<List<Highlight>> mark({
    required String documentId,
    required List<HighlightDraft> drafts,
    required int colorIndex,
    HighlightStyle style = HighlightStyle.highlight,
  }) async {
    var next = [..._current];
    final created = <Highlight>[];
    for (final draft in drafts) {
      final overlapped = _overlapping(next, documentId, draft);
      final highlight = Highlight(
        id: _uuid.v4(),
        documentId: documentId,
        blockIndex: draft.blockIndex,
        start: draft.start,
        end: draft.end,
        colorIndex: colorIndex,
        text: draft.text,
        createdAt: DateTime.now(),
        style: style,
        note: overlapped.map((h) => h.note).nonNulls.firstOrNull,
        rects: draft.rects,
      );
      next = [...next.where((h) => !overlapped.contains(h)), highlight];
      created.add(highlight);
    }
    await _commit(next);
    return created;
  }

  /// Añade una nota. Si el fragmento ya estaba marcado, la nota se guarda
  /// en esa marca; si no, se crea un resaltado con el primer color.
  Future<void> annotate({
    required String documentId,
    required List<HighlightDraft> drafts,
    required String note,
  }) async {
    var next = [..._current];
    for (final draft in drafts) {
      final existing = _overlapping(next, documentId, draft).firstOrNull;
      if (existing != null) {
        next = [
          for (final h in next)
            if (h.id == existing.id) h.copyWith(note: note) else h,
        ];
      } else {
        next = [
          ...next,
          Highlight(
            id: _uuid.v4(),
            documentId: documentId,
            blockIndex: draft.blockIndex,
            start: draft.start,
            end: draft.end,
            colorIndex: 0,
            text: draft.text,
            createdAt: DateTime.now(),
            note: note,
            rects: draft.rects,
          ),
        ];
      }
    }
    await _commit(next);
  }

  /// Cambia o borra (texto vacío) la nota de una marca.
  Future<void> updateNote(String id, String note) => _commit([
    for (final h in _current)
      if (h.id == id)
        h.copyWith(note: note.trim(), clearNote: note.trim().isEmpty)
      else
        h,
  ]);

  /// Quita las marcas que tocan los fragmentos indicados.
  Future<void> removeRanges({
    required String documentId,
    required List<HighlightDraft> drafts,
  }) {
    final doomed = {
      for (final d in drafts) ..._overlapping(_current, documentId, d),
    };
    return _commit([
      for (final h in _current)
        if (!doomed.contains(h)) h,
    ]);
  }

  /// Marcas existentes que se solapan con [draft].
  List<Highlight> overlapping(String documentId, HighlightDraft draft) =>
      _overlapping(_current, documentId, draft);

  static List<Highlight> _overlapping(
    List<Highlight> list,
    String documentId,
    HighlightDraft draft,
  ) => [
    for (final h in list)
      if (h.documentId == documentId &&
          h.blockIndex == draft.blockIndex &&
          h.overlaps(draft.start, draft.end))
        h,
  ];

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
