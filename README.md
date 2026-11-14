# Folio

Lector de documentos para Android e iOS hecho con Flutter: **PDF, Word,
Excel, CSV, TXT y Markdown** en una sola app, **sin anuncios, sin rastreo y
sin conexión**.

![Capturas de Folio](docs/preview.png)

## Qué hace

- **Biblioteca** en cuadrícula con portadas (primera página para PDF,
  portada tipográfica para el resto), búsqueda sin tildes y filtros por tipo.
- **Lector de texto** (Word, TXT, Markdown) con tipografía serif, tamaño e
  interlineado ajustables y ambientes Papel, Sepia y Noche.
- **Subrayados** de cuatro colores al seleccionar texto, reunidos en su
  propia pestaña.
- **PDF** con zoom, selección de texto e ir a página.
- **Hojas de cálculo** con cabeceras fijas, varias hojas y fechas/números
  formateados.
- Recuerda por dónde ibas en cada documento.
- Tema claro/oscuro y textos en español e inglés.

## Empezar

```bash
flutter pub get
flutter run
```

Requiere Flutter 3.50 (Dart 3.14) o superior.

## Desarrollo

- Reglas y comandos: [`CLAUDE.md`](CLAUDE.md)
- Arquitectura: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- Sistema de diseño: [`docs/DESIGN.md`](docs/DESIGN.md)
- Skills para Claude Code en `.claude/skills/` (añadir formato, nueva
  funcionalidad, revisar UI) y un agente revisor en `.claude/agents/`.

```bash
dart format lib test && flutter analyze && flutter test
```

## Licencias

Código bajo la licencia del repositorio. Tipografías Manrope, Literata y
JetBrains Mono bajo SIL Open Font License 1.1
(`assets/google_fonts/OFL.txt`).
