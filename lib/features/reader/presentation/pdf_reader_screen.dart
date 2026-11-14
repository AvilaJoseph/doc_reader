import 'dart:async';

import 'package:doc_reader/core/theme/app_colors.dart';
import 'package:doc_reader/core/theme/reading_theme.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/core/widgets/floating_pill.dart';
import 'package:doc_reader/core/widgets/selection_handle.dart';
import 'package:doc_reader/features/highlights/application/highlights_controller.dart';
import 'package:doc_reader/features/highlights/domain/highlight.dart';
import 'package:doc_reader/features/highlights/presentation/annotation_actions.dart';
import 'package:doc_reader/features/highlights/presentation/annotation_toolbar.dart';
import 'package:doc_reader/features/library/application/library_controller.dart';
import 'package:doc_reader/features/library/domain/document_source.dart';
import 'package:doc_reader/features/library/domain/library_document.dart';
import 'package:doc_reader/features/reader/application/document_providers.dart';
import 'package:doc_reader/features/reader/formats/pdf/pdf_night_filter.dart';
import 'package:doc_reader/features/reader/formats/pdf/pdf_text_lines.dart';
import 'package:doc_reader/features/reader/presentation/widgets/pdf_navigator_sheet.dart';
import 'package:doc_reader/features/reader/presentation/widgets/reader_scaffold.dart';
import 'package:doc_reader/features/reader/presentation/widgets/reader_search_bar.dart';
import 'package:doc_reader/features/reader/presentation/widgets/reader_states.dart';
import 'package:doc_reader/features/reader/presentation/widgets/reader_top_bar.dart';
import 'package:doc_reader/features/reader/search/text_search.dart';
import 'package:doc_reader/features/settings/application/settings_controller.dart';
import 'package:doc_reader/l10n/l10n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

/// Visor de PDF basado en pdfrx (PDFium): rápido, con zoom, selección de
/// texto, resaltados, subrayados y notas, sin servicios externos.
class PdfReaderScreen extends ConsumerStatefulWidget {
  const new({
    required this.document,
    required this.onMore,
    required this.library,
    super.key,
    this.initialPage,
  });

  final LibraryDocument document;
  final VoidCallback onMore;
  final LibraryController library;

  /// Página a abrir (p. ej. al venir de un subrayado); si no, la guardada.
  final int? initialPage;

  @override
  ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen> {
  final _controller = PdfViewerController();
  Timer? _saveTimer;
  int _page = 1;

  /// Página actual para la barra y la píldora: cambiarla no reconstruye
  /// el visor, solo esos dos textos.
  late final _pageNotifier = ValueNotifier(_page);
  int _pageCount = 0;

  /// Marcas del documento por página (se actualiza en cada build).
  Map<int, List<Highlight>> _highlights = const {};

  /// Modo noche: páginas invertidas y fondo oscuro.
  bool _night = false;

  /// Fragmentos de la selección actual, calculados al cambiar la selección.
  List<HighlightDraft> _selection = const [];

  @override
  void initState() {
    super.initState();
    _page = (widget.initialPage ?? widget.document.position.round()).clamp(
      1,
      1 << 20,
    );
  }

  AnnotationActions get _annotations => AnnotationActions(
    context: context,
    ref: ref,
    documentId: widget.document.id,
    documentTitle: widget.document.title,
  );

  /// Convierte la selección de pdfrx en fragmentos (uno por página).
  Future<List<HighlightDraft>> _draftsFrom(PdfTextSelection selection) async {
    if (!selection.hasSelectedText) return const [];
    final ranges = await selection.getSelectedTextRanges();
    return [
      for (final range in ranges)
        if (range.end > range.start)
          HighlightDraft(
            blockIndex: range.pageNumber,
            start: range.start,
            end: range.end,
            text: range.text.trim(),
            rects: mergeCharRectsIntoLines([
              for (final r in range.pageText.charRects.sublist(
                range.start,
                range.end,
              ))
                HighlightRect(r.left, r.top, r.right, r.bottom),
            ]),
          ),
    ];
  }

  void _onSelectionChanged(PdfTextSelection selection) {
    unawaited(
      _draftsFrom(selection).then((drafts) {
        if (mounted) _selection = drafts;
      }),
    );
  }

  /// Ejecuta [action] con la selección actual y la limpia después.
  void _withSelection(
    PdfViewerContextMenuBuilderParams params,
    FutureOr<void> Function(List<HighlightDraft> drafts) action, {
    bool clear = true,
  }) {
    params.dismissContextMenu();
    unawaited(() async {
      final drafts = await _draftsFrom(params.textSelectionDelegate);
      if (clear) await params.textSelectionDelegate.clearTextSelection();
      if (drafts.isNotEmpty) await action(drafts);
    }());
  }

  Widget? _buildContextMenu(
    BuildContext context,
    PdfViewerContextMenuBuilderParams params,
  ) {
    final delegate = params.textSelectionDelegate;
    if (!params.isTextSelectionEnabled || !delegate.hasSelectedText) {
      return null;
    }
    final annotations = _annotations;
    String joined(List<HighlightDraft> d) => d.map((e) => e.text).join(' ');
    return Align(
      alignment: Alignment.topLeft,
      child: AnnotationToolbar(
        anchors: TextSelectionToolbarAnchors(
          primaryAnchor: params.anchorA,
          secondaryAnchor: params.anchorB,
        ),
        onColor: (color) => _withSelection(
          params,
          (d) => annotations.mark(d, color, HighlightStyle.highlight),
        ),
        onUnderline: () => _withSelection(
          params,
          (d) => annotations.mark(d, 0, HighlightStyle.underline),
        ),
        onNote: () => _withSelection(params, annotations.note),
        onCopy: () =>
            _withSelection(params, (d) => annotations.copy(joined(d))),
        onShare: () =>
            _withSelection(params, (d) => annotations.share(joined(d))),
        onRemove: annotations.touchesExisting(_selection)
            ? () => _withSelection(params, annotations.remove)
            : null,
      ),
    );
  }

  /// Asas finas tipo Android en lugar de los triángulos de pdfrx.
  Widget _buildSelectionHandle(
    BuildContext context,
    PdfTextSelectionAnchor anchor,
    PdfViewerTextSelectionAnchorHandleState state,
  ) => SelectionHandle(isStart: anchor.type == PdfTextSelectionAnchorType.a);

  /// pdfrx coloca el asa de inicio encima del texto; la bajamos para que
  /// su punta toque la esquina inferior izquierda de la primera letra.
  Offset _selectionHandleOffset(
    BuildContext context,
    PdfTextSelectionAnchor anchor,
    PdfViewerTextSelectionAnchorHandleState state,
  ) {
    if (anchor.type != PdfTextSelectionAnchorType.a) return Offset.zero;
    final height = anchor.rect.height.abs() * _controller.currentZoom;
    return Offset(0, height + SelectionHandle.size);
  }

  List<Widget> _buildPageOverlays(
    BuildContext context,
    Rect pageRect,
    PdfPage page,
  ) {
    final marks = _highlights[page.pageNumber];
    if (marks == null || marks.isEmpty) return const [];
    final size = pageRect.size;
    final scale = size.height / page.height;
    return [
      Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: _PdfHighlightPainter(
              marks: [
                for (final h in marks)
                  for (final r in h.rects)
                    (
                      PdfRect(
                        r.left,
                        r.top,
                        r.right,
                        r.bottom,
                      ).toRect(page: page, scaledPageSize: size),
                      h,
                    ),
              ],
              strokeWidth: (1.6 * scale).clamp(1.2, 3.5),
              night: _night,
            ),
          ),
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _save();
    _pageNotifier.dispose();
    _searcher.dispose();
    _searchText.dispose();
    super.dispose();
  }

  void _onPageChanged(int? page) {
    if (page == null || page == _page) return;
    _page = page;
    _pageNotifier.value = page;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), _save);
  }

  void _save() {
    if (_pageCount == 0) return;
    unawaited(
      widget.library.saveProgress(
        widget.document.id,
        progress: _pageCount <= 1 ? 1 : (_page - 1) / (_pageCount - 1),
        position: _page.toDouble(),
      ),
    );
  }

  late final int _initialPage = _page;

  // Búsqueda: pdfrx recorre las páginas en segundo plano y pinta los
  // resultados; aquí solo se maneja la barra.
  late final _searcher = PdfTextSearcher(_controller);
  late final List<PdfViewerPagePaintCallback> _paintCallbacks = [
    _searcher.pageTextMatchPaintCallback,
  ];
  final _searchText = TextEditingController();
  bool _searchOpen = false;

  void _openSearch() => setState(() => _searchOpen = true);

  void _closeSearch() {
    _searcher.resetTextSearch();
    _searchText.clear();
    setState(() => _searchOpen = false);
  }

  void _onQueryChanged(String query) {
    if (query.trim().isEmpty) {
      _searcher.resetTextSearch();
      return;
    }
    _searcher.startTextSearch(
      accentInsensitivePattern(query),
      startPageNumber: _page,
    );
  }

  Future<void> _goTo(int page) async {
    if (!_controller.isReady || _pageCount == 0) return;
    await _controller.goToPage(pageNumber: page.clamp(1, _pageCount));
  }

  /// Páginas marcadas del documento (se actualiza en cada build).
  List<int> _bookmarks = const [];

  void _toggleBookmark() {
    unawaited(HapticFeedback.selectionClick());
    unawaited(widget.library.toggleBookmark(widget.document.id, _page));
  }

  /// Hoja de navegación: número de página, miniaturas e índice.
  Future<void> _openNavigator() async {
    if (!_controller.isReady) return;
    final target = await showPdfNavigator(
      context,
      document: _controller.document,
      currentPage: _page,
      bookmarks: _bookmarks,
      pageFilter: _night ? pdfNightFilter : null,
    );
    if (target == null || !mounted) return;
    if (target.dest case final dest?) {
      await _controller.goToDest(dest);
    } else if (target.page case final page?) {
      await _goTo(page);
    }
  }

  @override
  Widget build(BuildContext context) {
    _highlights = ref.watch(documentHighlightsProvider(widget.document.id));
    _bookmarks = ref.watch(
      libraryDocumentProvider(widget.document.id)
          .select((doc) => doc?.bookmarks ?? const <int>[]),
    );
    _night = ref.watch(
      settingsControllerProvider.select((s) => s.pdfNightMode),
    );
    final scheme = Theme.of(context).colorScheme;
    const night = ReadingTheme.night;
    final background = _night ? night.background : scheme.surfaceContainerHigh;
    final foreground = _night ? night.ink : scheme.onSurface;
    final muted = _night ? night.muted : scheme.onSurfaceVariant;
    final params = PdfViewerParams(
      textSelectionParams: PdfTextSelectionParams(
        onTextSelectionChange: _onSelectionChanged,
        buildSelectionHandle: _buildSelectionHandle,
        calcSelectionHandleOffset: _selectionHandleOffset,
      ),
      buildContextMenu: _buildContextMenu,
      pageOverlaysBuilder: _buildPageOverlays,
      pagePaintCallbacks: _paintCallbacks,
      matchTextColor: AppColors.searchMatch,
      activeMatchTextColor: AppColors.searchCurrent,
      backgroundColor: background,
      pageImageColorFilter: _night ? pdfNightFilter : null,
      margin: 10,
      pageDropShadow: BoxShadow(
        color: Colors.black.withValues(alpha: 0.12),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
      onViewerReady: (document, controller) {
        setState(() => _pageCount = document.pages.length);
      },
      onPageChanged: _onPageChanged,
      loadingBannerBuilder: (context, _, _) => ReaderLoading(color: muted),
      errorBannerBuilder: (context, error, _, _) => ReaderError(error: error),
    );
    final initialPage = _initialPage;

    final viewer = switch (widget.document.source) {
      FileSource(:final path) => PdfViewer.file(
        path,
        controller: _controller,
        params: params,
        initialPageNumber: initialPage,
      ),
      AssetSource(:final assetPath) => PdfViewer.asset(
        assetPath,
        controller: _controller,
        params: params,
        initialPageNumber: initialPage,
      ),
    };

    // Con la búsqueda abierta, "atrás" la cierra en vez de salir.
    return PopScope(
      canPop: !_searchOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeSearch();
      },
      child: ReaderScaffold(
        title: widget.document.title,
        searchBar: !_searchOpen
            ? null
            : ListenableBuilder(
                listenable: _searcher,
                builder: (context, _) => ReaderSearchBar(
                  controller: _searchText,
                  background: background,
                  foreground: foreground,
                  muted: muted,
                  current: _searcher.currentIndex,
                  total: _searcher.matches.length,
                  searching: _searcher.isSearching,
                  onChanged: _onQueryChanged,
                  onNext: () => unawaited(_searcher.goToNextMatch()),
                  onPrevious: () => unawaited(_searcher.goToPrevMatch()),
                  onClose: _closeSearch,
                ),
              ),
        liveSubtitle: _pageCount == 0 ? null : _pageLabel,
        background: background,
        foreground: foreground,
        muted: muted,
        onMore: widget.onMore,
        actions: [
          ReaderBarAction(
            icon: _night ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            tooltip: _night
                ? context.l10n.readerDayMode
                : context.l10n.readerNightMode,
            active: _night,
            onPressed: () => ref
                .read(settingsControllerProvider.notifier)
                .setPdfNightMode(enabled: !_night),
          ),
        ],
        body: viewer,
        bottomPill: _pageCount == 0
            ? null
            : ValueListenableBuilder<int>(
                valueListenable: _pageNotifier,
                builder: (context, _, _) => _pagePill(context),
              ),
      ),
    );
  }

  /// Etiqueta "N de M" derivada de [_pageNotifier].
  late final ValueListenable<String> _pageLabel = _MappedListenable(
    _pageNotifier,
    (page) => context.l10n.readerPageOf(page, _pageCount),
  );

  Widget _pagePill(BuildContext context) {
    return FloatingPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PillButton(
            icon: Icons.search_rounded,
            tooltip: context.l10n.readerSearch,
            onPressed: _openSearch,
          ),
          PillButton(
            icon: Icons.chevron_left_rounded,
            tooltip: MaterialLocalizations.of(context).previousPageTooltip,
            onPressed: _page > 1 ? () => _goTo(_page - 1) : null,
          ),
          PillButton(
            icon: Icons.menu_book_outlined,
            label: context.l10n.readerPageOf(_page, _pageCount),
            tooltip: context.l10n.readerNavigate,
            selected: true,
            onPressed: _openNavigator,
          ),
          PillButton(
            icon: Icons.chevron_right_rounded,
            tooltip: MaterialLocalizations.of(context).nextPageTooltip,
            onPressed: _page < _pageCount ? () => _goTo(_page + 1) : null,
          ),
          if (_bookmarks.contains(_page))
            PillButton(
              icon: Icons.bookmark_rounded,
              tooltip: context.l10n.readerBookmarkRemove,
              onPressed: _toggleBookmark,
            )
          else
            PillButton(
              icon: Icons.bookmark_border_rounded,
              tooltip: context.l10n.readerBookmarkAdd,
              onPressed: _toggleBookmark,
            ),
        ],
      ),
    );
  }
}

/// Transforma un [ValueListenable] sin crear estado extra.
class _MappedListenable<T, R> implements ValueListenable<R> {
  new(this._source, this._map);

  final ValueListenable<T> _source;
  final R Function(T value) _map;

  @override
  R get value => _map(_source.value);

  @override
  void addListener(VoidCallback listener) => _source.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _source.removeListener(listener);
}

/// Pinta resaltados (fondo multiplicado) y subrayados (línea) en una página.
class _PdfHighlightPainter extends CustomPainter {
  new({required this.marks, required this.strokeWidth, required this.night});

  final List<(Rect, Highlight)> marks;
  final double strokeWidth;

  /// Sobre páginas oscuras multiplicar no se vería: se pinta translúcido.
  final bool night;

  @override
  void paint(Canvas canvas, Size size) {
    for (final (rect, h) in marks) {
      if (h.style == HighlightStyle.underline) {
        final paint = Paint()
          ..color = night ? AppColors.underlineNight : AppColors.underline
          ..strokeWidth = strokeWidth;
        final y = rect.bottom + strokeWidth / 2;
        canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
      } else {
        final color =
            AppColors.highlights[h.colorIndex % AppColors.highlights.length];
        final paint = Paint()
          ..color = color.withValues(alpha: night ? 0.45 : 0.8)
          ..blendMode = night ? BlendMode.srcOver : BlendMode.multiply;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.inflate(1), const Radius.circular(2)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PdfHighlightPainter oldDelegate) =>
      oldDelegate.marks != marks ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.night != night;
}
