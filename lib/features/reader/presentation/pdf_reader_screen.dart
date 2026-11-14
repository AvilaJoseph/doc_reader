import 'dart:async';

import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/core/widgets/floating_pill.dart';
import 'package:doc_reader/features/library/application/library_controller.dart';
import 'package:doc_reader/features/library/domain/document_source.dart';
import 'package:doc_reader/features/library/domain/library_document.dart';
import 'package:doc_reader/features/reader/presentation/widgets/reader_scaffold.dart';
import 'package:doc_reader/features/reader/presentation/widgets/reader_states.dart';
import 'package:doc_reader/l10n/l10n.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

/// Visor de PDF basado en pdfrx (PDFium): rápido, con zoom, selección de
/// texto y sin servicios externos.
class PdfReaderScreen extends StatefulWidget {
  const new({
    required this.document,
    required this.onMore,
    required this.library,
    super.key,
  });

  final LibraryDocument document;
  final VoidCallback onMore;
  final LibraryController library;

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final _controller = PdfViewerController();
  Timer? _saveTimer;
  int _page = 1;
  int _pageCount = 0;

  @override
  void initState() {
    super.initState();
    _page = widget.document.position.round().clamp(1, 1 << 20);
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
    final scheme = Theme.of(context).colorScheme;
    final background = scheme.surfaceContainerHigh;
    final params = PdfViewerParams(
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
    final initialPage = widget.document.position.round().clamp(1, 1 << 20);

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
