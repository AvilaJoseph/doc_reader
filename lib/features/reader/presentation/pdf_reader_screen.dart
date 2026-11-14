import 'dart:async';

import 'package:doc_reader/core/theme/app_colors.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/core/widgets/floating_pill.dart';
import 'package:doc_reader/features/highlights/application/highlights_controller.dart';
import 'package:doc_reader/features/highlights/domain/highlight.dart';
import 'package:doc_reader/features/highlights/presentation/annotation_actions.dart';
import 'package:doc_reader/features/highlights/presentation/annotation_toolbar.dart';
import 'package:doc_reader/features/library/application/library_controller.dart';
import 'package:doc_reader/features/library/domain/document_source.dart';
import 'package:doc_reader/features/library/domain/library_document.dart';
import 'package:doc_reader/features/reader/formats/pdf/pdf_text_lines.dart';
import 'package:doc_reader/features/reader/presentation/widgets/reader_scaffold.dart';
import 'package:doc_reader/features/reader/presentation/widgets/reader_states.dart';
import 'package:doc_reader/l10n/l10n.dart';
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
  int _pageCount = 0;

  /// Marcas del documento por página (se actualiza en cada build).
  Map<int, List<Highlight>> _highlights = const {};

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
    super.dispose();
  }

  void _onPageChanged(int? page) {
    if (page == null || page == _page) return;
    setState(() => _page = page);
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

  Future<void> _goTo(int page) async {
    if (!_controller.isReady || _pageCount == 0) return;
    await _controller.goToPage(pageNumber: page.clamp(1, _pageCount));
  }

  Future<void> _askPage() async {
    final page = await showDialog<int>(
      context: context,
      builder: (context) => _GoToPageDialog(max: _pageCount),
    );
    if (page != null) await _goTo(page);
  }

  @override
  Widget build(BuildContext context) {
    _highlights = ref.watch(documentHighlightsProvider(widget.document.id));
    final scheme = Theme.of(context).colorScheme;
    final background = scheme.surfaceContainerHigh;
    final params = PdfViewerParams(
      textSelectionParams: PdfTextSelectionParams(
        onTextSelectionChange: _onSelectionChanged,
      ),
      buildContextMenu: _buildContextMenu,
      pageOverlaysBuilder: _buildPageOverlays,
      backgroundColor: background,
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
      loadingBannerBuilder: (context, _, _) =>
          ReaderLoading(color: scheme.onSurfaceVariant),
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

    return ReaderScaffold(
      title: widget.document.title,
      subtitle: _pageCount == 0
          ? null
          : context.l10n.readerPageOf(_page, _pageCount),
      background: background,
      foreground: scheme.onSurface,
      muted: scheme.onSurfaceVariant,
      onMore: widget.onMore,
      body: viewer,
      bottomPill: _pageCount == 0
          ? null
          : FloatingPill(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PillButton(
                    icon: Icons.chevron_left_rounded,
                    tooltip: MaterialLocalizations.of(context)
                        .previousPageTooltip,
                    onPressed: _page > 1 ? () => _goTo(_page - 1) : null,
                  ),
                  PillButton(
                    icon: Icons.menu_book_outlined,
                    label: context.l10n.readerPageOf(_page, _pageCount),
                    tooltip: context.l10n.readerGoToPage,
                    selected: true,
                    onPressed: _askPage,
                  ),
                  PillButton(
                    icon: Icons.chevron_right_rounded,
                    tooltip: MaterialLocalizations.of(context).nextPageTooltip,
                    onPressed: _page < _pageCount
                        ? () => _goTo(_page + 1)
                        : null,
                  ),
                ],
              ),
            ),
    );
  }
}

class _GoToPageDialog extends StatefulWidget {
  const new({required this.max});

  final int max;

  @override
  State<_GoToPageDialog> createState() => _GoToPageDialogState();
}

class _GoToPageDialogState extends State<_GoToPageDialog> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final page = int.tryParse(_text.text);
    Navigator.of(context).pop(page);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.readerGoToPage),
      content: TextField(
        controller: _text,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          hintText: '1 – ${widget.max}',
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.readerGo)),
      ],
    );
  }
}

/// Pinta resaltados (fondo multiplicado) y subrayados (línea) en una página.
class _PdfHighlightPainter extends CustomPainter {
  new({required this.marks, required this.strokeWidth});

  final List<(Rect, Highlight)> marks;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    for (final (rect, h) in marks) {
      if (h.style == HighlightStyle.underline) {
        final paint = Paint()
          ..color = AppColors.underline
          ..strokeWidth = strokeWidth;
        final y = rect.bottom + strokeWidth / 2;
        canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
      } else {
        final color =
            AppColors.highlights[h.colorIndex % AppColors.highlights.length];
        final paint = Paint()
          ..color = color.withValues(alpha: 0.8)
          ..blendMode = BlendMode.multiply;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.inflate(1), const Radius.circular(2)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PdfHighlightPainter oldDelegate) =>
      oldDelegate.marks != marks || oldDelegate.strokeWidth != strokeWidth;
}
