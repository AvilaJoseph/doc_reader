import 'dart:async';

import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/features/highlights/application/highlights_controller.dart';
import 'package:doc_reader/features/library/application/document_sharing.dart';
import 'package:doc_reader/features/library/application/library_controller.dart';
import 'package:doc_reader/features/library/domain/library_document.dart';
import 'package:doc_reader/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Acciones sobre un documento (abrir, renombrar, compartir, quitar).
Future<void> showDocumentActions(
  BuildContext context,
  WidgetRef ref,
  LibraryDocument doc, {
  VoidCallback? onOpen,
  bool allowRemove = true,
}) {
  final l10n = context.l10n;
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              doc.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
          ),
          if (onOpen != null)
            ListTile(
              leading: const Icon(Icons.chrome_reader_mode_outlined),
              title: Text(l10n.documentOpen),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onOpen();
              },
            ),
          ListTile(
            leading: const Icon(Icons.drive_file_rename_outline_rounded),
            title: Text(l10n.documentRename),
            onTap: () async {
              Navigator.of(sheetContext).pop();
              final name = await showDialog<String>(
                context: context,
                builder: (_) => _RenameDialog(initial: doc.title),
              );
              if (name != null && name.trim().isNotEmpty) {
                await ref
                    .read(libraryControllerProvider.notifier)
                    .rename(doc.id, name);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.ios_share_rounded),
            title: Text(l10n.documentShare),
            onTap: () {
              Navigator.of(sheetContext).pop();
              unawaited(shareDocument(ref, doc));
            },
          ),
          if (allowRemove)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: Text(l10n.documentRemove),
              onTap: () {
                Navigator.of(sheetContext).pop();
                unawaited(removeWithUndo(context, ref, doc));
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Quita el documento y ofrece deshacer; si no se deshace, borra el
/// archivo y sus subrayados.
Future<void> removeWithUndo(
  BuildContext context,
  WidgetRef ref,
  LibraryDocument doc,
) async {
  final library = ref.read(libraryControllerProvider.notifier);
  final highlights = ref.read(highlightsControllerProvider.notifier);
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  await library.remove(doc.id);
  var undone = false;
  final controller = messenger.showSnackBar(
    SnackBar(
      content: Text(l10n.documentRemoved(doc.title)),
      action: SnackBarAction(
        label: l10n.undo,
        onPressed: () {
          undone = true;
          unawaited(library.restore(doc));
        },
      ),
    ),
  );
  await controller.closed;
  if (!undone) {
    await library.purge(doc);
    await highlights.removeForDocument(doc.id);
  }
}

class _RenameDialog extends StatefulWidget {
  const new({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.renameTitle),
      content: TextField(
        controller: _text,
        autofocus: true,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_text.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
