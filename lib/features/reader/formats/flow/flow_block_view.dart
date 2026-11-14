import 'dart:async';

import 'package:doc_reader/core/theme/app_colors.dart';
import 'package:doc_reader/core/theme/app_typography.dart';
import 'package:doc_reader/core/theme/reading_theme.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/features/highlights/domain/highlight.dart';
import 'package:doc_reader/features/reader/formats/flow/flow_document.dart';
import 'package:doc_reader/features/reader/formats/flow/highlight_spans.dart';
import 'package:doc_reader/features/reader/formats/flow/highlight_toolbar.dart';
import 'package:flutter/services.dart';

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

  Color highlightColor(int index) {
    final color = AppColors.highlights[index % AppColors.highlights.length];
    return theme.brightness == Brightness.dark
        ? color.withValues(alpha: 0.42)
        : color.withValues(alpha: 0.85);
  }
}

/// Acciones de subrayado sobre un bloque.
typedef HighlightCallback = void Function(
  int blockIndex,
  int start,
  int end,
  int colorIndex,
);
typedef RemoveHighlightCallback = void Function(
  int blockIndex,
  int start,
  int end,
);

/// Pinta un [FlowBlock].
class FlowBlockView extends StatelessWidget {
  const new({
    required this.block,
    required this.blockIndex,
    required this.style,
    required this.highlights,
    required this.onHighlight,
    required this.onRemoveHighlight,
    required this.onCopy,
    super.key,
  });

  final FlowBlock block;
  final int blockIndex;
  final FlowReadingStyle style;
  final List<Highlight> highlights;
  final HighlightCallback onHighlight;
  final RemoveHighlightCallback onRemoveHighlight;
  final ValueChanged<String> onCopy;

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
        ),
      ),
      textAlign: switch (paragraph.alignment) {
        FlowAlignment.start => TextAlign.start,
        FlowAlignment.center => TextAlign.center,
        FlowAlignment.end => TextAlign.end,
        FlowAlignment.justify => TextAlign.justify,
      },
      selectionColor: style.theme.ink.withValues(alpha: 0.14),
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

    return HighlightToolbar(
      anchors: state.contextMenuAnchors,
      onColor: (color) {
        onHighlight(blockIndex, start, end, color);
        finish();
      },
      onCopy: () {
        final selected = paragraph.plainText.substring(start, end);
        unawaited(Clipboard.setData(ClipboardData(text: selected)));
        onCopy(selected);
        finish();
      },
      onRemove: touchesHighlight
          ? () {
              onRemoveHighlight(blockIndex, start, end);
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
        child: Image.memory(
          image.bytes,
          fit: BoxFit.contain,
          semanticLabel: image.description,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
