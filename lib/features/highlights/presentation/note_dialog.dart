import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/l10n/l10n.dart';

/// Pide el texto de una nota. Devuelve `null` si se cancela.
Future<String?> showNoteDialog(
  BuildContext context, {
  required String quote,
  String? initial,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _NoteDialog(quote: quote, initial: initial),
  );
}

class _NoteDialog extends StatefulWidget {
  const new({required this.quote, this.initial});

  final String quote;
  final String? initial;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(l10n.annotationNote),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '«${widget.quote}»',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _text,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l10n.annotationNoteHint,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
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
