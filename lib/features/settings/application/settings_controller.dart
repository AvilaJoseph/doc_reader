import 'dart:async';

import 'package:doc_reader/core/storage/preferences.dart';
import 'package:doc_reader/core/theme/reading_theme.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/features/settings/domain/app_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

/// Lee y guarda [AppSettings] en SharedPreferences (síncrono al leer).
class SettingsController extends Notifier<AppSettings> {
  static const _themeModeKey = 'settings.themeMode';
  static const _readingThemeKey = 'settings.readingTheme';
  static const _fontSizeKey = 'settings.fontSize';
  static const _lineHeightKey = 'settings.lineHeight';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    const defaults = AppSettings();
    return defaults.copyWith(
      themeMode: _byName(ThemeMode.values, prefs.getString(_themeModeKey)),
      readingTheme: _byName(
        ReadingTheme.values,
        prefs.getString(_readingThemeKey),
      ),
      fontSize: prefs.getDouble(_fontSizeKey),
      lineHeight: prefs.getDouble(_lineHeightKey),
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    unawaited(
      ref.read(sharedPreferencesProvider).setString(_themeModeKey, mode.name),
    );
  }

  void setReadingTheme(ReadingTheme theme) {
    state = state.copyWith(readingTheme: theme);
    unawaited(
      ref
          .read(sharedPreferencesProvider)
          .setString(_readingThemeKey, theme.name),
    );
  }

  void setFontSize(double size) {
    state = state.copyWith(fontSize: size);
    unawaited(
      ref
          .read(sharedPreferencesProvider)
          .setDouble(_fontSizeKey, state.fontSize),
    );
  }

  void setLineHeight(double height) {
    state = state.copyWith(lineHeight: height);
    unawaited(
      ref
          .read(sharedPreferencesProvider)
          .setDouble(_lineHeightKey, state.lineHeight),
    );
  }

  static T? _byName<T extends Enum>(List<T> values, String? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
