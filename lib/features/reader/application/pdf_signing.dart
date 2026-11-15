import 'dart:async';
import 'dart:convert';

import 'package:doc_reader/core/storage/preferences.dart';
import 'package:doc_reader/features/library/application/library_controller.dart';
import 'package:doc_reader/features/library/application/library_providers.dart';
import 'package:doc_reader/features/library/data/document_file_store.dart';
import 'package:doc_reader/features/library/domain/library_document.dart';
import 'package:doc_reader/features/reader/formats/pdf/pdf_stamper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Incrusta las marcas en el PDF. Sobreescríbelo en tests.
final pdfStamperProvider =
    Provider<Future<Uint8List> Function(Uint8List, List<PdfStamp>)>(
      (ref) => stampPdf,
    );

/// Última firma dibujada (PNG), recordada para firmar con un toque.
final savedSignatureProvider = NotifierProvider<SavedSignature, Uint8List?>(
  SavedSignature.new,
);

class SavedSignature extends Notifier<Uint8List?> {
  static const _key = 'sign.signature';

  @override
  Uint8List? build() {
    final encoded = ref.watch(sharedPreferencesProvider).getString(_key);
    if (encoded == null) return null;
    try {
      return base64Decode(encoded);
    } on FormatException {
      return null;
    }
  }

  void save(Uint8List png) {
    state = png;
    unawaited(
      ref.read(sharedPreferencesProvider).setString(_key, base64Encode(png)),
    );
  }
}

final pdfSigningProvider = Provider<PdfSigning>(PdfSigning.new);

/// Guarda copias firmadas de los PDF en la biblioteca.
class PdfSigning {
  const new(this._ref);

  final Ref _ref;

  /// Guarda una copia de [document] con [stamps] incrustadas.
  ///
  /// El original no se toca: la copia se llama `<título> (<sufijo>).pdf`.
  /// Devuelve el documento nuevo, o `null` si no se pudo importar.
  Future<LibraryDocument?> saveCopy({
    required LibraryDocument document,
    required List<PdfStamp> stamps,
    required String suffix,
  }) async {
    final original = await _ref
        .read(documentFileStoreProvider)
        .readBytes(document.source);
    final bytes = await _ref.read(pdfStamperProvider)(original, stamps);
    final result = await _ref.read(libraryControllerProvider.notifier).import([
      ImportCandidate(
        name: '${document.title} ($suffix).pdf',
        sizeBytes: bytes.length,
        openRead: () => Stream.value(bytes),
      ),
    ]);
    return result.added.firstOrNull;
  }
}
