import 'package:doc_reader/core/theme/app_colors.dart';
import 'package:doc_reader/core/theme/app_typography.dart';
import 'package:doc_reader/core/theme/reading_theme.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/features/highlights/domain/highlight.dart';
import 'package:doc_reader/features/highlights/presentation/annotation_toolbar.dart';
import 'package:doc_reader/features/reader/formats/flow/flow_document.dart';
import 'package:doc_reader/features/reader/formats/flow/highlight_spans.dart';

/// Parámetros tipográficos del lector.
@immutable
class FlowReadingStyle {
  const new({
    required this.theme,
    required this.fontSize,
    required this.lineHeight,
  });

  final ReadingTheme theme;
  final double fontSize;
  final double lineHeight;

  TextStyle get body => AppTypography.reading(
    color: theme.ink,
    fontSize: fontSize,
    height: lineHeight,
  );

  TextStyle heading(int level) {
    final scale = switch (level) {
      1 => 1.55,
      2 => 1.3,
      3 => 1.15,
      _ => 1.0,
    };
    return AppTypography.reading(
      color: theme.ink,
      fontSize: fontSize * scale,
      height: 1.25,
      fontWeight: level <= 2 ? FontWeight.w700 : FontWeight.w600,
    );
  }

  /// Línea de "Subrayar": azul clásico, algo más claro de noche.
  Color get underlineColor => theme.brightness == Brightness.dark
      ? AppColors.underlineNight
      : AppColors.underline;

  Color highlightColor(int index) {
    final color = AppColors.highlights[index % AppColors.highlights.length];
    return theme.brightness == Brightness.dark
        ? color.withValues(alpha: 0.42)
        : color.withValues(alpha: 0.85);
  }
}

/// Qué hacer con una selección de texto. Lo implementa el lector.
@immutable
class FlowAnnotationActions {
  const new({
    required this.onMark,
    required this.onNote,
    required this.onRemove,
    required this.onCopy,
    required this.onShare,
  });

  final void Function(HighlightDraft draft, int color, HighlightStyle style)
  onMark;
  final void Function(HighlightDraft draft) onNote;
  final void Function(HighlightDraft draft) onRemove;
  final void Function(String text) onCopy;
  final void Function(String text) onShare;
}

/// Pinta un [FlowBlock].
class FlowBlockView extends StatelessWidget {
  const new({
    required this.block,
    required this.blockIndex,
    required this.style,
    required this.highlights,
    required this.actions,
    super.key,
  });

  final FlowBlock block;
  final int blockIndex;
  final FlowReadingStyle style;
  final List<Highlight> highlights;
  final FlowAnnotationActions actions;

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      final ParagraphBlock p => _paragraph(context, p),
      final TableBlock t => _FlowTable(table: t, style: style),
      final ImageBlock i => _FlowImage(image: i),
      DividerBlock() => _divider(),
    };
  }

  Widget _paragraph(BuildContext context, ParagraphBlock paragraph) {
    final base = paragraph.isHeading
        ? style.heading(paragraph.headingLevel)
        : style.body;
    final text = SelectableText.rich(
      TextSpan(
        style: base,
        children: buildHighlightedSpans(
          runs: paragraph.runs,
          highlights: highlights,
          styleFor: (run) => _runStyle(base, run),
          colorFor: style.highlightColor,
          underlineColor: style.underlineColor,
        ),
      ),
      textAlign: switch (paragraph.alignment) {
        FlowAlignment.start => TextAlign.start,
        FlowAlignment.center => TextAlign.center,
        FlowAlignment.end => TextAlign.end,
        FlowAlignment.justify => TextAlign.justify,
      },
      selectionColor: AppColors.selection,
      contextMenuBuilder: (context, state) => _toolbar(state, paragraph),
    );

    final list = paragraph.list;
    final spacing = paragraph.isHeading
        ? EdgeInsets.only(
            top: style.fontSize * (paragraph.headingLevel <= 2 ? 1.4 : 1),
            bottom: style.fontSize * 0.5,
          )
        : EdgeInsets.only(bottom: style.fontSize * (list == null ? 0.9 : 0.4));

    if (list == null) return Padding(padding: spacing, child: text);
    return Padding(
      padding: spacing.add(
        EdgeInsets.only(left: style.fontSize * 1.1 * list.level),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: style.fontSize * 1.8,
            child: Text(
              list.marker,
              style: base.copyWith(color: style.theme.muted),
            ),
          ),
          Expanded(child: text),
        ],
      ),
    );
  }

  TextStyle _runStyle(TextStyle base, TextRun run) {
    var result = base.copyWith(
      fontWeight: run.bold ? FontWeight.w700 : null,
      fontStyle: run.italic ? FontStyle.italic : null,
      decoration: TextDecoration.combine([
        if (run.underline || run.link != null) TextDecoration.underline,
        if (run.strike) TextDecoration.lineThrough,
      ]),
      decorationColor: style.theme.muted,
    );
    if (run.code) {
      result = AppTypography.mono(
        result.copyWith(fontSize: (base.fontSize ?? 16) * 0.88),
      );
    }
    return result;
  }

  Widget _toolbar(EditableTextState state, ParagraphBlock paragraph) {
    final selection = state.textEditingValue.selection;
    if (selection.isCollapsed) return const SizedBox.shrink();
    final start = selection.start;
    final end = selection.end;
    final touchesHighlight = highlights.any((h) => h.overlaps(start, end));

    void finish() {
      state
        ..hideToolbar()
        ..userUpdateTextEditingValue(
          state.textEditingValue.copyWith(
            selection: TextSelection.collapsed(offset: end),
          ),
          SelectionChangedCause.toolbar,
        );
    }

    final draft = HighlightDraft(
      blockIndex: blockIndex,
      start: start,
      end: end,
      text: paragraph.plainText.substring(start, end),
    );

    return AnnotationToolbar(
      anchors: state.contextMenuAnchors,
      onColor: (color) {
        actions.onMark(draft, color, HighlightStyle.highlight);
        finish();
      },
      onUnderline: () {
        actions.onMark(draft, 0, HighlightStyle.underline);
        finish();
      },
      onNote: () {
        finish();
        actions.onNote(draft);
      },
      onCopy: () {
        actions.onCopy(draft.text);
        finish();
      },
      onShare: () {
        finish();
        actions.onShare(draft.text);
      },
      onRemove: touchesHighlight
          ? () {
              actions.onRemove(draft);
              finish();
            }
          : null,
    );
  }

  Widget _divider() => Padding(
    padding: EdgeInsets.symmetric(vertical: style.fontSize),
    child: Center(
      child: Text(
        '·  ·  ·',
        style: style.body.copyWith(color: style.theme.muted),
      ),
    ),
  );
}

class _FlowTable extends StatelessWidget {
  const new({required this.table, required this.style});

  final TableBlock table;
  final FlowReadingStyle style;

  @override
  Widget build(BuildContext context) {
    final columns = table.columnCount;
    if (columns == 0) return const SizedBox.shrink();
    final line = style.theme.muted.withValues(alpha: 0.35);
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: style.theme.ink,
      fontSize: style.fontSize * 0.78,
      height: 1.35,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: style.fontSize),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder.all(
            color: line,
            borderRadius: BorderRadius.circular(6),
          ),
          children: [
            for (final (rowIndex, row) in table.rows.indexed)
              TableRow(
                decoration: rowIndex == 0
                    ? BoxDecoration(
                        color: style.theme.ink.withValues(alpha: 0.04),
                      )
                    : null,
                children: [
                  for (var c = 0; c < columns; c++)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Text(
                          c < row.length ? row[c] : '',
                          style: rowIndex == 0
                              ? textStyle?.copyWith(fontWeight: FontWeight.w700)
                              : textStyle,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _FlowImage extends StatelessWidget {
  const new({required this.image});

  final ImageBlock image;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LayoutBuilder(
          // Decodifica al ancho de la columna, no al tamaño original: una
          // foto de 12 MP ocuparía ~48 MB de memoria y frenaría el scroll.
          builder: (context, constraints) => Image.memory(
            image.bytes,
            cacheWidth: constraints.maxWidth.isFinite
                ? (constraints.maxWidth *
                          MediaQuery.devicePixelRatioOf(context))
                      .round()
                : null,
            fit: BoxFit.contain,
            semanticLabel: image.description,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
