import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:gramercy/features/localization/ui/widgets/about_gramercy_dialog.dart';

void main() {
  testWidgets('about subtitle renders the live package version', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appVersionProvider.overrideWithValue(AsyncValue.data('9.9.9')),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: AboutGramercyDialog()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('v9.9.9 • War Thunder Custom Localization Engine'),
      findsOneWidget,
      reason:
          'version must come from package metadata, never a hardcoded string',
    );
    expect(
      find.text('v1.5.0 • War Thunder Custom Localization Engine'),
      findsNothing,
    );
  });
}
