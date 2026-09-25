import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:gramercy/features/localization/services/rebuild_service.dart';
import 'package:gramercy/features/localization/ui/widgets/purge_confirm_dialog.dart';
import 'package:gramercy/features/localization/ui/widgets/rebuild_dialog.dart';

class FakeWtPathNotifier extends WtPathNotifier {
  final String path;
  FakeWtPathNotifier(this.path);

  @override
  String? build() => path;
}

class MockRebuildService extends RebuildService {
  bool gameRunning = false;
  PurgeResult purgeResult = PurgeResult(
    success: true,
    deletedCount: 5,
    backupPath: '/backup/path',
    purgedAt: DateTime.now(),
  );
  FreshStringsStatus Function(DateTime? since)? freshStringsProvider;

  @override
  Future<bool> isGameRunning() async => gameRunning;

  @override
  Future<PurgeResult> purgeLocalizationCache(String wtPath) async =>
      purgeResult;

  @override
  Future<FreshStringsStatus> checkFreshStringsExist(
    String wtPath, {
    DateTime? since,
  }) async {
    if (freshStringsProvider != null) {
      return freshStringsProvider!(since);
    }
    return const FreshStringsStatus(hasFiles: false, fileCount: 0);
  }

  @override
  Future<bool> launchWarThunder(String wtPath) async => true;
}

Widget createTestWidget({
  required MockRebuildService mockService,
  String wtPath = r'C:\Games\WarThunder',
}) {
  return ProviderScope(
    overrides: [
      wtPathProvider.overrideWith(() => FakeWtPathNotifier(wtPath)),
      rebuildServiceProvider.overrideWithValue(mockService),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: const Scaffold(body: RebuildDialog()),
    ),
  );
}

void main() {
  setUp(() {});

  testWidgets('RebuildDialog initial state requires Step 1 purge first', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockService = MockRebuildService();
    await tester.pumpWidget(createTestWidget(mockService: mockService));
    await tester.pump();

    // Step 2 should be in awaiting state
    expect(find.text('Awaiting Step 1 cache purge...'), findsOneWidget);
    expect(find.text('Complete Step 1 cache purge first.'), findsOneWidget);

    // Launch button in Step 2 should be disabled
    final launchBtn = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Launch War Thunder'),
    );
    expect(launchBtn.onPressed, isNull);

    // Step 3 Reload & Apply button should be disabled
    final reloadBtn = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Reload & Apply'),
    );
    expect(reloadBtn.onPressed, isNull);
  });

  testWidgets(
    'Step 2 does not detect existing files as fresh strings before purge',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockService = MockRebuildService();
      // Even if old files exist on disk
      mockService.freshStringsProvider = (since) {
        if (since == null) {
          return const FreshStringsStatus(hasFiles: true, fileCount: 10);
        }
        return const FreshStringsStatus(hasFiles: false, fileCount: 0);
      };

      await tester.pumpWidget(createTestWidget(mockService: mockService));
      await tester.pump(const Duration(seconds: 3));

      // Must still be awaiting Step 1
      expect(find.text('Awaiting Step 1 cache purge...'), findsOneWidget);
      expect(find.textContaining('Fresh strings detected'), findsNothing);
    },
  );

  testWidgets(
    'Step 1 successful purge enables Step 2 and allows fresh file detection',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockService = MockRebuildService();
      DateTime? capturedSince;
      mockService.freshStringsProvider = (since) {
        capturedSince = since;
        if (since != null) {
          return const FreshStringsStatus(
            hasFiles: true,
            fileCount: 4,
            keyFilesFound: ['units.csv'],
          );
        }
        return const FreshStringsStatus(hasFiles: false, fileCount: 0);
      };

      await tester.pumpWidget(createTestWidget(mockService: mockService));
      await tester.pump();

      // Tap Purge Cache
      await tester.tap(find.text('Purge Cache'));
      await tester.pumpAndSettle();

      // In PurgeConfirmDialog, tap Backup & Purge Cache
      expect(find.byType(PurgeConfirmDialog), findsOneWidget);
      await tester.tap(find.text('Backup & Purge Cache'));
      await tester.pumpAndSettle();

      // Step 1 should show success message
      expect(
        find.textContaining('Purged 5 files (backup saved).'),
        findsOneWidget,
      );

      // Trigger periodic timer for Step 2 detection
      await tester.pump(const Duration(seconds: 3));
      expect(capturedSince, isNotNull);

      // Step 2 should now detect fresh strings
      expect(find.text('Fresh strings detected (4 CSV files)'), findsOneWidget);

      // Step 3 Reload & Apply should now be enabled
      final reloadBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Reload & Apply'),
      );
      expect(reloadBtn.onPressed, isNotNull);
    },
  );

  testWidgets(
    'Purge failure due to locked files shows error and keeps Step 2 awaiting',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockService = MockRebuildService();
      mockService.purgeResult = const PurgeResult(
        success: false,
        remainingFiles: ['units.csv'],
        errorMessage: 'Could not delete 1 file(s). In use by War Thunder.',
      );

      await tester.pumpWidget(createTestWidget(mockService: mockService));
      await tester.pump();

      await tester.tap(find.text('Purge Cache'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Backup & Purge Cache'));
      await tester.pumpAndSettle();

      // Step 1 shows error
      expect(
        find.textContaining(
          'Error: Could not delete 1 file(s). In use by War Thunder.',
        ),
        findsOneWidget,
      );

      // Step 2 remains awaiting Step 1
      expect(find.text('Awaiting Step 1 cache purge...'), findsOneWidget);
    },
  );
}
