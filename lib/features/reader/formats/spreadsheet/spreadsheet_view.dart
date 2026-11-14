import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/features/reader/formats/spreadsheet/workbook.dart';
import 'package:doc_reader/l10n/l10n.dart';
import 'package:flutter/services.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

const double _columnWidth = 120;
const double _rowHeaderWidth = 48;
const double _rowHeight = 40;

/// Cuadrícula de una hoja con encabezados fijos (letras y números).
///
/// Se construye de forma perezosa en ambos ejes, así que soporta hojas
/// grandes sin coste extra.
class SpreadsheetView extends StatelessWidget {
  const new({required this.sheet, super.key});

  final Sheet sheet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (sheet.isEmpty) {
      return Center(
        child: Text(
          context.l10n.readerSheetEmpty,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final border = BorderSide(color: scheme.outlineVariant, width: 0.5);
    final table = TableView.builder(
      pinnedRowCount: 1,
      pinnedColumnCount: 1,
      rowCount: sheet.rowCount + 1,
      columnCount: sheet.columnCount + 1,
      columnBuilder: (index) => TableSpan(
        extent: FixedTableSpanExtent(
          index == 0 ? _rowHeaderWidth : _columnWidth,
        ),
        foregroundDecoration: TableSpanDecoration(
          border: TableSpanBorder(trailing: border),
        ),
      ),
      rowBuilder: (index) => TableSpan(
        extent: const FixedTableSpanExtent(_rowHeight),
        foregroundDecoration: TableSpanDecoration(
          border: TableSpanBorder(trailing: border),
        ),
      ),
      cellBuilder: (context, vicinity) =>
          _buildCell(context, vicinity.row, vicinity.column),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sheet.truncated)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: scheme.surfaceContainerHighest,
            child: Text(
              context.l10n.readerSheetTruncated(sheet.rowCount),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        Expanded(child: table),
      ],
    );
  }

  TableViewCell _buildCell(BuildContext context, int row, int column) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isHeader = row == 0 || column == 0;

    if (isHeader) {
      final label = row == 0 && column == 0
          ? ''
          : row == 0
          ? columnLabel(column - 1)
          : '$row';
      return TableViewCell(
        child: ColoredBox(
          color: scheme.surfaceContainerHighest,
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    final value = sheet.rows[row - 1][column - 1];
    return TableViewCell(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: value.isEmpty ? null : () => _copy(context, value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context, String value) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final copied = context.l10n.copied;
    await Clipboard.setData(ClipboardData(text: value));
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(copied)));
  }
}
