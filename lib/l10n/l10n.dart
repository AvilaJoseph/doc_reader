import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/l10n/generated/app_localizations.dart';

export 'package:doc_reader/l10n/generated/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  /// Textos localizados: `context.l10n.libraryTitle`.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
