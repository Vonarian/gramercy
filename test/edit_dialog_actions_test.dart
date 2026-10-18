import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/features/localization/ui/widgets/edit_dialog_actions.dart';

Future<void> _pumpActions(
  WidgetTester tester, {
  required bool isOverridden,
  required bool isSaving,
  required void Function(String) onAction,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EditDialogActions(
          isOverridden: isOverridden,
          isSaving: isSaving,
          onCancel: () => onAction('cancel'),
          onSave: () => onAction('save'),
          onRevert: () => onAction('revert'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders revert, cancel and save when overridden', (
    tester,
  ) async {
    final actions = <String>[];
    await _pumpActions(
      tester,
      isOverridden: true,
      isSaving: false,
      onAction: actions.add,
    );

    expect(find.text('Revert to Base'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save Override'), findsOneWidget);
  });

  testWidgets('hides revert when not overridden', (tester) async {
    await _pumpActions(
      tester,
      isOverridden: false,
      isSaving: false,
      onAction: (_) {},
    );

    expect(find.text('Revert to Base'), findsNothing);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save Override'), findsOneWidget);
  });

  testWidgets('fires the cancel and revert callbacks when tapped', (
    tester,
  ) async {
    final actions = <String>[];
    await _pumpActions(
      tester,
      isOverridden: true,
      isSaving: false,
      onAction: actions.add,
    );

    await tester.tap(find.text('Cancel'));
    await tester.tap(find.text('Revert to Base'));

    expect(actions, ['cancel', 'revert']);
  });

  testWidgets('fires the save callback when tapped', (tester) async {
    final actions = <String>[];
    await _pumpActions(
      tester,
      isOverridden: false,
      isSaving: false,
      onAction: actions.add,
    );

    await tester.tap(find.text('Save Override'));

    expect(actions, ['save']);
  });

  testWidgets('isSaving disables all buttons and shows a spinner', (
    tester,
  ) async {
    final actions = <String>[];
    await _pumpActions(
      tester,
      isOverridden: true,
      isSaving: true,
      onAction: actions.add,
    );

    await tester.tap(find.text('Cancel'), warnIfMissed: false);
    expect(actions, isEmpty);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Save Override'), findsNothing);
    expect(find.text('Revert to Base'), findsOneWidget);
  });
}
