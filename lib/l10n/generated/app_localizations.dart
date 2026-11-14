import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Folio'**
  String get appTitle;

  /// No description provided for @navLibrary.
  ///
  /// In es, this message translates to:
  /// **'Biblioteca'**
  String get navLibrary;

  /// No description provided for @navHighlights.
  ///
  /// In es, this message translates to:
  /// **'Subrayados'**
  String get navHighlights;

  /// No description provided for @navSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get navSettings;

  /// No description provided for @back.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get back;

  /// No description provided for @moreOptions.
  ///
  /// In es, this message translates to:
  /// **'Más opciones'**
  String get moreOptions;

  /// No description provided for @undo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get undo;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @copied.
  ///
  /// In es, this message translates to:
  /// **'Copiado'**
  String get copied;

  /// No description provided for @libraryTitle.
  ///
  /// In es, this message translates to:
  /// **'Biblioteca'**
  String get libraryTitle;

  /// No description provided for @librarySearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar documentos'**
  String get librarySearchHint;

  /// No description provided for @filterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get filterAll;

  /// No description provided for @kindPdf.
  ///
  /// In es, this message translates to:
  /// **'PDF'**
  String get kindPdf;

  /// No description provided for @kindWord.
  ///
  /// In es, this message translates to:
  /// **'Word'**
  String get kindWord;

  /// No description provided for @kindSpreadsheet.
  ///
  /// In es, this message translates to:
  /// **'Excel'**
  String get kindSpreadsheet;

  /// No description provided for @kindText.
  ///
  /// In es, this message translates to:
  /// **'Texto'**
  String get kindText;

  /// No description provided for @addDocument.
  ///
  /// In es, this message translates to:
  /// **'Añadir documento'**
  String get addDocument;

  /// No description provided for @addDocumentHint.
  ///
  /// In es, this message translates to:
  /// **'PDF, Word, Excel o texto'**
  String get addDocumentHint;

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu biblioteca está vacía'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Abre un PDF, un Word o una hoja de cálculo. Sin anuncios y sin distracciones.'**
  String get libraryEmptyBody;

  /// No description provided for @libraryOpenFile.
  ///
  /// In es, this message translates to:
  /// **'Abrir archivo'**
  String get libraryOpenFile;

  /// No description provided for @libraryTrySamples.
  ///
  /// In es, this message translates to:
  /// **'Probar con ejemplos'**
  String get libraryTrySamples;

  /// No description provided for @libraryNoResults.
  ///
  /// In es, this message translates to:
  /// **'Ningún documento coincide con la búsqueda'**
  String get libraryNoResults;

  /// No description provided for @documentNotStarted.
  ///
  /// In es, this message translates to:
  /// **'Sin empezar'**
  String get documentNotStarted;

  /// No description provided for @documentProgress.
  ///
  /// In es, this message translates to:
  /// **'{percent} % leído'**
  String documentProgress(int percent);

  /// No description provided for @documentFinished.
  ///
  /// In es, this message translates to:
  /// **'Terminado'**
  String get documentFinished;

  /// No description provided for @documentOpen.
  ///
  /// In es, this message translates to:
  /// **'Abrir'**
  String get documentOpen;

  /// No description provided for @documentRename.
  ///
  /// In es, this message translates to:
  /// **'Cambiar nombre'**
  String get documentRename;

  /// No description provided for @documentShare.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get documentShare;

  /// No description provided for @documentRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar de la biblioteca'**
  String get documentRemove;

  /// No description provided for @documentRemoved.
  ///
  /// In es, this message translates to:
  /// **'«{title}» se quitó de la biblioteca'**
  String documentRemoved(String title);

  /// No description provided for @renameTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambiar nombre'**
  String get renameTitle;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @importAdded.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Documento añadido} other{{count} documentos añadidos}}'**
  String importAdded(int count);

  /// No description provided for @importUnsupported.
  ///
  /// In es, this message translates to:
  /// **'Formato no compatible: {names}'**
  String importUnsupported(String names);

  /// No description provided for @importFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir: {names}'**
  String importFailed(String names);

  /// No description provided for @readerError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo leer este documento'**
  String get readerError;

  /// No description provided for @readerErrorMissing.
  ///
  /// In es, this message translates to:
  /// **'El archivo ya no está disponible en el dispositivo'**
  String get readerErrorMissing;

  /// No description provided for @readerErrorUnsupported.
  ///
  /// In es, this message translates to:
  /// **'Este formato todavía no es compatible'**
  String get readerErrorUnsupported;

  /// No description provided for @readerNotFound.
  ///
  /// In es, this message translates to:
  /// **'Este documento ya no está en la biblioteca'**
  String get readerNotFound;

  /// No description provided for @readerPageOf.
  ///
  /// In es, this message translates to:
  /// **'{current} de {total}'**
  String readerPageOf(int current, int total);

  /// No description provided for @readerGoToPage.
  ///
  /// In es, this message translates to:
  /// **'Ir a la página'**
  String get readerGoToPage;

  /// No description provided for @readerGo.
  ///
  /// In es, this message translates to:
  /// **'Ir'**
  String get readerGo;

  /// No description provided for @readerAppearance.
  ///
  /// In es, this message translates to:
  /// **'Lectura'**
  String get readerAppearance;

  /// No description provided for @readerTextSize.
  ///
  /// In es, this message translates to:
  /// **'Tamaño de letra'**
  String get readerTextSize;

  /// No description provided for @readerLineHeight.
  ///
  /// In es, this message translates to:
  /// **'Interlineado'**
  String get readerLineHeight;

  /// No description provided for @readerAmbience.
  ///
  /// In es, this message translates to:
  /// **'Ambiente'**
  String get readerAmbience;

  /// No description provided for @readingThemePaper.
  ///
  /// In es, this message translates to:
  /// **'Papel'**
  String get readingThemePaper;

  /// No description provided for @readingThemeSepia.
  ///
  /// In es, this message translates to:
  /// **'Sepia'**
  String get readingThemeSepia;

  /// No description provided for @readingThemeNight.
  ///
  /// In es, this message translates to:
  /// **'Noche'**
  String get readingThemeNight;

  /// No description provided for @readerEmpty.
  ///
  /// In es, this message translates to:
  /// **'Este documento no tiene texto que mostrar'**
  String get readerEmpty;

  /// No description provided for @readerSheetEmpty.
  ///
  /// In es, this message translates to:
  /// **'Hoja vacía'**
  String get readerSheetEmpty;

  /// No description provided for @readerSheetTruncated.
  ///
  /// In es, this message translates to:
  /// **'Se muestran las primeras {rows} filas'**
  String readerSheetTruncated(int rows);

  /// No description provided for @highlightCopy.
  ///
  /// In es, this message translates to:
  /// **'Copiar'**
  String get highlightCopy;

  /// No description provided for @highlightRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar subrayado'**
  String get highlightRemove;

  /// No description provided for @highlightColor.
  ///
  /// In es, this message translates to:
  /// **'Subrayar en color {index}'**
  String highlightColor(int index);

  /// No description provided for @highlightsTitle.
  ///
  /// In es, this message translates to:
  /// **'Subrayados'**
  String get highlightsTitle;

  /// No description provided for @highlightsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay subrayados'**
  String get highlightsEmptyTitle;

  /// No description provided for @highlightsEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Selecciona texto en cualquier documento y elige un color, subraya o añade una nota.'**
  String get highlightsEmptyBody;

  /// No description provided for @highlightDeleted.
  ///
  /// In es, this message translates to:
  /// **'Subrayado eliminado'**
  String get highlightDeleted;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get settingsAppearance;

  /// No description provided for @themeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get themeDark;

  /// No description provided for @settingsReading.
  ///
  /// In es, this message translates to:
  /// **'Lectura'**
  String get settingsReading;

  /// No description provided for @settingsPreview.
  ///
  /// In es, this message translates to:
  /// **'Una buena página desaparece: solo quedan las palabras y quien las lee.'**
  String get settingsPreview;

  /// No description provided for @settingsAbout.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get settingsAbout;

  /// No description provided for @settingsPrivacyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin anuncios ni rastreo'**
  String get settingsPrivacyTitle;

  /// No description provided for @settingsPrivacyBody.
  ///
  /// In es, this message translates to:
  /// **'Folio no muestra publicidad ni recopila datos. Tus documentos se quedan en tu dispositivo.'**
  String get settingsPrivacyBody;

  /// No description provided for @settingsFormatsTitle.
  ///
  /// In es, this message translates to:
  /// **'Formatos compatibles'**
  String get settingsFormatsTitle;

  /// No description provided for @settingsFormatsBody.
  ///
  /// In es, this message translates to:
  /// **'PDF, Word (.docx), Excel (.xlsx), CSV, TXT y Markdown.'**
  String get settingsFormatsBody;

  /// No description provided for @annotationUnderline.
  ///
  /// In es, this message translates to:
  /// **'Subrayar'**
  String get annotationUnderline;

  /// No description provided for @annotationNote.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get annotationNote;

  /// No description provided for @annotationNoteHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu nota…'**
  String get annotationNoteHint;

  /// No description provided for @annotationShareTitle.
  ///
  /// In es, this message translates to:
  /// **'Fragmento de «{title}»'**
  String annotationShareTitle(String title);

  /// No description provided for @highlightsPage.
  ///
  /// In es, this message translates to:
  /// **'Pág. {page}'**
  String highlightsPage(int page);

  /// No description provided for @highlightsEditNote.
  ///
  /// In es, this message translates to:
  /// **'Editar nota'**
  String get highlightsEditNote;

  /// No description provided for @highlightsAddNote.
  ///
  /// In es, this message translates to:
  /// **'Añadir nota'**
  String get highlightsAddNote;

  /// No description provided for @highlightsUnderlined.
  ///
  /// In es, this message translates to:
  /// **'Subrayado'**
  String get highlightsUnderlined;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
