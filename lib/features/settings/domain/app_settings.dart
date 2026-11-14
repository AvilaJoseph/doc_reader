import 'package:doc_reader/core/theme/reading_theme.dart';
import 'package:doc_reader/core/ui.dart';

/// Preferencias del usuario: apariencia de la app y de la lectura.
@immutable
class AppSettings {
  const new({
    this.themeMode = ThemeMode.system,
    this.readingTheme = ReadingTheme.paper,
    this.fontSize = 19,
    this.lineHeight = 1.6,
  });

  static const double minFontSize = 14;
  static const double maxFontSize = 30;
  static const double minLineHeight = 1.2;
  static const double maxLineHeight = 2.1;

  final ThemeMode themeMode;
  final ReadingTheme readingTheme;
  final double fontSize;
  final double lineHeight;

  AppSettings copyWith({
    ThemeMode? themeMode,
    ReadingTheme? readingTheme,
    double? fontSize,
    double? lineHeight,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      readingTheme: readingTheme ?? this.readingTheme,
      fontSize: (fontSize ?? this.fontSize).clamp(minFontSize, maxFontSize),
      lineHeight: (lineHeight ?? this.lineHeight).clamp(
        minLineHeight,
        maxLineHeight,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.themeMode == themeMode &&
      other.readingTheme == readingTheme &&
      other.fontSize == fontSize &&
      other.lineHeight == lineHeight;

  @override
  int get hashCode =>
      Object.hash(themeMode, readingTheme, fontSize, lineHeight);
}
