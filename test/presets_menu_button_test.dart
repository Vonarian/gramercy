import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/features/localization/ui/widgets/presets_menu_button.dart';

void main() {
  testWidgets('menu exposes export, import and snapshot actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: PresetsMenuButton())),
      ),
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('Export Preset (.json)'), findsOneWidget);
    expect(find.text('Import Preset (.json)'), findsOneWidget);
    expect(find.text('Snapshot History...'), findsOneWidget);
  });
}
