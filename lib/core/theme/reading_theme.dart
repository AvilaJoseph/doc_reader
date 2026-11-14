import 'package:doc_reader/core/ui.dart';

/// Ambientes de lectura, independientes del tema claro/oscuro de la app.
enum ReadingTheme {
  paper(
    background: Color(0xFFFAF8F4),
    ink: Color(0xFF23201C),
    muted: Color(0xFF9A938A),
    brightness: Brightness.light,
  ),
  sepia(
    background: Color(0xFFF3EAD8),
    ink: Color(0xFF3B3025),
    muted: Color(0xFF9C8B74),
    brightness: Brightness.light,
  ),
  night(
    background: Color(0xFF141312),
    ink: Color(0xFFD9D3CA),
    muted: Color(0xFF7D766D),
    brightness: Brightness.dark,
  );

  new({
    required this.background,
    required this.ink,
    required this.muted,
    required this.brightness,
  });

  final Color background;
  final Color ink;
  final Color muted;
  final Brightness brightness;

  ReadingTheme get next => values[(index + 1) % values.length];
}
