import 'package:doc_reader/core/ui.dart';

/// Paleta base. Cálida, de bajo contraste cromático, pensada para leer.
///
/// No uses colores sueltos en los widgets: añade aquí un token con nombre
/// semántico y consúmelo vía [Theme] o [AppColors].
abstract final class AppColors {
  // Claro: papel cálido.
  static const Color lightBackground = Color(0xFFF7F4EF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceMuted = Color(0xFFEFEBE4);
  static const Color lightInk = Color(0xFF1E1B18);
  static const Color lightInkMuted = Color(0xFF8A847C);
  static const Color lightLine = Color(0xFFE3DDD3);

  // Oscuro: biblioteca de noche.
  static const Color darkBackground = Color(0xFF121110);
  static const Color darkSurface = Color(0xFF1C1A18);
  static const Color darkSurfaceMuted = Color(0xFF262321);
  static const Color darkInk = Color(0xFFF2EEE8);
  static const Color darkInkMuted = Color(0xFF948D84);
  static const Color darkLine = Color(0xFF34302C);

  // Píldora flotante (igual en ambos temas, como un objeto físico).
  static const Color pill = Color(0xFF232120);
  static const Color pillSelected = Color(0xFF3A3734);
  static const Color pillInk = Color(0xFFF4F1EC);
  static const Color pillInkMuted = Color(0xFFA19B93);

  // Portadas generadas.
  static const Color coverPaper = Color(0xFFF3EEE3);
  static const Color coverInk = Color(0xFF2B2622);

  // Acentos por tipo de documento (apagados, nada chillón).
  static const Color kindPdf = Color(0xFFB4533A);
  static const Color kindWord = Color(0xFF3F5E9A);
  static const Color kindSheet = Color(0xFF2F7652);
  static const Color kindText = Color(0xFF6B6259);
  static const Color kindImage = Color(0xFF7A5A9E);
  static const Color kindSlides = Color(0xFFC0702E);

  /// Selección de texto: el azul clásico de Android.
  static const Color selection = Color(0x662F7CF6);
  static const Color selectionHandle = Color(0xFF2F7CF6);

  /// Color de la línea de "Subrayar".
  static const Color underline = Color(0xFF2F7CF6);

  /// Coincidencias de búsqueda y la coincidencia actual (más intensa).
  static const Color searchMatch = Color(0x55FFB020);
  static const Color searchCurrent = Color(0xCCFF9500);

  /// Subrayado sobre fondos oscuros (más claro para que se vea).
  static const Color underlineNight = Color(0xFF6EA8FF);

  /// Colores del resaltador (fondo translúcido sobre el texto).
  static const List<Color> highlights = [
    Color(0xFFF3DC8C), // mantequilla
    Color(0xFFB9E3D6), // menta
    Color(0xFFCAC4F2), // lavanda
    Color(0xFFF2C3B3), // melocotón
  ];
}
