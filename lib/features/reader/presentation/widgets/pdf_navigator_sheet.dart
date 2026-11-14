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
  List<int> bookmarks = const [],
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
        bookmarks: bookmarks,
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

/// Pestañas del navegador.
enum _Tab { pages, outline, bookmarks }

class _PdfNavigator extends StatefulWidget {
  const new({
    required this.document,
    required this.currentPage,
    required this.bookmarks,
    required this.pageFilter,
  });

  final PdfDocument document;
  final int currentPage;
  final List<int> bookmarks;
  final ColorFilter? pageFilter;

  @override
  State<_PdfNavigator> createState() => _PdfNavigatorState();
}

class _PdfNavigatorState extends State<_PdfNavigator> {
  final _pageText = TextEditingController();
  late final Future<List<_OutlineEntry>> _outline = widget.document
      .loadOutline()
      .then(_flatten, onError: (_) => const <_OutlineEntry>[]);
  _Tab _tab = _Tab.pages;

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
              // Las pestañas solo aparecen si hay índice o marcadores.
              final hasOutline = snapshot.data?.isNotEmpty ?? false;
              final hasBookmarks = widget.bookmarks.isNotEmpty;
              if (!hasOutline && !hasBookmarks) {
                return const SizedBox.shrink();
              }
              Widget tab(_Tab tab, String label) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: FilterPill(
                  label: label,
                  selected: _tab == tab,
                  onTap: () => setState(() => _tab = tab),
                ),
              );
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    tab(_Tab.pages, l10n.readerPages),
                    if (hasOutline) tab(_Tab.outline, l10n.readerOutline),
                    if (hasBookmarks) tab(_Tab.bookmarks, l10n.readerBookmarks),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: switch (_tab) {
              _Tab.outline => _OutlineList(outline: _outline),
              _Tab.bookmarks => _BookmarkList(bookmarks: widget.bookmarks),
              _Tab.pages => _PageGrid(
                document: widget.document,
                currentPage: widget.currentPage,
                bookmarks: widget.bookmarks,
                pageFilter: widget.pageFilter,
              ),
            },
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
    required this.bookmarks,
    required this.pageFilter,
  });

  static const int columns = 3;
  static const double aspect = 0.62;

  final PdfDocument document;
  final int currentPage;
  final List<int> bookmarks;
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
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(2),
                            child: thumb,
                          ),
                          if (widget.bookmarks.contains(page))
                            Positioned(
                              top: 0,
                              right: 6,
                              child: Icon(
                                Icons.bookmark_rounded,
                                size: 20,
                                color: scheme.primary,
                              ),
                            ),
                        ],
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

class _BookmarkList extends StatelessWidget {
  const new({required this.bookmarks});

  final List<int> bookmarks;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final page = bookmarks[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          leading: const Icon(Icons.bookmark_rounded),
          title: Text(context.l10n.readerBookmarkPage(page)),
          onTap: () =>
              Navigator.of(context)
                  .pop<PdfNavigation>((page: page, dest: null)),
        );
      },
    );
  }
}
