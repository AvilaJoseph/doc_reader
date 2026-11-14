import 'dart:async';

import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/features/highlights/application/highlights_controller.dart';
import 'package:doc_reader/features/highlights/domain/highlight.dart';
import 'package:doc_reader/features/highlights/presentation/note_dialog.dart';
import 'package:doc_reader/l10n/l10n.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Acciones del menú de selección compartidas por todos los visores.
///
/// Recibe uno o varios fragmentos (varios en PDF cuando la selección cruza
/// páginas) y los guarda mediante [HighlightsController].
class AnnotationActions {
  const new({
    required this.context,
    required this.ref,
    required this.documentId,
    required this.documentTitle,
  });

  final BuildContext context;
  final WidgetRef ref;
  final String documentId;
  final String documentTitle;

  HighlightsController get _controller =>
      ref.read(highlightsControllerProvider.notifier);

  void mark(List<HighlightDraft> drafts, int color, HighlightStyle style) {
    if (drafts.isEmpty) return;
    unawaited(
      _controller.mark(
        documentId: documentId,
        drafts: drafts,
        colorIndex: color,
        style: style,
      ),
    );
  }

  void remove(List<HighlightDraft> drafts) => unawaited(
    _controller.removeRanges(documentId: documentId, drafts: drafts),
  );

  bool touchesExisting(List<HighlightDraft> drafts) =>
      drafts.any((d) => _controller.overlapping(documentId, d).isNotEmpty);

  Future<void> note(List<HighlightDraft> drafts) async {
    if (drafts.isEmpty) return;
    final existing = _controller.overlapping(documentId, drafts.first);
    final text = await showNoteDialog(
      context,
      quote: drafts.map((d) => d.text).join(' '),
      initial: existing.map((h) => h.note).nonNulls.firstOrNull,
    );
    if (text == null || text.trim().isEmpty) return;
    await _controller.annotate(
      documentId: documentId,
      drafts: drafts,
      note: text.trim(),
    );
  }

  void copy(String text) {
    unawaited(Clipboard.setData(ClipboardData(text: text)));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.copied)));
  }

  void share(String text) => unawaited(
    SharePlus.instance.share(
      ShareParams(
        text: '«$text»\n— $documentTitle',
        subject: context.l10n.annotationShareTitle(documentTitle),
      ),
    ),
  );
}
