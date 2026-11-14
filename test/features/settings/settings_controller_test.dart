import 'package:doc_reader/core/theme/reading_theme.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/features/settings/application/settings_controller.dart';
import 'package:doc_reader/features/settings/domain/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_app.dart';

void main() {
  test('carga valores por defecto y guarda cambios', () async {
    final container = await createContainer();
    addTearDown(container.dispose);

    expect(container.read(settingsControllerProvider), const AppSettings());

    container.read(settingsControllerProvider.notifier)
      ..setThemeMode(ThemeMode.dark)
      ..setReadingTheme(ReadingTheme.sepia)
      ..setFontSize(99);

    final settings = container.read(settingsControllerProvider);
    expect(settings.themeMode, ThemeMode.dark);
    expect(settings.readingTheme, ReadingTheme.sepia);
    expect(settings.fontSize, AppSettings.maxFontSize);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings.readingTheme'), 'sepia');
  });

  test('lee las preferencias guardadas', () async {
    final container = await createContainer(
      prefs: {'settings.themeMode': 'light', 'settings.fontSize': 22.0},
    );
    addTearDown(container.dispose);
    final settings = container.read(settingsControllerProvider);
    expect(settings.themeMode, ThemeMode.light);
    expect(settings.fontSize, 22);
  });
}
