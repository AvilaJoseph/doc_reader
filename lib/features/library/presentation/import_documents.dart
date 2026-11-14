import 'package:doc_reader/app/routes.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/features/library/application/library_controller.dart';
import 'package:doc_reader/features/library/data/document_file_store.dart';
import 'package:doc_reader/features/library/domain/document_kind.dart';
import 'package:doc_reader/l10n/l10n.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Abre el selector del sistema, importa lo elegido y, si es un único
/// documento, lo abre directamente.
Future<void> pickAndImportDocuments(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final router = GoRouter.of(context);

  final List<PlatformFile> files;
  try {
    files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: DocumentKind.allExtensions,
    );
  } on Object {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.importFailed(l10n.addDocument))),
    );
    return;
  }
  if (files.isEmpty) return;

  final result = await ref.read(libraryControllerProvider.notifier).import([
    for (final file in files)
      ImportCandidate(
        name: file.name,
        sizeBytes: file.lengthSync(),
        openRead: file.readAsByteStream,
      ),
  ]);

  messenger.hideCurrentSnackBar();
  if (result.unsupported.isNotEmpty) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.importUnsupported(result.unsupported.join(', '))),
      ),
    );
  } else if (result.failed.isNotEmpty) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.importFailed(result.failed.join(', ')))),
    );
  }

  if (result.added.length == 1) {
    await router.push(AppRoutes.reader(result.added.single.id));
  } else if (result.added.length > 1) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.importAdded(result.added.length))),
    );
  }
}
