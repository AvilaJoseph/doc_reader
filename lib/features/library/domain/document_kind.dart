import 'package:path/path.dart' as p;

/// Familias de documentos que la app sabe abrir.
///
/// Para soportar un formato nuevo: añade su extensión aquí, escribe el
/// parser en `features/reader/formats/` y conéctalo en `ReaderPage`.
/// Ver `.claude/skills/add-document-format/SKILL.md`.
enum DocumentKind {
  pdf(extensions: {'pdf'}),
  word(extensions: {'docx', 'rtf'}),
  spreadsheet(extensions: {'xlsx', 'csv', 'tsv'}),
  text(extensions: {'txt', 'md', 'markdown', 'text', 'log', 'epub'}),
  image(extensions: {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'});

  new({required this.extensions});

  final Set<String> extensions;

  /// Todas las extensiones admitidas (para el selector de archivos).
  static List<String> get allExtensions => [
    for (final kind in values) ...kind.extensions,
  ];

  /// Devuelve el tipo para un nombre o ruta de archivo, o `null`.
  static DocumentKind? fromFileName(String fileName) {
    final ext = extensionOf(fileName);
    for (final kind in values) {
      if (kind.extensions.contains(ext)) return kind;
    }
    return null;
  }

  /// Extensión en minúsculas y sin punto.
  static String extensionOf(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    return ext.startsWith('.') ? ext.substring(1) : ext;
  }
}
