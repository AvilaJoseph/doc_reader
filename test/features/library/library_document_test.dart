import 'package:doc_reader/features/library/domain/document_kind.dart';
import 'package:doc_reader/features/library/domain/document_source.dart';
import 'package:doc_reader/features/library/domain/library_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LibraryDocument se serializa y deserializa sin pérdidas', () {
    final doc = LibraryDocument(
      id: '1',
      title: 'Informe',
      fileName: 'informe.pdf',
      kind: DocumentKind.pdf,
      source: const FileSource('/tmp/a b/informe.pdf'),
      sizeBytes: 2048,
      addedAt: DateTime(2026, 1, 2),
      lastOpenedAt: DateTime(2026, 1, 3),
      progress: 0.5,
      position: 12,
      bookmarks: const [3, 9],
      favorite: true,
    );
    final copy = LibraryDocument.fromJson(doc.toJson());
    expect(copy, doc);
    expect(copy.source, const FileSource('/tmp/a b/informe.pdf'));
    expect(copy.kind, DocumentKind.pdf);
  });

  test('DocumentSource distingue archivos y assets', () {
    const asset = AssetSource('assets/samples/guia.pdf');
    expect(DocumentSource.decode(asset.encode()), asset);
  });
}
