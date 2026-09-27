import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/database/database.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/models/snapshot_models.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:gramercy/features/localization/ui/widgets/presets_menu_button.dart';
import 'package:gramercy/features/localization/ui/widgets/snapshot_history_dialog.dart';

class FakeSnapshotService extends SnapshotService {
  List<SnapshotMetadata> snapshotList;
  int restoreCallCount = 0;
  String? lastRestoredId;
  String? lastDeletedId;
  String? lastCreatedLabel;
  bool returnNullOnCreate;

  FakeSnapshotService({
    this.snapshotList = const [],
    this.returnNullOnCreate = false,
    required AppDatabase sharedDb,
  }) : super(db: sharedDb, baseDir: Directory.systemTemp);

  @override
  Future<List<SnapshotMetadata>> listSnapshots() async => List.of(snapshotList);

  @override
  Future<SnapshotMetadata?> createSnapshot({
    required String label,
    String? description,
  }) async {
    lastCreatedLabel = label;
    if (returnNullOnCreate) return null;
    final item = SnapshotMetadata(
      id: 'snapshot_created',
      name: label,
      createdAt: DateTime.now().toUtc(),
      totalOverrides: 10,
      filePath: '/dummy/$label.json',
    );
    snapshotList = [item, ...snapshotList];
    return item;
  }

  @override
  Future<int> restoreSnapshot(String snapshotId) async {
    restoreCallCount++;
    lastRestoredId = snapshotId;
    return 42;
  }

  @override
  Future<bool> deleteSnapshot(String snapshotId) async {
    lastDeletedId = snapshotId;
    snapshotList = snapshotList.where((s) => s.id != snapshotId).toList();
    return true;
  }
}

Widget createDialogTestWidget({required FakeSnapshotService service}) {
  return ProviderScope(
    overrides: [snapshotServiceProvider.overrideWithValue(service)],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: const Scaffold(body: SnapshotHistoryDialog()),
    ),
  );
}

Widget createMenuTestWidget({required FakeSnapshotService service}) {
  return ProviderScope(
    overrides: [snapshotServiceProvider.overrideWithValue(service)],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: const Scaffold(body: PresetsMenuButton()),
    ),
  );
}

void main() {
  late AppDatabase sharedDb;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    sharedDb = AppDatabase(NativeDatabase.memory());
  });

  tearDownAll(() async {
    await sharedDb.close();
  });

  final sampleSnapshot1 = SnapshotMetadata(
    id: 'snap_1',
    name: 'Pre-Update Backup',
    createdAt: DateTime(2026, 9, 27, 10, 30),
    totalOverrides: 42,
    filePath: '/path/to/snap_1.json',
  );

  final sampleSnapshot2 = SnapshotMetadata(
    id: 'snap_2',
    name: 'Manual Checkpoint',
    createdAt: DateTime(2026, 9, 26, 15, 0),
    totalOverrides: 15,
    filePath: '/path/to/snap_2.json',
  );

  testWidgets('renders empty state when no snapshots exist', (tester) async {
    final service = FakeSnapshotService(
      snapshotList: const [],
      sharedDb: sharedDb,
    );
    await tester.pumpWidget(createDialogTestWidget(service: service));
    await tester.pumpAndSettle();

    expect(find.text('Edit History & Snapshots'), findsOneWidget);
    expect(find.text('+ New Snapshot'), findsOneWidget);
    expect(find.byIcon(Icons.history_toggle_off), findsOneWidget);
    expect(
      find.text(
        'No snapshots saved yet.\nAutomatic snapshots are created before War Thunder updates.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders populated snapshots list with metadata', (tester) async {
    final service = FakeSnapshotService(
      snapshotList: [sampleSnapshot1, sampleSnapshot2],
      sharedDb: sharedDb,
    );
    await tester.pumpWidget(createDialogTestWidget(service: service));
    await tester.pumpAndSettle();

    expect(find.text('Pre-Update Backup'), findsOneWidget);
    expect(find.text('Manual Checkpoint'), findsOneWidget);
    expect(find.text('42 strings'), findsOneWidget);
    expect(find.text('15 strings'), findsOneWidget);
    expect(find.byIcon(Icons.restore), findsNWidgets(2));
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
  });

  testWidgets('restore button prompts confirmation and executes restore', (
    tester,
  ) async {
    final service = FakeSnapshotService(
      snapshotList: [sampleSnapshot1],
      sharedDb: sharedDb,
    );
    await tester.pumpWidget(createDialogTestWidget(service: service));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Restore'));
    await tester.pumpAndSettle();

    expect(find.text('Restore Snapshot?'), findsOneWidget);
    expect(find.textContaining('Pre-Update Backup'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Confirm Restore'));
    await tester.pumpAndSettle();

    expect(service.restoreCallCount, equals(1));
    expect(service.lastRestoredId, equals('snap_1'));
    expect(find.textContaining('Restored 42 strings'), findsOneWidget);
  });

  testWidgets(
    'restore confirmation cancel dismisses dialog without restoring',
    (tester) async {
      final service = FakeSnapshotService(
        snapshotList: [sampleSnapshot1],
        sharedDb: sharedDb,
      );
      await tester.pumpWidget(createDialogTestWidget(service: service));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Restore'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(service.restoreCallCount, equals(0));
      expect(find.text('Restore Snapshot?'), findsNothing);
    },
  );

  testWidgets('delete button prompts confirmation and executes delete', (
    tester,
  ) async {
    final service = FakeSnapshotService(
      snapshotList: [sampleSnapshot1],
      sharedDb: sharedDb,
    );
    await tester.pumpWidget(createDialogTestWidget(service: service));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Delete Snapshot?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(service.lastDeletedId, equals('snap_1'));
    expect(find.text('Pre-Update Backup'), findsNothing);
  });

  testWidgets('delete confirmation cancel dismisses dialog without deleting', (
    tester,
  ) async {
    final service = FakeSnapshotService(
      snapshotList: [sampleSnapshot1],
      sharedDb: sharedDb,
    );
    await tester.pumpWidget(createDialogTestWidget(service: service));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(service.lastDeletedId, isNull);
    expect(find.text('Pre-Update Backup'), findsOneWidget);
  });

  testWidgets('creates new snapshot via dialog', (tester) async {
    final service = FakeSnapshotService(
      snapshotList: const [],
      sharedDb: sharedDb,
    );
    await tester.pumpWidget(createDialogTestWidget(service: service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('+ New Snapshot'));
    await tester.pumpAndSettle();

    expect(find.text('Create Snapshot'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Custom Test Snapshot');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(service.lastCreatedLabel, equals('Custom Test Snapshot'));
    expect(find.text('Custom Test Snapshot'), findsOneWidget);
  });

  testWidgets('shows notice when snapshot creation has no overrides', (
    tester,
  ) async {
    final service = FakeSnapshotService(
      snapshotList: const [],
      returnNullOnCreate: true,
      sharedDb: sharedDb,
    );
    await tester.pumpWidget(createDialogTestWidget(service: service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('+ New Snapshot'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('No custom overrides to snapshot.'), findsOneWidget);
  });

  testWidgets('close icon button pops dialog', (tester) async {
    final service = FakeSnapshotService(
      snapshotList: const [],
      sharedDb: sharedDb,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [snapshotServiceProvider.overrideWithValue(service)],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showDialog<void>(
                context: ctx,
                builder: (_) => const SnapshotHistoryDialog(),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(SnapshotHistoryDialog), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(SnapshotHistoryDialog), findsNothing);
  });

  testWidgets(
    'PresetsMenuButton includes Snapshot History option and opens dialog',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final service = FakeSnapshotService(
        snapshotList: const [],
        sharedDb: sharedDb,
      );
      await tester.pumpWidget(createMenuTestWidget(service: service));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Export Preset (.json)'), findsOneWidget);
      expect(find.text('Import Preset (.json)'), findsOneWidget);
      expect(find.text('Snapshot History...'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);

      await tester.tap(find.text('Snapshot History...'));
      await tester.pumpAndSettle();

      expect(find.byType(SnapshotHistoryDialog), findsOneWidget);
      expect(find.text('Edit History & Snapshots'), findsOneWidget);
    },
  );
}
