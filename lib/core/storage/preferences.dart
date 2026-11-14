import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Instancia de [SharedPreferences] cargada en `main()` antes de arrancar.
///
/// Se sobreescribe en el `ProviderScope` raíz (y en los tests).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider debe sobreescribirse en main()',
  ),
);
