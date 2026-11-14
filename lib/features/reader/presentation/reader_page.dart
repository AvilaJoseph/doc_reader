import 'dart:async';

import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/core/widgets/empty_state.dart';
import 'package:doc_reader/features/library/application/library_controller.dart';
import 'package:doc_reader/features/library/domain/document_kind.dart';
import 'package:doc_reader/features/library/presentation/widgets/document_actions_sheet.dart';
import 'package:doc_reader/features/reader/application/document_providers.dart';
import 'package:doc_reader/features/reader/presentation/flow_reader_screen.dart';
import 'package:doc_reader/features/reader/presentation/pdf_reader_screen.dart';
import 'package:doc_reader/features/reader/presentation/spreadsheet_reader_screen.dart';
import 'package:doc_reader/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Punto de entrada del lector: elige el visor según el tipo de documento.
class ReaderPage extends ConsumerStatefulWidget {
  const new({required this.documentId, super.key, this.initialLocation});

  final String documentId;

  /// Página (PDF) o bloque (texto) donde abrir, si se pide uno concreto.
  final int? initialLocation;

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  @override
  void initState() {
    super.initState();
    unawaited(
      ref
          .read(libraryControllerProvider.notifier)
          .markOpened(widget.documentId),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Solo reconstruimos si cambia el documento en sí, no su progreso.
    final doc = ref.watch(
      libraryDocumentProvider(widget.documentId)
          .select((doc) => doc == null ? null : (doc.id, doc.title)),
    );
    final document = ref.read(libraryDocumentProvider(widget.documentId));
    if (doc == null || document == null) {
      final loading = ref.watch(libraryControllerProvider).isLoading;
      return Scaffold(
        appBar: AppBar(),
        body: loading
            ? const SizedBox.shrink()
            : EmptyState(
                icon: Icons.search_off_rounded,
                title: context.l10n.readerNotFound,
              ),
      );
    }

    void onMore() =>
        showDocumentActions(context, ref, document, allowRemove: false);

    return switch (document.kind) {
      DocumentKind.pdf => PdfReaderScreen(
        document: document,
        onMore: onMore,
        library: ref.read(libraryControllerProvider.notifier),
        initialPage: widget.initialLocation,
      ),
      DocumentKind.word || DocumentKind.text => FlowReaderScreen(
        document: document,
        onMore: onMore,
        initialBlock: widget.initialLocation,
      ),
      DocumentKind.spreadsheet => SpreadsheetReaderScreen(
        document: document,
        onMore: onMore,
      ),
    };
  }
}
