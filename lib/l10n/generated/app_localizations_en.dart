// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Folio';

  @override
  String get navLibrary => 'Library';

  @override
  String get navHighlights => 'Highlights';

  @override
  String get navSettings => 'Settings';

  @override
  String get back => 'Back';

  @override
  String get moreOptions => 'More options';

  @override
  String get undo => 'Undo';

  @override
  String get retry => 'Retry';

  @override
  String get copied => 'Copied';

  @override
  String get libraryTitle => 'Library';

  @override
  String get librarySearchHint => 'Search documents';

  @override
  String get filterAll => 'All';

  @override
  String get kindPdf => 'PDF';

  @override
  String get kindWord => 'Word';

  @override
  String get kindSpreadsheet => 'Excel';

  @override
  String get kindText => 'Text';

  @override
  String get addDocument => 'Add document';

  @override
  String get addDocumentHint => 'PDF, Word, Excel or text';

  @override
  String get libraryEmptyTitle => 'Your library is empty';

  @override
  String get libraryEmptyBody =>
      'Open a PDF, a Word file or a spreadsheet. No ads, no distractions.';

  @override
  String get libraryOpenFile => 'Open file';

  @override
  String get libraryTrySamples => 'Try the samples';

  @override
  String get libraryNoResults => 'No documents match your search';

  @override
  String get documentNotStarted => 'Not started';

  @override
  String documentProgress(int percent) {
    return '$percent% read';
  }

  @override
  String get documentFinished => 'Finished';

  @override
  String get documentOpen => 'Open';

  @override
  String get documentRename => 'Rename';

  @override
  String get documentShare => 'Share';

  @override
  String get documentRemove => 'Remove from library';

  @override
  String documentRemoved(String title) {
    return '“$title” was removed from the library';
  }

  @override
  String get renameTitle => 'Rename';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String importAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents added',
      one: 'Document added',
    );
    return '$_temp0';
  }

  @override
  String importUnsupported(String names) {
    return 'Unsupported format: $names';
  }

  @override
  String importFailed(String names) {
    return 'Couldn\'t open: $names';
  }

  @override
  String get readerError => 'This document couldn\'t be read';

  @override
  String get readerErrorMissing =>
      'The file is no longer available on this device';

  @override
  String get readerErrorUnsupported => 'This format isn\'t supported yet';

  @override
  String get readerNotFound => 'This document is no longer in the library';

  @override
  String readerPageOf(int current, int total) {
    return '$current of $total';
  }

  @override
  String get readerGoToPage => 'Go to page';

  @override
  String get readerNightMode => 'Night mode';

  @override
  String get readerDayMode => 'Day mode';

  @override
  String get readerLockRotation => 'Lock rotation';

  @override
  String get readerUnlockRotation => 'Allow rotation';

  @override
  String get readerSearch => 'Search in document';

  @override
  String get readerSearchHint => 'Search…';

  @override
  String readerSearchCount(int current, int total) {
    return '$current of $total';
  }

  @override
  String get readerSearchNone => 'No results';

  @override
  String get readerSearchPrevious => 'Previous';

  @override
  String get readerSearchNext => 'Next';

  @override
  String get readerNavigate => 'Navigate';

  @override
  String get readerPages => 'Pages';

  @override
  String get readerOutline => 'Contents';

  @override
  String get readerBookmarks => 'Bookmarks';

  @override
  String get readerBookmarkAdd => 'Bookmark this page';

  @override
  String get readerBookmarkRemove => 'Remove bookmark';

  @override
  String readerBookmarkPage(int page) {
    return 'Page $page';
  }

  @override
  String get readerGo => 'Go';

  @override
  String get readerAppearance => 'Reading';

  @override
  String get readerTextSize => 'Text size';

  @override
  String get readerLineHeight => 'Line spacing';

  @override
  String get readerAmbience => 'Ambience';

  @override
  String get readingThemePaper => 'Paper';

  @override
  String get readingThemeSepia => 'Sepia';

  @override
  String get readingThemeNight => 'Night';

  @override
  String get readerEmpty => 'This document has no text to show';

  @override
  String get readerSheetEmpty => 'Empty sheet';

  @override
  String readerSheetTruncated(int rows) {
    return 'Showing the first $rows rows';
  }

  @override
  String get highlightCopy => 'Copy';

  @override
  String get highlightRemove => 'Remove highlight';

  @override
  String highlightColor(int index) {
    return 'Highlight with color $index';
  }

  @override
  String get highlightsTitle => 'Highlights';

  @override
  String get highlightsEmptyTitle => 'No highlights yet';

  @override
  String get highlightsEmptyBody =>
      'Select text in any document and pick a color, underline it or add a note.';

  @override
  String get highlightDeleted => 'Highlight deleted';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsReading => 'Reading';

  @override
  String get settingsPreview =>
      'A good page disappears: only the words and their reader remain.';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsPrivacyTitle => 'No ads, no tracking';

  @override
  String get settingsPrivacyBody =>
      'Folio shows no advertising and collects no data. Your documents stay on your device.';

  @override
  String get settingsFormatsTitle => 'Supported formats';

  @override
  String get settingsFormatsBody =>
      'PDF, Word (.docx), Excel (.xlsx), CSV, TXT and Markdown.';

  @override
  String get annotationUnderline => 'Underline';

  @override
  String get annotationNote => 'Note';

  @override
  String get annotationNoteHint => 'Write your note…';

  @override
  String annotationShareTitle(String title) {
    return 'Excerpt from “$title”';
  }

  @override
  String highlightsPage(int page) {
    return 'Page $page';
  }

  @override
  String get highlightsEditNote => 'Edit note';

  @override
  String get highlightsAddNote => 'Add note';

  @override
  String get highlightsUnderlined => 'Underlined';
}
