import 'package:doc_reader/features/library/domain/document_kind.dart';

/// Documentos de ejemplo empaquetados en `assets/samples/`.
abstract final class SampleDocuments {
  static const all = <({String title, String asset})>[
    (title: 'Bienvenida a Folio', asset: 'assets/samples/bienvenida.docx'),
    (title: 'Guía de lectura', asset: 'assets/samples/guia.pdf'),
    (title: 'Presupuesto mensual', asset: 'assets/samples/presupuesto.xlsx'),
    (title: 'Notas de ideas', asset: 'assets/samples/notas.md'),
  ];

  static DocumentKind kindOf(String asset) =>
      DocumentKind.fromFileName(asset) ?? DocumentKind.text;
}
