---
name: add-document-format
description: Añadir soporte para un nuevo formato de documento (p. ej. .pptx, .odt, .epub, .rtf) al lector Folio, desde la detección de extensión hasta el visor y los tests.
---

# Añadir un formato de documento

1. **Decide el modelo de destino**
   - Texto con párrafos/listas/tablas → `FlowDocument`
     (`lib/features/reader/formats/flow/flow_document.dart`).
   - Tabla/celdas → `Workbook`/`Sheet`
     (`lib/features/reader/formats/spreadsheet/workbook.dart`).
   - Algo que no encaja (diapositivas, imágenes por página) → crea un modelo
     nuevo en `lib/features/reader/formats/<formato>/` y su visor.
   Prefiere reutilizar un modelo existente: así el visor, los subrayados y
   los ajustes de lectura funcionan sin más trabajo.

2. **Registra la extensión** en `DocumentKind`
   (`lib/features/library/domain/document_kind.dart`). Si es un tipo nuevo
   de verdad, añade el valor del enum y luego resuelve todos los `switch`
   que el analizador marque (icono/acento en `document_cover.dart`, etiqueta
   en `document_card.dart`, filtro en `library_page.dart`, visor en
   `reader_page.dart`) y su texto en los ARB.

3. **Escribe el parser** como función pura top-level
   `Modelo parseX(Uint8List bytes)` en `formats/<familia>/x_parser.dart`:
   - Sin Flutter UI ni I/O; debe poder ir en `compute()`.
   - Errores → `DocumentParseException` (`lib/core/errors/app_exception.dart`).
   - Para ZIP/XML usa `archive` y `xml` (ya están; no añadas `excel`, choca
     con `pdfrx`).
   - Limita tamaños (ver `SheetLimits`) para no bloquear con archivos enormes.

4. **Conéctalo** en `lib/features/reader/application/document_providers.dart`
   (el `switch` por extensión de `flowDocumentProvider` o `workbookProvider`).

5. **Tests** en `test/features/reader/formats/<familia>/`:
   - Genera un archivo real (python-docx, openpyxl, reportlab… o construye el
     ZIP en memoria) y guárdalo en `test/fixtures/` si es pequeño.
   - Cubre: caso feliz, estilos/estructura, bytes inválidos → excepción.

6. **Textos**: actualiza `settingsFormatsBody` en `lib/l10n/app_*.arb` y la
   lista de formatos del README.

7. **Verifica**: `dart format lib test && flutter analyze && flutter test`.
   Si cambia la UI, regenera capturas con la skill `check-ui`.
