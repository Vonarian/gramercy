import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/ui/fallback/unsupported_platform_screen.dart';

void main() {
  testWidgets(
    'unsupported platform screen names the platform and the hand-off',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: UnsupportedPlatformScreen(platform: 'Android')),
      );

      expect(find.text('Gramercy is a desktop application'), findsOneWidget);
      expect(find.textContaining('Android sandboxes access'), findsOneWidget);
      expect(find.textContaining('preset pack'), findsOneWidget);
    },
  );
}
