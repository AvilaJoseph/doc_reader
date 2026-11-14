import 'package:doc_reader/core/theme/reading_theme.dart';
import 'package:doc_reader/core/ui.dart';
import 'package:doc_reader/features/reader/formats/flow/flow_block_view.dart';
import 'package:doc_reader/features/reader/formats/flow/flow_document.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('la selección puede abarcar varios párrafos', (tester) async {
    final registry = FlowSelectionRegistry();
    const style = FlowReadingStyle(
      theme: ReadingTheme.paper,
      fontSize: 16,
      lineHeight: 1.4,
    );
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      localizedApp(
        SelectionArea(
          focusNode: focus,
          child: Column(
            children: [
              for (final (i, text) in ['Primer párrafo', 'Segundo'].indexed)
                FlowBlockView(
                  block: ParagraphBlock(runs: [TextRun(text)]),
                  blockIndex: i,
                  style: style,
                  highlights: const [],
                  selection: registry,
                ),
            ],
          ),
        ),
      ),
    );
    expect(registry.drafts(), isEmpty);

    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    final drafts = registry.drafts();
    expect(drafts.map((d) => (d.blockIndex, d.text)), [
      (0, 'Primer párrafo'),
      (1, 'Segundo'),
    ]);
  });
}
