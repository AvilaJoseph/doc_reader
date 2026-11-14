import 'dart:async';

import 'package:doc_reader/core/theme/app_theme.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/core/widgets/floating_pill.dart';
import 'package:doc_reader/features/library/application/library_controller.dart';
import 'package:doc_reader/features/library/domain/library_document.dart';
import 'package:doc_reader/features/reader/application/document_providers.dart';
import 'package:doc_reader/features/reader/formats/spreadsheet/spreadsheet_view.dart';
import 'package:doc_reader/features/reader/formats/spreadsheet/workbook.dart';
import 'package:doc_reader/features/reader/presentation/widgets/reader_scaffold.dart';
import 'package:doc_reader/features/reader/presentation/widgets/reader_states.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Visor de hojas de cálculo con pestañas de hojas en la píldora inferior.
class SpreadsheetReaderScreen extends ConsumerStatefulWidget {
  const new({required this.document, required this.onMore, super.key});

  final LibraryDocument document;
  final VoidCallback onMore;

  @override
  ConsumerState<SpreadsheetReaderScreen> createState() =>
      _SpreadsheetReaderScreenState();
}

class _SpreadsheetReaderScreenState
    extends ConsumerState<SpreadsheetReaderScreen> {
  late int _sheetIndex = widget.document.position.round();
  late final LibraryController _library = ref.read(
    libraryControllerProvider.notifier,
  );

  void _select(int index, int count) {
    setState(() => _sheetIndex = index);
    unawaited(
      _library.saveProgress(
        widget.document.id,
        progress: count <= 1 ? 1 : (index + 1) / count,
        position: index.toDouble(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final workbook = ref.watch(workbookProvider(widget.document.id));
    final sheets = workbook.value?.sheets ?? const <Sheet>[];
    final index = sheets.isEmpty ? 0 : _sheetIndex.clamp(0, sheets.length - 1);

    return ReaderScaffold(
      title: widget.document.title,
      subtitle: sheets.isEmpty ? null : sheets[index].name,
      background: scheme.surface,
      foreground: scheme.onSurface,
      muted: scheme.onSurfaceVariant,
      onMore: widget.onMore,
      bottomPill: sheets.length < 2
          ? null
          : ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width - AppSpacing.xl,
              ),
              child: FloatingPill(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (i, sheet) in sheets.indexed)
                        PillButton(
                          icon: Icons.grid_on_rounded,
                          label: sheet.name,
                          selected: i == index,
                          onPressed: () => _select(i, sheets.length),
                        ),
                    ],
                  ),
                ),
              ),
            ),
      body: switch (workbook) {
        AsyncData(:final value) when value.sheets.isNotEmpty => Padding(
          padding: EdgeInsets.only(
            bottom: sheets.length < 2 ? 0 : AppSpacing.bottomPillClearance / 2,
          ),
          child: SpreadsheetView(
            key: ValueKey(index),
            sheet: value.sheets[index],
          ),
        ),
        AsyncData() => const SpreadsheetView(
          sheet: Sheet(name: '', rows: []),
        ),
        AsyncError(:final error) => ReaderError(
          error: error,
          onRetry: () => ref.invalidate(workbookProvider(widget.document.id)),
        ),
        _ => ReaderLoading(color: scheme.onSurfaceVariant),
      },
    );
  }
}
