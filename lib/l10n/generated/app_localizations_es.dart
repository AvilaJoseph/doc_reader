// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Folio';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navHighlights => 'Subrayados';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get back => 'Volver';

  @override
  String get moreOptions => 'Más opciones';

  @override
  String get undo => 'Deshacer';

  @override
  String get retry => 'Reintentar';

  @override
  String get copied => 'Copiado';

  @override
  String get libraryTitle => 'Biblioteca';

  @override
  String get librarySearchHint => 'Buscar documentos';

  @override
  String get filterAll => 'Todos';

  @override
  String get kindPdf => 'PDF';

  @override
  String get kindWord => 'Word';

  @override
  String get kindSpreadsheet => 'Excel';

  @override
  String get kindText => 'Texto';

  @override
  String get addDocument => 'Añadir documento';

  @override
  String get addDocumentHint => 'PDF, Word, Excel o texto';

  @override
  String get libraryEmptyTitle => 'Tu biblioteca está vacía';

  @override
  String get libraryEmptyBody =>
      'Abre un PDF, un Word o una hoja de cálculo. Sin anuncios y sin distracciones.';

  @override
  String get libraryOpenFile => 'Abrir archivo';

  @override
  String get libraryTrySamples => 'Probar con ejemplos';

  @override
  String get libraryNoResults => 'Ningún documento coincide con la búsqueda';

  @override
  String get documentNotStarted => 'Sin empezar';

  @override
  String documentProgress(int percent) {
    return '$percent % leído';
  }

  @override
  String get documentFinished => 'Terminado';

  @override
  String get documentOpen => 'Abrir';

  @override
  String get documentRename => 'Cambiar nombre';

  @override
  String get documentShare => 'Compartir';

  @override
  String get documentRemove => 'Quitar de la biblioteca';

  @override
  String documentRemoved(String title) {
    return '«$title» se quitó de la biblioteca';
  }

  @override
  String get renameTitle => 'Cambiar nombre';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String importAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documentos añadidos',
      one: 'Documento añadido',
    );
    return '$_temp0';
  }

  @override
  String importUnsupported(String names) {
    return 'Formato no compatible: $names';
  }

  @override
  String importFailed(String names) {
    return 'No se pudo abrir: $names';
  }

  @override
  String get readerError => 'No se pudo leer este documento';

  @override
  String get readerErrorMissing =>
      'El archivo ya no está disponible en el dispositivo';

  @override
  String get readerErrorUnsupported => 'Este formato todavía no es compatible';

  @override
  String get readerNotFound => 'Este documento ya no está en la biblioteca';

  @override
  String readerPageOf(int current, int total) {
    return '$current de $total';
  }

  @override
  String get readerGoToPage => 'Ir a la página';

  @override
  String get readerNightMode => 'Modo noche';

  @override
  String get readerDayMode => 'Modo día';

  @override
  String get readerLockRotation => 'Bloquear giro';

  @override
  String get readerUnlockRotation => 'Permitir giro';

  @override
  String get readerSearch => 'Buscar en el documento';

  @override
  String get readerSearchHint => 'Buscar…';

  @override
  String readerSearchCount(int current, int total) {
    return '$current de $total';
  }

  @override
  String get readerSearchNone => 'Sin resultados';

  @override
  String get readerSearchPrevious => 'Anterior';

  @override
  String get readerSearchNext => 'Siguiente';

  @override
  String get readerGo => 'Ir';

  @override
  String get readerAppearance => 'Lectura';

  @override
  String get readerTextSize => 'Tamaño de letra';

  @override
  String get readerLineHeight => 'Interlineado';

  @override
  String get readerAmbience => 'Ambiente';

  @override
  String get readingThemePaper => 'Papel';

  @override
  String get readingThemeSepia => 'Sepia';

  @override
  String get readingThemeNight => 'Noche';

  @override
  String get readerEmpty => 'Este documento no tiene texto que mostrar';

  @override
  String get readerSheetEmpty => 'Hoja vacía';

  @override
  String readerSheetTruncated(int rows) {
    return 'Se muestran las primeras $rows filas';
  }

  @override
  String get highlightCopy => 'Copiar';

  @override
  String get highlightRemove => 'Quitar subrayado';

  @override
  String highlightColor(int index) {
    return 'Subrayar en color $index';
  }

  @override
  String get highlightsTitle => 'Subrayados';

  @override
  String get highlightsEmptyTitle => 'Aún no hay subrayados';

  @override
  String get highlightsEmptyBody =>
      'Selecciona texto en cualquier documento y elige un color, subraya o añade una nota.';

  @override
  String get highlightDeleted => 'Subrayado eliminado';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get settingsReading => 'Lectura';

  @override
  String get settingsPreview =>
      'Una buena página desaparece: solo quedan las palabras y quien las lee.';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsPrivacyTitle => 'Sin anuncios ni rastreo';

  @override
  String get settingsPrivacyBody =>
      'Folio no muestra publicidad ni recopila datos. Tus documentos se quedan en tu dispositivo.';

  @override
  String get settingsFormatsTitle => 'Formatos compatibles';

  @override
  String get settingsFormatsBody =>
      'PDF, Word (.docx), Excel (.xlsx), CSV, TXT y Markdown.';

  @override
  String get annotationUnderline => 'Subrayar';

  @override
  String get annotationNote => 'Nota';

  @override
  String get annotationNoteHint => 'Escribe tu nota…';

  @override
  String annotationShareTitle(String title) {
    return 'Fragmento de «$title»';
  }

  @override
  String highlightsPage(int page) {
    return 'Pág. $page';
  }

  @override
  String get highlightsEditNote => 'Editar nota';

  @override
  String get highlightsAddNote => 'Añadir nota';

  @override
  String get highlightsUnderlined => 'Subrayado';
}
