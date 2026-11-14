import 'package:doc_reader/core/storage/preferences.dart';
import 'package:doc_reader/core/theme/app_theme.dart';
import 'package:doc_reader/core/theme/app_typography.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Envuelve [child] con tema y localización en español, sin fuentes de red.
Widget localizedApp(Widget child) {
  AppTypography.useGoogleFonts = false;
  return MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

/// Contenedor de Riverpod con SharedPreferences en memoria.
Future<ProviderContainer> createContainer({
  Map<String, Object> prefs = const {},
  List<Override> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final instance = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(instance),
      ...overrides,
    ],
  );
  return container;
}
