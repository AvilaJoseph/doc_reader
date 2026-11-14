import 'package:doc_reader/core/theme/app_theme.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/core/widgets/filter_pill.dart';
import 'package:doc_reader/l10n/l10n.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

/// Destino elegido en el navegador: una página o una entrada del índice.
typedef PdfNavigation = ({int? page, PdfDest? dest});

/// Hoja para moverse por un PDF: ir a una página, miniaturas e índice.
///
/// Reúne todo en un sitio y a un toque: escribir el número, tocar una
/// miniatura o tocar un capítulo cierra la hoja y salta.
Future<PdfNavigation?> showPdfNavigator(
  BuildContext context, {
  required PdfDocument document,
  required int currentPage,
  ColorFilter? pageFilter,
}) {
  return showModalBottomSheet<PdfNavigation>(
    context: context,
    isScrollControlled: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.85,
      child: _PdfNavigator(
        document: document,
        currentPage: currentPage,
        pageFilter: pageFilter,
      ),
    ),
  );
}

/// Entrada del índice ya aplanada, con su nivel de sangría.
typedef _OutlineEntry = ({String title, PdfDest? dest, int depth});

List<_OutlineEntry> _flatten(List<PdfOutlineNode> nodes, [int depth = 0]) => [
  for (final node in nodes) ...[
    (title: node.title.trim(), dest: node.dest, depth: depth),
    ..._flatten(node.children, depth + 1),
  ],
];

class _PdfNavigator extends StatefulWidget {
  const new({
    required this.document,
    required this.currentPage,
    required this.pageFilter,
  });

  final PdfDocument document;
  final int currentPage;
  final ColorFilter? pageFilter;

  @override
  State<_PdfNavigator> createState() => _PdfNavigatorState();
}

class _PdfNavigatorState extends State<_PdfNavigator> {
  final _pageText = TextEditingController();
  late final Future<List<_OutlineEntry>> _outline = widget.document
      .loadOutline()
      .then(_flatten, onError: (_) => const <_OutlineEntry>[]);
  bool _showOutline = false;

  @override
  void dispose() {
    _pageText.dispose();
    super.dispose();
  }

  void _goToTyped() {
    final page = int.tryParse(_pageText.text);
    if (page == null) return;
    Navigator.of(context).pop<PdfNavigation>((
      page: page.clamp(1, widget.document.pages.length),
      dest: null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final count = widget.document.pages.length;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(l10n.readerNavigate, style: textTheme.titleLarge),
                ),
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _pageText,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.go,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: '1 – $count',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _goToTyped(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(onPressed: _goToTyped, child: Text(l10n.readerGo)),
              ],
            ),
          ),
          FutureBuilder(
            future: _outline,
            builder: (context, snapshot) {
              // Las pestañas solo aparecen si el PDF trae índice.
              if (snapshot.data?.isEmpty ?? true) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    FilterPill(
                      label: l10n.readerPages,
                      selected: !_showOutline,
                      onTap: () => setState(() => _showOutline = false),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilterPill(
                      label: l10n.readerOutline,
                      selected: _showOutline,
                      onTap: () => setState(() => _showOutline = true),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: _showOutline
                ? _OutlineList(outline: _outline)
                : _PageGrid(
                    document: widget.document,
                    currentPage: widget.currentPage,
                    pageFilter: widget.pageFilter,
                  ),
          ),
        ],
      ),
    );
  }
}

class _PageGrid extends StatefulWidget {
  const new({
    required this.document,
    required this.currentPage,
    required this.pageFilter,
  });

  static const int columns = 3;
  static const double aspect = 0.62;

  final PdfDocument document;
  final int currentPage;
  final ColorFilter? pageFilter;

  @override
  State<_PageGrid> createState() => _PageGridState();
}

class _PageGridState extends State<_PageGrid> {
  ScrollController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const columns = _PageGrid.columns;
    const aspect = _PageGrid.aspect;
    final document = widget.document;
    final currentPage = widget.currentPage;
    final pageFilter = widget.pageFilter;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppSpacing.md;
        final tileWidth =
            (constraints.maxWidth - AppSpacing.lg * 2 - spacing * 2) / columns;
        final rowHeight = tileWidth / aspect + spacing;
        // Abre la cuadrícula con la página actual a la vista.
        final controller = _controller ??= ScrollController(
          initialScrollOffset:
              ((currentPage - 1) ~/ columns - 1).clamp(0, 1 << 20).toDouble() *
              rowHeight,
        );
        return GridView.builder(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: aspect,
          ),
          itemCount: document.pages.length,
          itemBuilder: (context, index) {
            final page = index + 1;
            final current = page == currentPage;
            Widget thumb = PdfPageView(
              document: document,
              pageNumber: page,
              // Miniatura a baja resolución: rápida y ligera.
              maximumDpi: 48,
              backgroundColor: Colors.white,
            );
            if (pageFilter case final filter?) {
              thumb = ColorFiltered(colorFilter: filter, child: thumb);
            }
            return InkWell(
              borderRadius: BorderRadius.circular(AppRadii.card),
              onTap: () =>
                  Navigator.of(context)
                      .pop<PdfNavigation>((page: page, dest: null)),
              child: Column(
                children: [
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        border: Border.all(
                          color: current
                              ? scheme.primary
                              : scheme.outlineVariant,
                          width: current ? 2 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: thumb,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$page',
                    style: textTheme.labelMedium?.copyWith(
                      color: current ? scheme.primary : scheme.onSurfaceVariant,
                      fontWeight: current ? FontWeight.w700 : null,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _OutlineList extends StatelessWidget {
  const new({required this.outline});

  final Future<List<_OutlineEntry>> outline;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder(
      future: outline,
      builder: (context, snapshot) {
        final entries = snapshot.data ?? const [];
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return ListTile(
              contentPadding: EdgeInsets.only(
                left: AppSpacing.lg + entry.depth * AppSpacing.md,
                right: AppSpacing.lg,
              ),
              title: Text(
                entry.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: entry.depth == 0
                    ? const TextStyle(fontWeight: FontWeight.w600)
                    : null,
              ),
              trailing: entry.dest == null
                  ? null
                  : Text(
                      '${entry.dest!.pageNumber}',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
              enabled: entry.dest != null,
              onTap: () =>
                  Navigator.of(context)
                      .pop<PdfNavigation>((page: null, dest: entry.dest)),
            );
          },
        );
      },
    );
  }
}
