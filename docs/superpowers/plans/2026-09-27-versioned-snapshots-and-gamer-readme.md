# Versioned Snapshots & Gamer-Friendly README Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement automated, version-controlled edit snapshots (Snapshot Vault) with a 1-click restore dialog, hook automated snapshots into the game rebuild flow, and completely overhaul `README.md` with gamer-focused, benefit-driven messaging.

**Architecture:** A standalone `SnapshotService` reads/writes timestamped JSON snapshots in the application documents directory (`snapshots/`), isolated from War Thunder files. Snapshots are auto-triggered before `RebuildService` purges game cache, and managed via `SnapshotHistoryDialog` from the Top Bar Presets menu. `README.md` is rewritten to translate technical architecture into player benefits (Armor-Plated Edit Locker, Instant 50,000+ String Search, Surgical Patching).

**Tech Stack:** Dart, Flutter, Riverpod 3, Drift SQLite, `dart:io`, `flutter_test`.

## Global Constraints
- Maximum 200 Lines of Code per non-test Dart source file (`dart format .`).
- Maximum 40 Lines of Code per method/function.
- Maximum 50 Lines of Code per Flutter `build()` method.
- Maximum 400 Lines of Code per test file.
- Zero static analysis warnings (`flutter analyze`).
- Minimum 80% test coverage on business logic (`flutter test --coverage`).
- Conventional Commits for every task commit.
- Preserve the recognized term "Community Presets (Squadron & WT Live Sharing)".

---

### Task 1: `SnapshotMetadata` Model & `SnapshotService`

**Files:**
- Create: `lib/features/localization/models/snapshot_models.dart`
- Create: `lib/features/localization/services/snapshot_service.dart`
- Create: `test/snapshot_service_test.dart`

**Interfaces:**
- Consumes: `AppDatabase` (Drift), `LocalizationsOverride`
- Produces:
  ```dart
  class SnapshotMetadata {
    final String id;
    final String name;
    final DateTime createdAt;
    final String? description;
    final int totalOverrides;
    final String filePath;
  }
  
  class SnapshotService {
    final AppDatabase db;
    final Directory baseDir;
    Future<SnapshotMetadata?> createSnapshot({required String label, String? description});
    Future<List<SnapshotMetadata>> listSnapshots();
    Future<int> restoreSnapshot(String snapshotId);
    Future<bool> deleteSnapshot(String snapshotId);
  }
  ```

- [ ] **Step 1: Write the failing unit tests for `SnapshotService`**

```dart
// test/snapshot_service_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/database/database.dart';
import 'package:gramercy/features/localization/models/snapshot_models.dart';
import 'package:gramercy/features/localization/services/snapshot_service.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late SnapshotService service;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('gramercy_snap_test_');
    service = SnapshotService(db: db, baseDir: tempDir);
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SnapshotService', () {
    test('createSnapshot returns null when no overrides exist', () async {
      final snap = await service.createSnapshot(label: 'Empty Test');
      expect(snap, isNull);
    });

    test('createSnapshot persists JSON and returns SnapshotMetadata', () async {
      await db.saveOverride(
        const LocalizationsOverridesCompanion(
          fileName: Value('units.csv'),
          stringKey: Value('germ_tiger_ii'),
          customValue: Value('Königstiger'),
        ),
      );

      final snap = await service.createSnapshot(
        label: 'Pre-Update Purge',
        description: 'Auto-snapshot',
      );

      expect(snap, isNotNull);
      expect(snap!.name, equals('Pre-Update Purge'));
      expect(snap.totalOverrides, equals(1));
      expect(File(snap.filePath).existsSync(), isTrue);

      final content = jsonDecode(await File(snap.filePath).readAsString());
      expect(content['schema_version'], equals('gramercy_preset_v1'));
      expect(content['overrides']['units.csv']['germ_tiger_ii'], equals('Königstiger'));
    });

    test('listSnapshots returns newest first', () async {
      await db.saveOverride(
        const LocalizationsOverridesCompanion(
          fileName: Value('units.csv'),
          stringKey: Value('test_1'),
          customValue: Value('val1'),
        ),
      );

      final snap1 = await service.createSnapshot(label: 'Snap 1');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final snap2 = await service.createSnapshot(label: 'Snap 2');

      final list = await service.listSnapshots();
      expect(list.length, equals(2));
      expect(list.first.name, equals('Snap 2'));
      expect(list.last.name, equals('Snap 1'));
    });

    test('restoreSnapshot restores overrides to database', () async {
      await db.saveOverride(
        const LocalizationsOverridesCompanion(
          fileName: Value('units.csv'),
          stringKey: Value('us_m4a3'),
          customValue: Value('Easy Eight'),
        ),
      );

      final snap = await service.createSnapshot(label: 'Restore Source');
      expect(snap, isNotNull);

      // Delete override from DB
      await db.deleteOverride('units.csv', 'us_m4a3');
      expect(await db.getAllOverrides(), isEmpty);

      // Restore snapshot
      final restoredCount = await service.restoreSnapshot(snap!.id);
      expect(restoredCount, equals(1));

      final overrides = await db.getAllOverrides();
      expect(overrides.length, equals(1));
      expect(overrides.first.customValue, equals('Easy Eight'));
    });

    test('deleteSnapshot deletes file from disk', () async {
      await db.saveOverride(
        const LocalizationsOverridesCompanion(
          fileName: Value('units.csv'),
          stringKey: Value('us_m4a3'),
          customValue: Value('Easy Eight'),
        ),
      );

      final snap = await service.createSnapshot(label: 'To Delete');
      expect(File(snap!.filePath).existsSync(), isTrue);

      final deleted = await service.deleteSnapshot(snap.id);
      expect(deleted, isTrue);
      expect(File(snap.filePath).existsSync(), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/snapshot_service_test.dart`
Expected: Compilation failure (classes `SnapshotMetadata` and `SnapshotService` do not exist).

- [ ] **Step 3: Implement `SnapshotMetadata` model**

```dart
// lib/features/localization/models/snapshot_models.dart
class SnapshotMetadata {
  final String id;
  final String name;
  final DateTime createdAt;
  final String? description;
  final int totalOverrides;
  final String filePath;

  const SnapshotMetadata({
    required this.id,
    required this.name,
    required this.createdAt,
    this.description,
    required this.totalOverrides,
    required this.filePath,
  });

  factory SnapshotMetadata.fromJson(Map<String, dynamic> json, String filePath) {
    return SnapshotMetadata(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled Snapshot',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      description: json['description'] as String?,
      totalOverrides: (json['total_overrides'] as num?)?.toInt() ?? 0,
      filePath: filePath,
    );
  }
}
```

- [ ] **Step 4: Implement `SnapshotService`**

```dart
// lib/features/localization/services/snapshot_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/database.dart';
import '../../../core/logging/app_logger.dart';
import '../models/snapshot_models.dart';

class SnapshotService {
  final AppDatabase db;
  final Directory baseDir;

  const SnapshotService({required this.db, required this.baseDir});

  Future<Directory> _ensureDir() async {
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }
    return baseDir;
  }

  Future<SnapshotMetadata?> createSnapshot({
    required String label,
    String? description,
  }) async {
    final overrides = await db.getAllOverrides();
    if (overrides.isEmpty) return null;

    final dir = await _ensureDir();
    final now = DateTime.now();
    final stamp = now.toIso8601String().replaceAll(RegExp(r'[:.-]'), '_');
    final id = 'snapshot_$stamp';
    final file = File(p.join(dir.path, '$id.json'));

    final map = <String, Map<String, String>>{};
    for (final o in overrides) {
      map.putIfAbsent(o.fileName, () => {})[o.stringKey] = o.customValue;
    }

    final payload = {
      'schema_version': 'gramercy_preset_v1',
      'id': id,
      'name': label,
      'created_at': now.toIso8601String(),
      if (description != null) 'description': description,
      'total_overrides': overrides.length,
      'overrides': map,
    };

    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    AppLogger.instance.i('Created snapshot ${file.path} ($label)', tag: 'SNAPSHOT');

    return SnapshotMetadata(
      id: id,
      name: label,
      createdAt: now,
      description: description,
      totalOverrides: overrides.length,
      filePath: file.path,
    );
  }

  Future<List<SnapshotMetadata>> listSnapshots() async {
    if (!await baseDir.exists()) return [];
    final list = <SnapshotMetadata>[];

    await for (final entity in baseDir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final content = await entity.readAsString();
          final data = jsonDecode(content) as Map<String, dynamic>;
          list.add(SnapshotMetadata.fromJson(data, entity.path));
        } catch (e) {
          AppLogger.instance.w('Skipping invalid snapshot ${entity.path}: $e');
        }
      }
    }

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<int> restoreSnapshot(String snapshotId) async {
    final file = File(p.join(baseDir.path, '$snapshotId.json'));
    if (!await file.exists()) return 0;

    final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final overridesMap = data['overrides'] as Map<String, dynamic>? ?? {};

    final companions = <LocalizationsOverridesCompanion>[];
    overridesMap.forEach((fileKey, entries) {
      if (entries is Map<String, dynamic>) {
        entries.forEach((stringKey, customVal) {
          companions.add(
            LocalizationsOverridesCompanion(
              fileName: Value(fileKey),
              stringKey: Value(stringKey),
              customValue: Value(customVal.toString()),
              updatedAt: Value(DateTime.now()),
            ),
          );
        });
      }
    });

    final count = await db.batchUpsertOverrides(companions);
    AppLogger.instance.i('Restored $count overrides from $snapshotId', tag: 'SNAPSHOT');
    return count;
  }

  Future<bool> deleteSnapshot(String snapshotId) async {
    final file = File(p.join(baseDir.path, '$snapshotId.json'));
    if (!await file.exists()) return false;
    await file.delete();
    AppLogger.instance.i('Deleted snapshot $snapshotId', tag: 'SNAPSHOT');
    return true;
  }
}
```

- [ ] **Step 5: Verify tests pass & check formatting/LoC**

Run: `dart format test/snapshot_service_test.dart lib/features/localization/models/snapshot_models.dart lib/features/localization/services/snapshot_service.dart`
Run: `flutter test test/snapshot_service_test.dart`
Run: `wc -l lib/features/localization/models/snapshot_models.dart lib/features/localization/services/snapshot_service.dart test/snapshot_service_test.dart`
Expected: 5/5 tests PASS, all files $\le 200$ LoC ($\le 400$ for test).

- [ ] **Step 6: Commit Task 1**

```bash
git add lib/features/localization/models/snapshot_models.dart lib/features/localization/services/snapshot_service.dart test/snapshot_service_test.dart
git commit -m "feat(snapshot): implement SnapshotMetadata and SnapshotService"
```

---

### Task 2: RebuildService Auto-Snapshot Integration

**Files:**
- Modify: `lib/features/localization/services/rebuild_service.dart`
- Modify: `test/rebuild_service_test.dart`

**Interfaces:**
- Consumes: `SnapshotService.createSnapshot()`
- Produces: Auto-snapshot executed inside `purgeLocalizationCache(String wtPath)`

- [ ] **Step 1: Write the failing test for auto-snapshotting during rebuild**

Add to `test/rebuild_service_test.dart`:
```dart
test('purgeLocalizationCache invokes snapshotService before deleting files', () async {
  // Setup mock/temp snapshot service
  // Verify snapshot file exists in snapshot directory after purge
});
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/rebuild_service_test.dart`
Expected: Fails because `RebuildService` constructor does not take or call `SnapshotService`.

- [ ] **Step 3: Update `RebuildService` to accept optional `SnapshotService`**

```dart
class RebuildService {
  final BackupService backupService;
  final GameProcessService gameProcessService;
  final SnapshotService? snapshotService;

  const RebuildService({
    this.backupService = const BackupService(),
    this.gameProcessService = const GameProcessService(),
    this.snapshotService,
  });
```
Inside `purgeLocalizationCache`:
```dart
// Auto-snapshot custom overrides before touching game directory
if (snapshotService != null) {
  try {
    await snapshotService!.createSnapshot(
      label: 'Pre-Update Purge',
      description: 'Auto-snapshot captured before War Thunder cache purge',
    );
  } catch (e) {
    AppLogger.instance.w('Auto-snapshot before purge failed: $e', tag: 'REBUILD');
  }
}
```

- [ ] **Step 4: Verify tests pass & check formatting/LoC**

Run: `dart format lib/features/localization/services/rebuild_service.dart test/rebuild_service_test.dart`
Run: `flutter test test/rebuild_service_test.dart`
Expected: All tests pass, `rebuild_service.dart` remains $\le 200$ LoC.

- [ ] **Step 5: Commit Task 2**

```bash
git add lib/features/localization/services/rebuild_service.dart test/rebuild_service_test.dart
git commit -m "feat(rebuild): trigger automated snapshot before localization cache purge"
```

---

### Task 3: UI Integration (`SnapshotHistoryDialog` & Top Bar Presets Menu)

**Files:**
- Create: `lib/features/localization/ui/widgets/snapshot_history_dialog.dart`
- Modify: `lib/features/localization/providers/localization_providers.dart`
- Modify: `lib/features/localization/ui/widgets/top_app_bar.dart`
- Create: `test/snapshot_dialog_test.dart`

**Interfaces:**
- Consumes: `snapshotServiceProvider`, `snapshotListProvider`
- Produces: `SnapshotHistoryDialog` widget, `PresetsMenuButton` integration

- [ ] **Step 1: Write widget test for `SnapshotHistoryDialog`**

```dart
// test/snapshot_dialog_test.dart
// Verify dialog displays list of snapshots, empty state when empty, and triggers restore
```

- [ ] **Step 2: Add providers to `localization_providers.dart`**

```dart
final snapshotServiceProvider = Provider<SnapshotService>((ref) {
  final db = ref.watch(dbProvider);
  // Using path_provider or app directory
  final baseDir = Directory(p.join(getApplicationDocumentsDirectory().path, 'gramercy', 'snapshots'));
  return SnapshotService(db: db, baseDir: baseDir);
});

final snapshotListProvider = FutureProvider.autoDispose<List<SnapshotMetadata>>((ref) async {
  final service = ref.watch(snapshotServiceProvider);
  return service.listSnapshots();
});
```

- [ ] **Step 3: Implement `SnapshotHistoryDialog`**

Create `lib/features/localization/ui/widgets/snapshot_history_dialog.dart` ($\le 200$ LoC):
- Header: Title "Edit History & Snapshots" + "Create Checkpoint" button.
- Body: `ListView.separated` of snapshots with timestamp, override count, Restore button, Delete button.
- Confirmation modal before restoring.
- Toast/SnackBar feedback on success.

- [ ] **Step 4: Add "Snapshot History" to `top_app_bar.dart` `PresetsMenuButton`**

In `lib/features/localization/ui/widgets/top_app_bar.dart`:
Add `PopupMenuItem` for `Snapshot History...` with `Icons.history`. On tap, open `showDialog(builder: (_) => const SnapshotHistoryDialog())`.

- [ ] **Step 5: Verify widget tests & verify LoC**

Run: `dart format --output=none --set-exit-if-changed .`
Run: `flutter analyze`
Run: `flutter test test/snapshot_dialog_test.dart`
Run: `wc -l lib/features/localization/ui/widgets/snapshot_history_dialog.dart lib/features/localization/ui/widgets/top_app_bar.dart`
Expected: 0 warnings, all source files $\le 200$ LoC.

- [ ] **Step 6: Commit Task 3**

```bash
git add lib/features/localization/ui/widgets/snapshot_history_dialog.dart lib/features/localization/providers/localization_providers.dart lib/features/localization/ui/widgets/top_app_bar.dart test/snapshot_dialog_test.dart
git commit -m "feat(ui): add SnapshotHistoryDialog and Presets menu integration"
```

---

### Task 4: Gamer-Friendly README Overhaul

**Files:**
- Modify: `README.md`

**Objectives:**
- Translate technical jargon into direct player benefits.
- Preserve recognizable terms: "Community Presets (Squadron & WT Live Sharing)".
- Detail the **Armor-Plated Edit Locker** (how edits are stored outside the game directory and never lost on game uninstall/updates).
- Highlight the **Automated Snapshot Safety Net** in the Major Update Survival Guide.
- Ensure high-octane, gamer-friendly tone without meme excess.

- [ ] **Step 1: Rewrite `README.md`**

Incorporate:
1. **Hook**: Rename tanks, planes, missiles, kill feeds, and HUD messages with zero game crashes and 100% BattlEye safety.
2. **Feature Translations**:
   - *Armor-Plated Edit Locker* (replaces Drift SQLite Delta Vault)
   - *Instant 50,000+ String Cockpit* (replaces 120Hz Virtualized Cockpit)
   - *Surgical Patching* (replaces Delta-Patching Engine)
   - *Community Presets (Squadron & WT Live Sharing)*
   - *Automated Snapshot Safety Net* (new versioning showcase)
3. **Major Update Guide**: Clear, confident 3-step guide explaining how your edits survive game updates and how auto-snapshots keep you 100% covered.
4. **Badges & Architecture**: Keep technical architecture diagram in Architecture section for developers while making sections 1-6 purely gamer-focused.

- [ ] **Step 2: Review `README.md` for clarity, tone, and link correctness**

Check all section anchors, image paths, and formatting.

- [ ] **Step 3: Commit Task 4**

```bash
git add README.md
git commit -m "docs(readme): overhaul with gamer-friendly copy and snapshot vault guide"
```

---

### Task 5: Full Verification & DoD Checklist

- [ ] **Step 1: Run format check**
Run: `dart format --output=none --set-exit-if-changed .`
Expected: 0 changes.

- [ ] **Step 2: Run static analysis**
Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 3: Run full test suite with coverage**
Run: `flutter test --coverage`
Expected: All tests pass, $\ge 80\%$ coverage.

- [ ] **Step 4: Check LoC limits across all modified and new files**
Run: `wc -l lib/features/localization/models/snapshot_models.dart lib/features/localization/services/snapshot_service.dart lib/features/localization/ui/widgets/snapshot_history_dialog.dart lib/features/localization/services/rebuild_service.dart lib/features/localization/ui/widgets/top_app_bar.dart`
Expected: Every source file $\le 200$ LoC, test files $\le 400$ LoC.

- [ ] **Step 5: Verify zero untracked temp files**
Run: `git status -uall`
Expected: Clean working tree.
