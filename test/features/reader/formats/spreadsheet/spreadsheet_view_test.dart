import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/features/reader/formats/spreadsheet/spreadsheet_view.dart';
import 'package:doc_reader/features/reader/formats/spreadsheet/workbook.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_app.dart';

void main() {
  Widget wrap(Sheet sheet) => localizedApp(SpreadsheetView(sheet: sheet));

  testWidgets('muestra encabezados de columna, filas y valores', (
    tester,
  ) async {
    const sheet = Sheet(
      name: 'Hoja',
      rows: [
        ['Producto', 'Precio'],
        ['Café', '2.5'],
      ],
    );
    await tester.pumpWidget(wrap(sheet));

    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Café'), findsOneWidget);
  });

  testWidgets('una hoja vacía muestra un mensaje', (tester) async {
    await tester.pumpWidget(wrap(const Sheet(name: 'x', rows: [])));
    expect(find.text('Hoja vacía'), findsOneWidget);
  });

  testWidgets('avisa cuando la hoja está truncada', (tester) async {
    const sheet = Sheet(
      name: 'x',
      rows: [
        ['a'],
      ],
      truncated: true,
    );
    await tester.pumpWidget(wrap(sheet));
    expect(find.text('Se muestran las primeras 1 filas'), findsOneWidget);
  });
}
