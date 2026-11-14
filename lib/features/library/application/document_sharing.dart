import 'package:doc_reader/features/library/application/library_providers.dart';
import 'package:doc_reader/features/library/domain/document_source.dart';
import 'package:doc_reader/features/library/domain/library_document.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Abre la hoja de compartir del sistema con el archivo original.
Future<void> shareDocument(WidgetRef ref, LibraryDocument doc) async {
  final file = switch (doc.source) {
    FileSource(:final path) => XFile(path, name: doc.fileName),
    AssetSource() => XFile.fromData(
      await ref.read(documentFileStoreProvider).readBytes(doc.source),
      name: doc.fileName,
    ),
  };
  await SharePlus.instance.share(
    ShareParams(
      files: [file],
      title: doc.title,
      fileNameOverrides: [doc.fileName],
    ),
  );
}
