# Arquitectura

## Visión general

```
                ┌──────────── app/ ─────────────┐
                │ App · router · AppShell       │
                └──────┬───────────────┬────────┘
                       │               │
        ┌──────────────▼──┐   ┌────────▼─────────┐
        │ features/library│   │ features/reader  │
        │  biblioteca,    │   │  ReaderPage →    │
        │  importación    │   │  PDF | Flow | Hoja│
        └──────┬──────────┘   └────────┬─────────┘
               │ providers             │ providers
        ┌──────▼──────────┐   ┌────────▼─────────┐
        │ highlights      │   │ settings         │
        └─────────────────┘   └──────────────────┘
                       core/ (tema, widgets, ui.dart)
```

Cada feature tiene cuatro capas:

| Capa | Contenido | Puede depender de |
|---|---|---|
| `domain` | Modelos inmutables, enums, interfaces de repositorio | nada de Flutter UI |
| `data` | Implementaciones: SharedPreferences, sistema de archivos | `domain` |
| `application` | Providers y Notifiers de Riverpod (casos de uso) | `domain`, `data` |
| `presentation` | Páginas y widgets | `application`, `domain`, `core` |

## Flujo de un documento

1. **Importar**: `pickAndImportDocuments` abre el selector del sistema y
   convierte cada archivo en un `ImportCandidate` (nombre + stream).
2. `LibraryController.import` detecta el tipo (`DocumentKind`), copia el
   archivo a la carpeta privada de la app (`DocumentFileStore`) y guarda un
   `LibraryDocument` en `LibraryRepository`.
3. **Abrir**: la ruta `/reader/:id` crea `ReaderPage`, que elige el visor
   según `DocumentKind`.
4. Los visores de texto y hojas piden los bytes a `documentBytesProvider` y
   los parsean en otro isolate (`flowDocumentProvider`, `workbookProvider`).
   El PDF lo abre `pdfrx` directamente desde el archivo.
5. El avance (`progress` 0..1) y la posición (`position`, que depende del
   visor) se guardan con `LibraryController.saveProgress`.

## Estado (Riverpod 3)

- `sharedPreferencesProvider` se sobreescribe en `main()` y en tests.
- Repositorios y almacenes son `Provider`s → se sustituyen en tests.
- Listas persistentes = `AsyncNotifier` (`libraryControllerProvider`,
  `highlightsControllerProvider`). Ajustes = `Notifier` síncrono.
- Datos derivados = `Provider`/`FutureProvider` (`filteredLibraryProvider`,
  `documentHighlightsProvider`, `flowDocumentProvider`…).

## Subrayados

Se anclan con `(documentId, blockIndex, start, end)` sobre el texto plano de
un `ParagraphBlock`. `buildHighlightedSpans` parte los `TextRun` en esos
límites para pintar el fondo. Cada párrafo es un `SelectableText.rich` con
`contextMenuBuilder` propio (`HighlightToolbar`).

## Persistencia

`SharedPreferences` con JSON versionado en la clave
(`library.documents.v1`, `highlights.v1`). Si la biblioteca crece (carpetas,
búsqueda de texto completo), implementar `LibraryRepository` con una base de
datos (p. ej. drift) sin tocar la UI.

## Añadir una feature

Ver `.claude/skills/new-feature/SKILL.md`.
