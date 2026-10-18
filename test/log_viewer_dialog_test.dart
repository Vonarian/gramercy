import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/logging/app_logger.dart';
import 'package:gramercy/core/logging/log_entry.dart';
import 'package:gramercy/core/services/preferences_service.dart';
import 'package:gramercy/features/localization/providers/config_providers.dart';
import 'package:gramercy/features/localization/providers/logging_providers.dart';
import 'package:gramercy/features/localization/ui/widgets/log_viewer_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpViewer(
  WidgetTester tester,
  Map<String, Object> prefValues,
) async {
  SharedPreferences.setMockInitialValues(prefValues);
  final prefs = PreferencesService(await SharedPreferences.getInstance());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: Scaffold(body: LogViewerDialog())),
    ),
  );
  await tester.pumpAndSettle();
}

void _mockPlatformChannel() {
  // Deprecated channel-level mock is required to intercept the aggregated
  // `flutter/platform` channel used by Clipboard/SystemChrome in tests.
  // ignore: deprecated_member_use
  SystemChannels.platform.setMockMethodCallHandler((call) async => null);
}

void main() {
  setUp(() {
    _mockPlatformChannel();
    AppLogger.instance
      ..configure(minLevel: LogLevel.verbose, fileOutput: false)
      ..clear();
  });

  tearDown(() {
    // ignore: deprecated_member_use
    SystemChannels.platform.setMockMethodCallHandler(null);
    AppLogger.instance
      ..configure(minLevel: LogLevel.info, fileOutput: false)
      ..clear();
  });

  testWidgets('lists buffered entries and filters by search text', (
    tester,
  ) async {
    AppLogger.instance
      ..i('Deploy finished', tag: 'EXPORT')
      ..e('Config missing', tag: 'WORKER');

    await _pumpViewer(tester, {});

    expect(
      find.textContaining('[INFO] [EXPORT] Deploy finished'),
      findsOneWidget,
    );
    expect(
      find.textContaining('[ERR ] [WORKER] Config missing'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'export');
    await tester.pumpAndSettle();

    expect(find.textContaining('Config missing'), findsNothing);
    expect(find.textContaining('Deploy finished'), findsOneWidget);
  });

  testWidgets('clear button empties the visible log', (tester) async {
    AppLogger.instance.i('Deploy finished', tag: 'EXPORT');
    await _pumpViewer(tester, {});
    expect(find.textContaining('Deploy finished'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Deploy finished'), findsNothing);
    expect(AppLogger.instance.entries, isEmpty);
  });

  testWidgets('copy button pushes the formatted log to the clipboard', (
    tester,
  ) async {
    AppLogger.instance
      ..i('Deploy finished', tag: 'EXPORT')
      ..w('Latency high', tag: 'NET');

    await _pumpViewer(tester, {});
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Copied 2 log lines'), findsOneWidget);
  });

  testWidgets('raising the level filter hides lower-severity rows', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferencesService(await SharedPreferences.getInstance());
    final container = ProviderContainer(
      overrides: [prefsProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    AppLogger.instance
      ..i('Deploy finished', tag: 'EXPORT')
      ..e('Config missing', tag: 'WORKER');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: LogViewerDialog())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Min: INFO'), findsOneWidget);

    await container
        .read(logLevelNotifierProvider.notifier)
        .setLogLevel(LogLevel.error);
    await tester.pumpAndSettle();

    expect(find.textContaining('Deploy finished'), findsNothing);
    expect(find.textContaining('Config missing'), findsOneWidget);
  });
}
