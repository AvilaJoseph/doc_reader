# Folio — lector de documentos (Flutter)

App Android/iOS para leer **PDF, Word (.docx), Excel (.xlsx/.csv) y texto
(.txt/.md)** sin anuncios, sin rastreo y sin red. Interfaz minimalista y
cálida: biblioteca en cuadrícula, lector serif tranquilo, navegación en
píldora flotante y subrayados de colores.

Idioma del proyecto: **español** (UI, comentarios, commits y docs).

## Principio rector: velocidad y sencillez

Los lectores habituales son lentos y confusos; Folio gana siendo **rápido,
simple y eficiente**. Toda decisión pasa por este filtro:

- **Abrir al instante**: nada pesado en el arranque ni en `build()`;
  parsear en isolates (`compute`), cargar perezosamente (listas `.builder`,
  miniaturas a baja resolución) y cachear lo ya calculado.
- **Menos es más**: cada pantalla con una acción principal clara; nada de
  menús anidados, diálogos innecesarios ni opciones que casi nadie usa. Si
  una función complica la UI, va en "Más opciones" o no va.
- **Pocos toques**: lo frecuente (abrir, seguir leyendo, subrayar) a uno o
  dos toques. Recordar siempre la posición y las preferencias.
- **Sin esperas visibles**: mostrar contenido parcial antes que un spinner
  largo; animaciones cortas (≤ 250 ms).
- Antes de añadir una dependencia, valorar su peso y su coste de arranque.

## Comandos

```bash
flutter pub get                 # también genera lib/l10n/generated
flutter analyze                 # debe quedar en "No issues found!"
flutter test                    # unitarias + widgets
dart format lib test            # formato obligatorio
dart fix --apply                # arreglos automáticos de lints
flutter run                     # dispositivo/emulador
flutter build web --release --no-web-resources-cdn && \
  node tool/screenshots/capture.js   # capturas para revisar la UI
```

Antes de dar algo por terminado: `dart format`, `flutter analyze` sin
avisos y `flutter test` en verde.

## Arquitectura (feature-first)

```
lib/
  main.dart            arranque: SharedPreferences, fuentes, ProviderScope
  app/                 App, router (go_router), shell con píldora, rutas
  core/                código transversal sin lógica de negocio
    ui.dart            ÚNICO import de Material (ver "Reglas")
    theme/             colores, tipografías, tema, ambientes de lectura
    widgets/           widgets reutilizables (píldora, estados vacíos…)
    storage/ errors/ utils/
  features/<feature>/
    domain/            modelos inmutables y contratos (sin Flutter UI)
    data/              implementaciones (SharedPreferences, archivos…)
    application/       providers y Notifiers de Riverpod
    presentation/      páginas y widgets
  l10n/                ARB (es plantilla, en) + extensión context.l10n
```

Features: `library` (biblioteca e importación), `reader` (visores por
formato), `highlights` (subrayados), `settings` (preferencias).

Dependencias entre capas: `presentation → application → domain ← data`.
Una feature puede leer providers de otra, nunca sus widgets internos.

Detalle en `docs/ARCHITECTURE.md`; sistema de diseño en `docs/DESIGN.md`.

## Formatos de documento

- `features/reader/formats/flow/`: modelo `FlowDocument` (párrafos con
  estilo, listas, tablas, imágenes) + parsers `parseDocx`, `parseMarkdown`,
  `parsePlainText`. Un único visor (`FlowReaderScreen`) los pinta.
- `features/reader/formats/spreadsheet/`: modelo `Workbook/Sheet` +
  `parseXlsx`, `parseCsv` y `SpreadsheetView` (cuadrícula perezosa).
- PDF: `pdfrx` (PDFium) directamente en `PdfReaderScreen`.
- Los parsers son funciones puras top-level, se ejecutan con `compute()` y
  lanzan `DocumentParseException`. Tienen tests con archivos reales.
- Para añadir un formato usa la skill `.claude/skills/add-document-format`.

## Reglas

1. **Material solo vía `package:doc_reader/core/ui.dart`.** Flutter 3.47+
   movió Material a `material_ui`, pero go_router, pdfrx, etc. siguen en
   `flutter/material` y sus tipos no son compatibles. No añadas
   `material_ui` como dependencia.
2. **Textos siempre localizados**: añade la clave a `lib/l10n/app_es.arb`
   y `app_en.arb`, usa `context.l10n.clave`. Nada de cadenas sueltas en UI.
3. **Colores y medidas desde el tema**: `Theme.of(context).colorScheme`,
   `AppColors`, `AppSpacing`, `AppRadii`. No inventes colores en widgets.
4. **Estado con Riverpod 3** (`Notifier`/`AsyncNotifier`, sin codegen). Las
   dependencias (repositorios, almacenamiento) son providers para poder
   sobreescribirlos en tests. No uses `ref` en `dispose()`: guarda el
   notifier en `initState`.
5. **Navegación con `AppRoutes`** y `context.push/go`. El lector va fuera
   del shell de pestañas.
6. **Sin red**: fuentes empaquetadas en `assets/google_fonts/` y
   `GoogleFonts.config.allowRuntimeFetching = false`. Si usas un peso nuevo
   de Manrope/Literata, añade su `.ttf` (nombre `Familia-Variante.ttf`).
   Nada de analytics, anuncios ni SDKs que llamen a internet.
7. **Modelos inmutables** con `copyWith`, `==`/`hashCode` y `toJson` si se
   persisten. Persistencia detrás de una interfaz (`LibraryRepository`…).
8. **Tests**: cada parser y cada controller con su test. Widgets con
   `test/helpers/test_app.dart` (`localizedApp`, `createContainer`).
9. Estilo: `very_good_analysis`, 80 columnas, imports `package:`, comas
   finales. El SDK (Dart 3.14) pide `const new(...)` en constructores sin
   nombre de clase repetido; `dart fix --apply` lo hace solo.

## Trampas conocidas

- `excel` (pub) es incompatible con `pdfrx` (versiones de `archive`/`xml`),
  por eso XLSX se parsea a mano con `archive` + `xml`.
- `google_fonts` 9 ya usa `material_ui`: no llames a `*TextTheme()`; usa
  `GoogleFonts.x().fontFamily` o `GoogleFonts.x(textStyle: ...)`.
- `Center` sin `heightFactor` dentro de una píldora se expande a toda la
  altura (rompía la navegación).
- El lector de texto es una sola `SelectionArea`; cada párrafo informa de
  su parte de la selección con `SelectionListener` y
  `FlowSelectionRegistry` la convierte en fragmentos por párrafo.
- Web solo se usa para capturas/previsualización; los imports de archivos
  usan `dart:io` y no funcionan en web.

## Pendiente / ideas

- "Abrir con…" desde otras apps (intent VIEW en Android, Document Types en
  iOS) reutilizando `ImportCandidate`.
- Marcadores, índice (TOC) de PDF.
- Más formatos: .pptx, .odt, .epub, .rtf.
