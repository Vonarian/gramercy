import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/isolates/localization_worker.dart';
import 'package:gramercy/core/services/preferences_service.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:gramercy/features/localization/ui/widgets/config_status_pill.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockWorker extends Mock implements LocalizationWorkerService {}

const _disabledStatus = ConfigBlkStatus(
  exists: true,
  isLocalizationEnabled: false,
  filePath: '/wt/config.blk',
);

const _enabledStatus = ConfigBlkStatus(
  exists: true,
  isLocalizationEnabled: true,
  filePath: '/wt/config.blk',
);

const _missingStatus = ConfigBlkStatus(
  exists: false,
  isLocalizationEnabled: false,
  filePath: '/wt/config.blk',
);

Future<void> _pumpPill(
  WidgetTester tester,
  AsyncValue<ConfigBlkStatus> status, {
  LocalizationWorkerService? worker,
}) async {
  SharedPreferences.setMockInitialValues({
    PreferencesService.keyWtInstallPath: '/wt',
  });
  final prefs = PreferencesService(await SharedPreferences.getInstance());
  final workerStub = worker ?? _MockWorker();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        workerServiceProvider.overrideWithValue(workerStub),
        configBlkStatusProvider.overrideWithValue(status),
      ],
      child: const MaterialApp(home: Scaffold(body: ConfigStatusPill())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue('/tmp/config.blk');
  });

  testWidgets('loading state renders nothing', (tester) async {
    await _pumpPill(tester, const AsyncValue.loading());

    expect(find.text('testLocalization: ACTIVE'), findsNothing);
    expect(find.text('Enable in config.blk'), findsNothing);
  });

  testWidgets('error state renders nothing', (tester) async {
    await _pumpPill(
      tester,
      AsyncValue.error(StateError('boom'), StackTrace.empty),
    );

    expect(find.text('testLocalization: ACTIVE'), findsNothing);
    expect(find.text('Enable in config.blk'), findsNothing);
  });

  testWidgets('missing config.blk renders nothing', (tester) async {
    await _pumpPill(tester, const AsyncValue.data(_missingStatus));

    expect(find.text('testLocalization: ACTIVE'), findsNothing);
    expect(find.text('Enable in config.blk'), findsNothing);
  });

  testWidgets('enabled localization renders the active pill', (tester) async {
    await _pumpPill(tester, const AsyncValue.data(_enabledStatus));

    expect(find.text('testLocalization: ACTIVE'), findsOneWidget);
    expect(find.text('Enable in config.blk'), findsNothing);
  });

  testWidgets('disabled localization renders a patch button', (tester) async {
    await _pumpPill(tester, const AsyncValue.data(_disabledStatus));

    expect(find.text('Enable in config.blk'), findsOneWidget);
    expect(find.text('testLocalization: ACTIVE'), findsNothing);
  });

  testWidgets('patch button triggers the worker and refreshes status', (
    tester,
  ) async {
    final worker = _MockWorker();
    when(() => worker.patchConfigBlk(any())).thenAnswer((_) async => true);
    await _pumpPill(
      tester,
      const AsyncValue.data(_disabledStatus),
      worker: worker,
    );

    await tester.tap(find.text('Enable in config.blk'));
    await tester.pumpAndSettle();

    verify(() => worker.patchConfigBlk('/wt/config.blk')).called(1);
  });
}
