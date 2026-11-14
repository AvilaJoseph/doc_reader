import 'package:doc_reader/core/ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografías de la app.
///
/// - Interfaz: Manrope (grotesca geométrica, limpia).
/// - Lectura: Literata (serif diseñada para pantallas).
///
/// Las fuentes van empaquetadas en `assets/google_fonts/` y la descarga en
/// tiempo de ejecución está desactivada (ver `main.dart`): la app no hace
/// peticiones de red. Si usas un peso o estilo nuevo, añade su .ttf a esa
/// carpeta (nombre `Familia-Variante.ttf`) o google_fonts fallará.
abstract final class AppTypography {
  /// Se desactiva en tests para no hacer peticiones de red.
  static bool useGoogleFonts = true;

  static TextTheme uiTextTheme(TextTheme base) {
    final themed = base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        height: 1.05,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
    // google_fonts ya usa `material_ui`, así que aplicamos solo la familia
    // (TextStyle es común a ambos paquetes).
    return useGoogleFonts
        ? themed.apply(fontFamily: GoogleFonts.manrope().fontFamily)
        : themed;
  }

  /// Estilo base del texto de lectura.
  static TextStyle reading({
    required Color color,
    required double fontSize,
    required double height,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    final style = TextStyle(
      color: color,
      fontSize: fontSize,
      height: height,
      fontWeight: fontWeight,
    );
    return useGoogleFonts
        ? GoogleFonts.literata(textStyle: style)
        : style.copyWith(fontFamily: 'serif');
  }

  /// Serif para títulos de portadas y encabezados de lectura.
  static TextStyle serifDisplay(TextStyle base) => useGoogleFonts
      ? GoogleFonts.literata(textStyle: base)
      : base.copyWith(fontFamily: 'serif');

  /// Monoespaciada para fragmentos de código (solo se empaqueta Regular).
  static TextStyle mono(TextStyle base) {
    final regular = base.copyWith(
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
    );
    return useGoogleFonts
        ? GoogleFonts.jetBrainsMono(textStyle: regular)
        : regular.copyWith(fontFamily: 'monospace');
  }
}
