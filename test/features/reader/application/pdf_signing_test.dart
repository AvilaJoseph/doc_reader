import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:doc_reader/features/library/application/library_controller.dart';
import 'package:doc_reader/features/library/application/library_providers.dart';
import 'package:doc_reader/features/library/data/cover_cache.dart';
import 'package:doc_reader/features/library/data/document_file_store.dart';
import 'package:doc_reader/features/library/domain/document_kind.dart';
import 'package:doc_reader/features/reader/application/pdf_signing.dart';
import 'package:doc_reader/features/reader/formats/pdf/pdf_stamper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  late Directory tempDir;
  late ProviderContainer container;
  List<PdfStamp>? received;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('signing_test');
    received = null;
    container = await createContainer(
      overrides: [
        documentFileStoreProvider.overrideWithValue(
          DocumentFileStore(baseDirectory: () async => tempDir),
        ),
        coverCacheProvider.overrideWithValue(
          CoverCache(baseDirectory: () async => tempDir),
        ),
        pdfStamperProvider.overrideWithValue((pdf, stamps) async {
          received = stamps;
          return Uint8List.fromList([...pdf, ...utf8.encode('firmado')]);
        }),
      ],
    );
    await container.read(libraryControllerProvider.future);
  });

  tearDown(() async {
    container.dispose();
    await tempDir.delete(recursive: true);
  });

  test('guarda una copia firmada sin tocar el original', () async {
    final library = container.read(libraryControllerProvider.notifier);
    final bytes = utf8.encode('%PDF-1.4 original');
    final original = (await library.import([
      ImportCandidate(
        name: 'Contrato.pdf',
        sizeBytes: bytes.length,
        openRead: () => Stream.value(bytes),
      ),
    ])).added.single;

    final stamp = PdfStamp(
      pageIndex: 0,
      left: 0.5,
      top: 0.8,
      width: 0.3,
      height: 0.1,
      rgba: Uint8List(4),
      pixelWidth: 1,
      pixelHeight: 1,
    );
    final copy = await container
        .read(pdfSigningProvider)
        .saveCopy(document: original, stamps: [stamp], suffix: 'firmado');

    expect(received, [stamp]);
    expect(copy!.fileName, 'Contrato (firmado).pdf');
    expect(copy.kind, DocumentKind.pdf);
    expect(copy.id, isNot(original.id));
    final store = container.read(documentFileStoreProvider);
    expect(
      utf8.decode(await store.readBytes(copy.source)),
      '%PDF-1.4 originalfirmado',
    );
    expect(
      utf8.decode(await store.readBytes(original.source)),
      '%PDF-1.4 original',
    );
  });

  test('recuerda la última firma', () {
    final png = Uint8List.fromList([1, 2, 3]);
    container.read(savedSignatureProvider.notifier).save(png);
    expect(container.read(savedSignatureProvider), png);
  });
}
