import 'dart:async';

import 'package:doc_reader/core/theme/app_colors.dart';
import 'package:doc_reader/core/theme/app_theme.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/core/widgets/empty_state.dart';
import 'package:doc_reader/core/widgets/floating_pill.dart';
import 'package:doc_reader/features/highlights/application/highlights_controller.dart';
import 'package:doc_reader/features/highlights/domain/highlight.dart';
import 'package:doc_reader/features/highlights/presentation/annotation_actions.dart';
import 'package:doc_reader/features/highlights/presentation/annotation_toolbar.dart';
import 'package:doc_reader/features/library/application/library_controller.dart';
import 'package:doc_reader/features/library/domain/library_document.dart';
import 'package:doc_reader/features/reader/application/document_providers.dart';
import 'package:doc_reader/features/reader/formats/flow/flow_block_view.dart';
import 'package:doc_reader/features/reader/formats/flow/flow_document.dart';
import 'package:doc_reader/features/reader/presentation/widgets/reader_scaffold.dart';
import 'package:doc_reader/features/reader/presentation/widgets/reader_search_bar.dart';
import 'package:doc_reader/features/reader/presentation/widgets/reader_states.dart';
import 'package:doc_reader/features/reader/read_aloud/read_aloud_controller.dart';
import 'package:doc_reader/features/reader/search/text_search.dart';
import 'package:doc_reader/features/settings/application/settings_controller.dart';
import 'package:doc_reader/features/settings/presentation/reading_controls.dart';
import 'package:doc_reader/l10n/l10n.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lector de documentos de texto (Word, TXT, Markdown) con tipografía
/// serif, ambientes de lectura y subrayados.
class FlowReaderScreen extends ConsumerStatefulWidget {
  const new({
    required this.document,
    required this.onMore,
    super.key,
    this.initialBlock,
  });

  final LibraryDocument document;
  final VoidCallback onMore;

  /// Bloque al que saltar al abrir (p. ej. desde un subrayado).
  final int? initialBlock;

  @override
  ConsumerState<FlowReaderScreen> createState() => _FlowReaderScreenState();
}

class _FlowReaderScreenState extends ConsumerState<FlowReaderScreen> {
  final _scroll = ScrollController();
  Timer? _saveTimer;
  double _progress = 0;

  /// Estado que cambia al hacer scroll: va en notifiers para redibujar solo
  /// el porcentaje y la píldora, nunca la lista de párrafos.
  final _percent = ValueNotifier('0 %');
  final _pillVisible = ValueNotifier(true);
  bool _restored = false;
  late final LibraryController _library;

  // Selección (puede abarcar varios párrafos).
  final _selection = FlowSelectionRegistry();
  String _selectedText = '';

  // Búsqueda dentro del documento.
  final _searchText = TextEditingController();
  bool _searchOpen = false;
  Timer? _searchTimer;
  SearchIndex? _searchIndex;
  List<SearchMatch> _matches = const [];
  int _currentMatch = 0;
  Map<int, List<TextRange>> _hitsByBlock = const {};

  /// Bloque al que se quiere llegar; lleva [_targetKey] para encontrarlo.
  int? _targetBlock;
  final _targetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Se guarda aquí porque `ref` no se puede usar dentro de dispose().
    _library = ref.read(libraryControllerProvider.notifier);
    _progress = widget.document.progress;
    _percent.value = _format(_progress);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _saveNow();
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _percent.dispose();
    _searchTimer?.cancel();
    _searchText.dispose();
    _pillVisible.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scroll.position;
    if (!position.hasContentDimensions) return;
    final max = position.maxScrollExtent;
    final next = max <= 0 ? 1.0 : (position.pixels / max).clamp(0.0, 1.0);
    _progress = next;
    _percent.value = _format(next);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), _saveNow);
  }

  static String _format(double progress) => '${(progress * 100).round()} %';

  void _saveNow() {
    if (!_restored) return;
    unawaited(
      _library.saveProgress(
        widget.document.id,
        progress: _progress,
        position: _progress,
      ),
    );
  }

  /// Vuelve a la posición guardada. Como la lista es perezosa, la altura
  /// total se estima; se reajusta un par de frames hasta estabilizarse.
  void _restorePosition(int blockCount, [int attempt = 0]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final block = widget.initialBlock;
      final target = block != null && blockCount > 0
          ? (block / blockCount).clamp(0.0, 1.0)
          : widget.document.position.clamp(0.0, 1.0);
      if (target > 0) {
        _scroll.jumpTo(target * _scroll.position.maxScrollExtent);
      }
      if (attempt < 3 && target > 0) {
        _restorePosition(blockCount, attempt + 1);
      } else {
        _restored = true;
      }
    });
  }

  bool _onUserScroll(UserScrollNotification notification) {
    final visible = switch (notification.direction) {
      ScrollDirection.reverse => false,
      ScrollDirection.forward => true,
      ScrollDirection.idle => _pillVisible.value,
    };
    _pillVisible.value = visible;
    return false;
  }

  /// Lee en voz alta desde el párrafo por el que se va.
  void _toggleListen() {
    final aloud = ref.read(readAloudControllerProvider.notifier);
    if (ref.read(readAloudControllerProvider).isPlaying) {
      unawaited(aloud.stop());
      return;
    }
    final blocks = ref
        .read(flowDocumentProvider(widget.document.id))
        .value
        ?.blocks;
    if (blocks == null || blocks.isEmpty) return;
    unawaited(
      aloud.play(
        from: (_progress * blocks.length).floor().clamp(0, blocks.length - 1),
        count: blocks.length,
        source: (i) => switch (blocks[i]) {
          final ParagraphBlock p => p.plainText,
          _ => null,
        },
      ),
    );
  }

  void _openSearch() => setState(() => _searchOpen = true);

  void _closeSearch() {
    _searchTimer?.cancel();
    _searchText.clear();
    setState(() {
      _searchOpen = false;
      _matches = const [];
      _hitsByBlock = const {};
      _targetBlock = null;
    });
  }

  void _onQueryChanged(String query) {
    _searchTimer?.cancel();
    _searchTimer = Timer(
      const Duration(milliseconds: 150),
      () => _runSearch(query),
    );
  }

  void _runSearch(String query) {
    final flow = ref.read(flowDocumentProvider(widget.document.id)).value;
    if (flow == null || !mounted) return;
    final index = _searchIndex ??= SearchIndex([
      for (final block in flow.blocks)
        if (block is ParagraphBlock) block.plainText else '',
    ]);
    final matches = index.find(query);
    final hits = <int, List<TextRange>>{};
    for (final m in matches) {
      (hits[m.blockIndex] ??= []).add(TextRange(start: m.start, end: m.end));
    }
    // Empieza por el primer resultado desde donde se está leyendo.
    final here = (_progress * flow.blocks.length).floor();
    final first = matches.indexWhere((m) => m.blockIndex >= here);
    setState(() {
      _matches = matches;
      _hitsByBlock = hits;
      _currentMatch = first < 0 ? 0 : first;
    });
    if (matches.isNotEmpty) _goToMatch(flow.blocks.length);
  }

  void _step(int delta) {
    final count = ref
        .read(flowDocumentProvider(widget.document.id))
        .value
        ?.blocks
        .length;
    if (_matches.isEmpty || count == null) return;
    setState(() {
      _currentMatch = (_currentMatch + delta) % _matches.length;
    });
    _goToMatch(count);
  }

  void _goToMatch(int blockCount) {
    final block = _matches[_currentMatch].blockIndex;
    setState(() => _targetBlock = block);
    _scrollToBlock(block, blockCount);
  }

  /// Lleva [block] a la vista. La lista es perezosa: si el bloque aún no
  /// existe se salta a una posición estimada y se reintenta un frame después.
  void _scrollToBlock(int block, int blockCount, [int attempt = 0]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients || _targetBlock != block) return;
      final target = _targetKey.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(target, alignment: 0.3);
        return;
      }
      if (attempt >= 6) return;
      final position = _scroll.position;
      _scroll.jumpTo(
        (block / blockCount * position.maxScrollExtent).clamp(
          0,
          position.maxScrollExtent,
        ),
      );
      _scrollToBlock(block, blockCount, attempt + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final theme = settings.readingTheme;
    final flow = ref.watch(flowDocumentProvider(widget.document.id));
    final listening = ref.watch(
      readAloudControllerProvider.select((s) => s.isPlaying),
    );
    // Mientras se escucha, la lista acompaña al párrafo que suena.
    ref.listen(readAloudControllerProvider.select((s) => s.index), (_, index) {
      final count = flow.value?.blocks.length;
      if (index == null || count == null) return;
      setState(() => _targetBlock = index);
      _scrollToBlock(index, count);
    });

    // Con la búsqueda abierta, "atrás" la cierra en vez de salir.
    return PopScope(
      canPop: !_searchOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeSearch();
      },
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: const TextSelectionThemeData(
            selectionColor: AppColors.selection,
            selectionHandleColor: AppColors.selectionHandle,
            cursorColor: AppColors.selectionHandle,
          ),
        ),
        child: ReaderScaffold(
          title: widget.document.title,
          liveSubtitle: _percent,
          background: theme.background,
          foreground: theme.ink,
          muted: theme.muted,
          onMore: widget.onMore,
          searchBar: _searchOpen
              ? ReaderSearchBar(
                  controller: _searchText,
                  background: theme.background,
                  foreground: theme.ink,
                  muted: theme.muted,
                  current: _currentMatch,
                  total: _matches.length,
                  onChanged: _onQueryChanged,
                  onNext: () => _step(1),
                  onPrevious: () => _step(-1),
                  onClose: _closeSearch,
                )
              : null,
          pillVisible: _pillVisible,
          bottomPill: FloatingPill(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PillButton(
                  icon: Icons.search_rounded,
                  tooltip: context.l10n.readerSearch,
                  onPressed: _openSearch,
                ),
                PillButton(
                  icon: listening
                      ? Icons.stop_rounded
                      : Icons.headphones_rounded,
                  tooltip: listening
                      ? context.l10n.readerListenStop
                      : context.l10n.readerListen,
                  selected: listening,
                  onPressed: _toggleListen,
                ),
                PillButton(
                  icon: Icons.text_fields_rounded,
                  label: context.l10n.readerAppearance,
                  onPressed: () => showReadingSettingsSheet(context),
                ),
                PillButton(
                  icon: switch (theme.next.brightness) {
                    Brightness.dark => Icons.dark_mode_outlined,
                    Brightness.light => Icons.light_mode_outlined,
                  },
                  tooltip: context.l10n.readerAmbience,
                  onPressed: () => ref
                      .read(settingsControllerProvider.notifier)
                      .setReadingTheme(theme.next),
                ),
              ],
            ),
          ),
          body: switch (flow) {
            AsyncData(:final value) => _content(
              value,
              FlowReadingStyle(
                theme: theme,
                fontSize: settings.fontSize,
                lineHeight: settings.lineHeight,
              ),
            ),
            AsyncError(:final error) => ReaderError(
              error: error,
              onRetry: () =>
                  ref.invalidate(flowDocumentProvider(widget.document.id)),
            ),
            _ => ReaderLoading(color: theme.muted),
          },
        ),
      ),
    );
  }

  Widget _content(FlowDocument flow, FlowReadingStyle style) {
    if (flow.isEmpty) {
      _restored = true;
      return EmptyState(
        icon: Icons.notes_rounded,
        title: context.l10n.readerEmpty,
      );
    }
    if (!_restored) _restorePosition(flow.blocks.length);

    final highlights = ref.watch(
      documentHighlightsProvider(widget.document.id),
    );
    final annotations = AnnotationActions(
      context: context,
      ref: ref,
      documentId: widget.document.id,
      documentTitle: widget.document.title,
    );
    // Columna de lectura de ~680 px como máximo, centrada en tablets.
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width > 680 + AppSpacing.lg * 2
        ? (width - 680) / 2
        : AppSpacing.lg;

    // Una sola zona de selección para todo el documento: se puede
    // seleccionar de un párrafo a otro, como en cualquier app de Android.
    return SelectionArea(
      onSelectionChanged: (content) => _selectedText = content?.plainText ?? '',
      contextMenuBuilder: (context, state) => _toolbar(state, annotations),
      child: NotificationListener<UserScrollNotification>(
        onNotification: _onUserScroll,
        child: Scrollbar(
          controller: _scroll,
          child: ListView.builder(
            controller: _scroll,
            padding: EdgeInsets.fromLTRB(
              horizontal,
              AppSpacing.md,
              horizontal,
              AppSpacing.bottomPillClearance +
                  MediaQuery.paddingOf(context).bottom,
            ),
            itemCount: flow.blocks.length,
            itemBuilder: (context, index) {
              final block = flow.blocks[index];
              final hits = _hitsByBlock[index] ?? const <TextRange>[];
              int? currentHit;
              if (hits.isNotEmpty) {
                final current = _matches[_currentMatch];
                if (current.blockIndex == index) {
                  currentHit = hits.indexWhere((h) => h.start == current.start);
                }
              }
              return FlowBlockView(
                key: index == _targetBlock ? _targetKey : null,
                searchHits: hits,
                currentHit: currentHit,
                block: block,
                blockIndex: index,
                style: style,
                highlights: highlights[index] ?? const [],
                selection: _selection,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _toolbar(SelectableRegionState state, AnnotationActions annotations) {
    final drafts = _selection.drafts();
    final text = _selectedText.trim();
    if (drafts.isEmpty && text.isEmpty) return const SizedBox.shrink();

    void finish() {
      state
        ..hideToolbar()
        ..clearSelection();
    }

    void run(void Function() action) {
      finish();
      action();
    }

    return AnnotationToolbar(
      anchors: state.contextMenuAnchors,
      onColor: (color) =>
          run(() => annotations.mark(drafts, color, HighlightStyle.highlight)),
      onUnderline: () =>
          run(() => annotations.mark(drafts, 0, HighlightStyle.underline)),
      onNote: () => run(() => unawaited(annotations.note(drafts))),
      onCopy: () => run(() => annotations.copy(text)),
      onShare: () => run(() => annotations.share(text)),
      onRemove: annotations.touchesExisting(drafts)
          ? () => run(() => annotations.remove(drafts))
          : null,
    );
  }
}
