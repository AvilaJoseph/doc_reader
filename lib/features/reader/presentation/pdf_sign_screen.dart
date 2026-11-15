import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:doc_reader/core/theme/app_colors.dart';
import 'package:doc_reader/core/theme/app_theme.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/core/widgets/floating_pill.dart';
import 'package:doc_reader/features/library/domain/library_document.dart';
import 'package:doc_reader/features/reader/application/pdf_signing.dart';
import 'package:doc_reader/features/reader/formats/pdf/pdf_stamper.dart';
import 'package:doc_reader/features/reader/presentation/widgets/signature_pad_sheet.dart';
import 'package:doc_reader/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:pdfrx/pdfrx.dart';

/// Abre la pantalla de rellenar y firmar sobre [pdf], empezando en
/// [pageNumber]. Devuelve la copia firmada, si se guardó.
Future<LibraryDocument?> showPdfSignScreen(
  BuildContext context, {
  required LibraryDocument document,
  required PdfDocument pdf,
  required int pageNumber,
}) => Navigator.of(context).push(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) =>
        PdfSignScreen(document: document, pdf: pdf, initialPage: pageNumber),
  ),
);

/// Coloca firmas y textos sobre las páginas y guarda una copia del PDF.
class PdfSignScreen extends ConsumerStatefulWidget {
  const new({
    required this.document,
    required this.pdf,
    required this.initialPage,
    super.key,
  });

  final LibraryDocument document;
  final PdfDocument pdf;
  final int initialPage;

  @override
  ConsumerState<PdfSignScreen> createState() => _PdfSignScreenState();
}

/// Marca en edición: imagen + rectángulo en fracciones de la página.
class _Placed {
  new({
    required this.page,
    required this.image,
    required this.rgba,
    required this.rect,
  });

  final int page;
  final ui.Image image;
  final Uint8List rgba;
  Rect rect;

  double get aspect => image.height / image.width;
}

class _PdfSignScreenState extends ConsumerState<PdfSignScreen> {
  late int _page = widget.initialPage;
  final _placed = <_Placed>[];
  _Placed? _selected;
  bool _saving = false;

  int get _pageCount => widget.pdf.pages.length;

  PdfPage get _pdfPage => widget.pdf.pages[_page - 1];

  /// Alto/ancho de la página tal como se ve.
  double get _pageAspect => _pdfPage.height / _pdfPage.width;

  @override
  void dispose() {
    for (final p in _placed) {
      p.image.dispose();
    }
    super.dispose();
  }

  Future<void> _addSignature() async {
    final saved = ref.read(savedSignatureProvider);
    final png = await showSignaturePad(context, saved: saved);
    if (png == null || !mounted) return;
    if (!identical(png, saved)) {
      ref.read(savedSignatureProvider.notifier).save(png);
    }
    final codec = await ui.instantiateImageCodec(png);
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    await _place(image, width: 0.35);
  }

  Future<void> _addText() async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _TextDialog(),
    );
    if (text == null || text.trim().isEmpty || !mounted) return;
    final painter = TextPainter(
      text: TextSpan(
        text: text.trim(),
        style: const TextStyle(
          color: AppColors.signatureInk,
          fontSize: 48,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), Offset.zero);
    final image = await recorder.endRecording().toImage(
      painter.width.ceil(),
      painter.height.ceil(),
    );
    painter.dispose();
    // Cuerpo de letra parecido al de un formulario (~2,2 % del alto).
    final height = 0.022 * (text.trim().split('\n').length);
    await _place(
      image,
      width: height / (image.height / image.width) / _pageAspect,
    );
  }

  Future<void> _place(ui.Image image, {required double width}) async {
    final data = await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    if (data == null || !mounted) return;
    final w = math.min(width, 0.9);
    final h = w * (image.height / image.width) / _pageAspect;
    final placed = _Placed(
      page: _page,
      image: image,
      rgba: data.buffer.asUint8List(),
      rect: Rect.fromLTWH((1 - w) / 2, (1 - h) / 2, w, h),
    );
    setState(() {
      _placed.add(placed);
      _selected = placed;
    });
  }

  void _remove(_Placed placed) => setState(() {
    _placed.remove(placed);
    if (_selected == placed) _selected = null;
    placed.image.dispose();
  });

  Future<void> _save() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    LibraryDocument? copy;
    try {
      copy = await ref
          .read(pdfSigningProvider)
          .saveCopy(
            document: widget.document,
            suffix: l10n.signSuffix,
            stamps: [
              for (final p in _placed)
                PdfStamp(
                  pageIndex: p.page - 1,
                  left: p.rect.left,
                  top: p.rect.top,
                  width: p.rect.width,
                  height: p.rect.height,
                  rgba: p.rgba,
                  pixelWidth: p.image.width,
                  pixelHeight: p.image.height,
                ),
            ],
          );
    } on Object {
      copy = null;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (copy == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.signFailed)));
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.signSaved(copy.fileName))),
    );
    navigator.pop(copy);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerHigh,
      appBar: AppBar(
        backgroundColor: scheme.surfaceContainerHigh,
        title: Text(l10n.signTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilledButton(
              onPressed: _placed.isEmpty || _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.signSave),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.bottomPillClearance +
                  MediaQuery.paddingOf(context).bottom,
            ),
            child: Center(
              child: AspectRatio(
                aspectRatio: 1 / _pageAspect,
                child: LayoutBuilder(
                  builder: (context, box) => _pageEditor(box.biggest),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
            child: Center(heightFactor: 1, child: _pill(context)),
          ),
        ],
      ),
    );
  }

  Widget _pageEditor(Size size) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selected = null),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: PdfPageView(
                key: ValueKey(_page),
                document: widget.pdf,
                pageNumber: _page,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          for (final placed in _placed)
            if (placed.page == _page)
              _StampView(
                key: ObjectKey(placed),
                placed: placed,
                pageSize: size,
                selected: placed == _selected,
                pageAspect: _pageAspect,
                onSelect: () => setState(() => _selected = placed),
                onChanged: () => setState(() {}),
                onRemove: () => _remove(placed),
                removeLabel: context.l10n.signRemove,
              ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context) {
    final l10n = context.l10n;
    return FloatingPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PillButton(
            icon: Icons.chevron_left_rounded,
            tooltip: l10n.readerSearchPrevious,
            onPressed: _page > 1 ? () => setState(() => _page--) : null,
          ),
          PillButton(
            icon: Icons.description_outlined,
            label: l10n.readerPageOf(_page, _pageCount),
            selected: true,
            onPressed: null,
          ),
          PillButton(
            icon: Icons.chevron_right_rounded,
            tooltip: l10n.readerSearchNext,
            onPressed: _page < _pageCount
                ? () => setState(() => _page++)
                : null,
          ),
          PillButton(
            icon: Icons.draw_outlined,
            label: l10n.signSignature,
            onPressed: () => unawaited(_addSignature()),
          ),
          PillButton(
            icon: Icons.title_rounded,
            label: l10n.signText,
            onPressed: () => unawaited(_addText()),
          ),
        ],
      ),
    );
  }
}

/// Una marca colocada: se arrastra para moverla, la esquina inferior
/// derecha cambia el tamaño y la superior derecha la quita.
class _StampView extends StatelessWidget {
  const new({
    required this.placed,
    required this.pageSize,
    required this.selected,
    required this.pageAspect,
    required this.onSelect,
    required this.onChanged,
    required this.onRemove,
    required this.removeLabel,
    super.key,
  });

  final _Placed placed;
  final Size pageSize;
  final bool selected;
  final double pageAspect;
  final VoidCallback onSelect;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final String removeLabel;

  /// Margen táctil alrededor de la marca para las asas.
  static const _pad = 14.0;

  void _move(Offset delta) {
    final r = placed.rect;
    final dx = delta.dx / pageSize.width;
    final dy = delta.dy / pageSize.height;
    placed.rect = Rect.fromLTWH(
      (r.left + dx).clamp(0, 1 - r.width),
      (r.top + dy).clamp(0, 1 - r.height),
      r.width,
      r.height,
    );
    onChanged();
  }

  void _resize(Offset delta) {
    final r = placed.rect;
    final maxWidth = math.min(
      1 - r.left,
      (1 - r.top) / (placed.aspect / pageAspect),
    );
    final w = (r.width + delta.dx / pageSize.width).clamp(0.04, maxWidth);
    placed.rect = Rect.fromLTWH(
      r.left,
      r.top,
      w,
      w * placed.aspect / pageAspect,
    );
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final r = placed.rect;
    return Positioned(
      left: r.left * pageSize.width - _pad,
      top: r.top * pageSize.height - _pad,
      width: r.width * pageSize.width + _pad * 2,
      height: r.height * pageSize.height + _pad * 2,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: onSelect,
              onPanStart: (_) => onSelect(),
              onPanUpdate: (d) => _move(d.delta),
              child: Padding(
                padding: const EdgeInsets.all(_pad),
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    border: selected
                        ? Border.all(color: AppColors.selectionHandle)
                        : null,
                  ),
                  child: RawImage(image: placed.image, fit: BoxFit.fill),
                ),
              ),
            ),
          ),
          if (selected) ...[
            Positioned(
              right: 0,
              top: 0,
              child: _Handle(
                icon: Icons.close_rounded,
                label: removeLabel,
                onTap: onRemove,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onPanUpdate: (d) => _resize(d.delta),
                child: const _Handle(icon: Icons.open_in_full_rounded),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const new({required this.icon, this.label, this.onTap});

  final IconData icon;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.selectionHandle,
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(
            dimension: 28,
            child: Icon(icon, size: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Diálogo para escribir un texto (nombre, DNI, fecha…).
class _TextDialog extends StatefulWidget {
  const new();

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return AlertDialog(
      title: Text(l10n.signText),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: null,
            decoration: InputDecoration(hintText: l10n.signTextHint),
          ),
          const SizedBox(height: AppSpacing.sm),
          ActionChip(
            avatar: const Icon(Icons.today_rounded, size: 18),
            label: Text(l10n.signToday),
            onPressed: () =>
                _controller.text = DateFormat.yMd(locale)
                    .format(DateTime.now()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.signAdd),
        ),
      ],
    );
  }
}
