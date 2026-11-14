import 'dart:convert';

import 'package:doc_reader/app/app.dart';
import 'package:doc_reader/core/storage/preferences.dart';
import 'package:doc_reader/core/theme/app_typography.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/core/widgets/filter_pill.dart';
import 'package:doc_reader/features/library/data/prefs_library_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpApp(WidgetTester tester, Map<String, Object> prefs) async {
  AppTypography.useGoogleFonts = false;
  tester.platformDispatcher.localesTestValue = const [Locale('es')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  SharedPreferences.setMockInitialValues(prefs);
  final instance = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(instance)],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('biblioteca vacía ofrece abrir archivo y ejemplos', (
    tester,
  ) async {
    await pumpApp(tester, {});
    expect(find.text('Tu biblioteca está vacía'), findsOneWidget);
    expect(find.text('Abrir archivo'), findsOneWidget);
    expect(find.text('Probar con ejemplos'), findsOneWidget);
    // Navegación en píldora.
    expect(find.text('Biblioteca'), findsWidgets);
    expect(find.text('Subrayados'), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);
  });

  testWidgets('muestra documentos guardados y filtra por tipo', (tester) async {
    final docs = [
      {
        'id': 'a',
        'title': 'Notas de clase',
        'fileName': 'notas.md',
        'kind': 'text',
        'source': 'asset:assets/samples/notas.md',
        'sizeBytes': 1200,
        'addedAt': '2026-01-01T10:00:00.000',
      },
      {
        'id': 'b',
        'title': 'Presupuesto',
        'fileName': 'presupuesto.xlsx',
        'kind': 'spreadsheet',
        'source': 'asset:assets/samples/presupuesto.xlsx',
        'sizeBytes': 0,
        'addedAt': '2026-01-02T10:00:00.000',
        'progress': 0.5,
      },
    ];
    await pumpApp(tester, {
      PrefsLibraryRepository.storageKey: jsonEncode(docs),
    });

    expect(find.text('Notas de clase'), findsWidgets);
    expect(find.text('Presupuesto'), findsWidgets);
    expect(find.text('50 % leído'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterPill, 'Excel'));
    await tester.pumpAndSettle();
    expect(find.text('Notas de clase'), findsNothing);
    expect(find.text('Presupuesto'), findsWidgets);
  });

  testWidgets('la pestaña Ajustes cambia el tema', (tester) async {
    await pumpApp(tester, {});
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });
}
