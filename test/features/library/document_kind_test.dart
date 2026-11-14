import 'package:doc_reader/features/library/domain/document_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detecta el tipo por extensión sin importar mayúsculas', () {
    expect(DocumentKind.fromFileName('Informe.PDF'), DocumentKind.pdf);
    expect(DocumentKind.fromFileName('carta.docx'), DocumentKind.word);
    expect(DocumentKind.fromFileName('datos.xlsx'), DocumentKind.spreadsheet);
    expect(DocumentKind.fromFileName('datos.csv'), DocumentKind.spreadsheet);
    expect(DocumentKind.fromFileName('notas.md'), DocumentKind.text);
    expect(DocumentKind.fromFileName('foto.JPG'), DocumentKind.image);
  });

  test('devuelve null para formatos no soportados', () {
    expect(DocumentKind.fromFileName('viejo.doc'), isNull);
    expect(DocumentKind.fromFileName('sin_extension'), isNull);
  });

  test('allExtensions incluye todas las extensiones', () {
    expect(
      DocumentKind.allExtensions,
      containsAll(['pdf', 'docx', 'xlsx', 'csv', 'txt']),
    );
  });
}
