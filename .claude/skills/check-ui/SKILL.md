---
name: check-ui
description: Ver la app Folio funcionando y revisar el diseño con capturas reales (build web + Playwright) en tema claro, oscuro y en cada visor.
---

# Revisar la UI con capturas

La app es móvil, pero la build web sirve para revisar el diseño sin
emulador. Los datos de ejemplo se inyectan en `localStorage` (formato de
`shared_preferences` web: clave `flutter.<clave>`).

1. Compila sin CDN (CanvasKit local, funciona sin acceso a gstatic):
   `flutter build web --release --no-web-resources-cdn`
2. Captura (Playwright ya instalado en el entorno):
   `node tool/screenshots/capture.js` → `build/screenshots/*.png`
   Para algunas: `node tool/screenshots/capture.js library-light reader-docx`
3. Mira las imágenes y compara con `docs/DESIGN.md`: márgenes, píldora sin
   tapar contenido importante, textos sin cortar, contraste en oscuro.
4. Si las capturas son para el README/PR, compón `docs/preview.png`.

Notas:
- Las pantallas disponibles y los documentos de ejemplo están al principio
  de `capture.js`; añade más ahí.
- La importación de archivos usa `dart:io` y no funciona en web; usa los
  ejemplos de `assets/samples/` (se regeneran con
  `python3 tool/generate_samples.py assets/samples`).
