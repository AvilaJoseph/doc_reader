# Sistema de diseño

Inspiración: lectores minimalistas con biblioteca de portadas, tipografía
serif para leer y controles flotantes oscuros. Sin marcas ni recursos de
terceros: todo (portadas, colores, iconos) es propio.

## Principios

1. **El texto manda.** Nada compite con el documento: sin banners, sin
   barras pesadas. Los controles flotan y se esconden al hacer scroll.
2. **Cálido y tranquilo.** Papel crema en claro, carbón cálido en oscuro.
3. **Objetos físicos.** Portadas con proporción de libro y sombra de lomo;
   la píldora de navegación es un objeto oscuro en ambos temas.

## Tokens (`lib/core/theme/`)

| Token | Claro | Oscuro |
|---|---|---|
| Fondo | `#F7F4EF` | `#121110` |
| Superficie | `#FFFFFF` | `#1C1A18` |
| Superficie apagada | `#EFEBE4` | `#262321` |
| Tinta | `#1E1B18` | `#F2EEE8` |
| Tinta secundaria | `#8A847C` | `#948D84` |
| Línea | `#E3DDD3` | `#34302C` |
| Píldora | `#232120` (92 % + desenfoque) | igual |

Acentos por tipo (apagados): PDF `#B4533A`, Word `#3F5E9A`,
Excel `#2F7652`, Texto `#6B6259`.

Subrayados: mantequilla `#F3DC8C`, menta `#B9E3D6`, lavanda `#CAC4F2`,
melocotón `#F2C3B3` (al 42 % sobre el ambiente Noche).

Ambientes de lectura (`ReadingTheme`): Papel `#FAF8F4`, Sepia `#F3EAD8`,
Noche `#141312`.

## Tipografía

- **Manrope** (UI): títulos de página `headlineMedium` w800, −0.8 de
  tracking; etiquetas w600.
- **Literata** (lectura): 19 px por defecto, interlineado 1.6; encabezados
  ×1.55 / ×1.3 / ×1.15.
- **JetBrains Mono** (código en Markdown), solo Regular.

Las fuentes van empaquetadas (OFL) en `assets/google_fonts/`.

## Espaciado y forma

`AppSpacing`: 4 · 8 · 16 · 24 · 32; margen de página 20; hueco inferior de
112 para la píldora. `AppRadii`: tarjetas 6, campos 16, hojas 28, píldoras
totalmente redondas.

## Componentes

- `FloatingPill` + `PillButton`: navegación principal (icono sobre texto) y
  barras del lector (icono + texto).
- `CircleIconButton`: volver / más opciones.
- `FilterPill`: filtros de la biblioteca.
- `DocumentCard` / `DocumentCover` / `AddDocumentCard` (borde discontinuo).
- `HighlightToolbar`: puntos de color + copiar + quitar.
- `EmptyState`: icono, título, texto y acciones.

## Capturas

`docs/preview.png`. Para regenerarlas:
`flutter build web --release --no-web-resources-cdn && node tool/screenshots/capture.js`.
