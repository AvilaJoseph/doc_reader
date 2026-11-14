import 'dart:async';

import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/core/widgets/empty_state.dart';
import 'package:doc_reader/features/library/application/library_controller.dart';
import 'package:doc_reader/features/library/domain/document_kind.dart';
import 'package:doc_reader/features/library/presentation/widgets/document_actions_sheet.dart';
import 'package:doc_reader/features/reader/application/document_providers.dart';
import 'package:doc_reader/features/reader/presentation/flow_reader_screen.dart';
import 'package:doc_reader/features/reader/presentation/image_reader_screen.dart';
import 'package:doc_reader/features/reader/presentation/pdf_reader_screen.dart';
import 'package:doc_reader/features/reader/presentation/spreadsheet_reader_screen.dart';
import 'package:doc_reader/features/settings/application/settings_controller.dart';
import 'package:doc_reader/l10n/l10n.dart';
import 'package:flutter/services.dart';
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

  bool _rotationApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_rotationApplied) return;
    _rotationApplied = true;
    _applyRotationLock(
      locked: ref.read(settingsControllerProvider).lockRotation,
    );
  }

  @override
  void dispose() {
    // Al salir del lector la app vuelve a girar libremente.
    unawaited(SystemChrome.setPreferredOrientations(const []));
    super.dispose();
  }

  /// Fija la orientación actual mientras se lee, o la libera.
  void _applyRotationLock({required bool locked}) {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    unawaited(
      SystemChrome.setPreferredOrientations(
        !locked
            ? const []
            : landscape
            ? const [
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ]
            : const [DeviceOrientation.portraitUp],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      settingsControllerProvider.select((s) => s.lockRotation),
      (_, locked) => _applyRotationLock(locked: locked),
    );
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
      DocumentKind.word ||
      DocumentKind.text ||
      DocumentKind.presentation => FlowReaderScreen(
        document: document,
        onMore: onMore,
        initialBlock: widget.initialLocation,
      ),
      DocumentKind.image => ImageReaderScreen(
        document: document,
        onMore: onMore,
      ),
      DocumentKind.spreadsheet => SpreadsheetReaderScreen(
        document: document,
        onMore: onMore,
      ),
    };
  }
}
