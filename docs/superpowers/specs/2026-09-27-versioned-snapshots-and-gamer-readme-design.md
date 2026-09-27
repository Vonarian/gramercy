# Design Specification: Versioned Snapshots & Gamer-Friendly README Overhaul

- **Date:** 2026-09-27
- **Status:** Approved
- **Target Release:** v1.3.2
- **Topic:** Version-Controlled Edits (Snapshot Vault) & Gamer/Gooner-Friendly README Translation

---

## 1. Executive Summary

Gramercy is War Thunder's premier localization management desktop cockpit. While the underlying architecture (Drift SQLite, Riverpod 3, Worker Isolates, Delta Synthesis) provides enterprise-grade performance and safety, non-technical players and modders need:
1. **Digestible, Benefit-Driven Marketing:** Translating engineering concepts (e.g., "Drift SQLite Delta Vault", "Immutable Delta Synthesis") into concrete gamer benefits ("Armor-Plated Edit Locker", "Zero Game Crashes", "Zero FPS Loss", "Instant 50,000+ String Search").
2. **Version-Controlled Edit Security:** Guaranteeing that player customizations (custom tank designations, historical weaponry, anime/meme kill feeds) are stored outside the game installation directory and versioned with automatic, 1-click restorable snapshots before any game update or cache purge.
3. **Streamlined UI Integration:** Introducing an asynchronous, zero-latency Snapshot History modal accessible from the Top Bar Presets menu without causing frame drops or UI latency.

---

## 2. Architecture & Data Model

### 2.1 Snapshot Storage Architecture
- Snapshots are stored in an isolated, OS-standard user documents directory:
  - Windows: `%APPDATA%\gramercy\snapshots\`
  - macOS: `~/Library/Application Support/gramercy/snapshots/`
  - Linux: `~/.local/share/gramercy/snapshots/`
- Completely separated from the War Thunder game installation folder (`<War Thunder>/lang/`). Even if War Thunder is uninstalled, verified, or updated by the Gaijin launcher, the snapshots remain untouched.

### 2.2 Data Structure
Reuses and extends the battle-tested `gramercy_preset_v1` JSON structure:
```json
{
  "schema_version": "gramercy_preset_v1",
  "id": "snapshot_20260927_131500_pre_update",
  "name": "Pre-Update Purge",
  "created_at": "2026-09-27T13:15:00.000Z",
  "description": "Automatic snapshot captured before cache rebuild",
  "total_overrides": 42,
  "overrides": {
    "units.csv": {
      "germ_tiger_ii": "King Tiger (H)",
      "us_m4a3_76w_sherman": "Easy Eight"
    }
  }
}
```

### 2.3 `SnapshotMetadata` Model
A lightweight metadata header representation to allow instant list rendering without parsing large override maps:
```dart
class SnapshotMetadata {
  final String id;
  final String name;
  final DateTime createdAt;
  final String? description;
  final int totalOverrides;
  final String filePath;
}
```

### 2.4 `SnapshotService` Interface
Located in `lib/features/localization/services/snapshot_service.dart` ($\le 200$ LoC):
- `Future<SnapshotMetadata?> createSnapshot({required String label, String? description})`:
  - Fetches all active overrides from `AppDatabase.getAllOverrides()`.
  - If empty, gracefully returns `null` (no unnecessary blank files).
  - Asynchronously writes formatted JSON to the snapshot directory.
- `Future<List<SnapshotMetadata>> listSnapshots()`:
  - Asynchronously reads files in the snapshot directory matching `snapshot_*.json`.
  - Parses top-level metadata only.
  - Sorts descending by `createdAt` (newest first).
- `Future<int> restoreSnapshot(String snapshotId)`:
  - Reads and decodes snapshot JSON.
  - Validates `schema_version`.
  - Executes `AppDatabase.batchUpsertOverrides(...)` in an atomic transaction.
  - Returns count of restored overrides.
- `Future<bool> deleteSnapshot(String snapshotId)`:
  - Deletes the specified snapshot file from disk asynchronously.

---

## 3. Integration & Performance Guarantees

### 3.1 Rebuild Wizard Integration
In `lib/features/localization/services/rebuild_service.dart`:
- Before executing the `lang/` disk purge in `purgeLocalizationCache(String wtPath)`:
  ```dart
  await snapshotService.createSnapshot(
    label: 'Pre-Update Purge',
    description: 'Auto-snapshot before War Thunder cache purge',
  );
  ```
- Ensures users can roll back their customized strings even if fresh game CSV generation fails.

### 3.2 Performance & Zero-Jank Mandate
- All file reads and writes in `SnapshotService` are asynchronous (`dart:io` `File.readAsString` / `File.writeAsString`).
- The 120Hz virtualized list (`VirtualizedLocalizationList`) is unaffected as Riverpod streams the updated overrides after `batchUpsertOverrides` completes.
- Dialog rendering uses compact, efficient Flutter widgets that dispose cleanly.

---

## 4. UI Specification: `SnapshotHistoryDialog`

### 4.1 Top Bar Presets Dropdown
In `lib/features/localization/ui/widgets/top_app_bar.dart`:
- Add a new menu item to `PresetsMenuButton`:
  - Icon: `Icons.history` or `Icons.camera_alt_outlined`
  - Text: `Snapshot History...`
  - Tap: Displays `SnapshotHistoryDialog`.

### 4.2 Modal Dialog Layout
File: `lib/features/localization/ui/widgets/snapshot_history_dialog.dart` ($\le 200$ LoC):
- **Header**:
  - Title: "Edit History & Snapshots"
  - Action button: "+ Create Snapshot" (with prompt for optional label).
- **Body**:
  - `ListView.separated` of snapshot cards.
  - Each card displays:
    - Title / Label (e.g. `Pre-Update Purge` or custom label)
    - Formatted timestamp (e.g., `Today, 13:15` or `Sep 27, 2026 13:15`)
    - Override count badge: `X customized strings`
    - Action buttons:
      - **"Restore"** (`FilledButton.tonal`): Prompts confirmation dialog ("Restore X overrides from this snapshot?"), applies via `restoreSnapshot`, shows success `SnackBar`, and refreshes view.
      - **"Delete"** (`IconButton` with `Icons.delete_outline`): Confirms and deletes file.
- **Empty State**:
  - Centered icon and message: *"No snapshots yet. Automatic snapshots are created before game updates."*

---

## 5. Gamer-Friendly README Overhaul

Transform `README.md` from an academic architecture brief into a high-octane, gamer-friendly showcase:

1. **Header & Value Pitch**:
   - Focus on what gamers care about: renaming vehicles, customizing kill messages, installing anime/meme packs, with 0 FPS loss, 0 game crashes, and 100% BattlEye anti-cheat safety.
2. **Translate Technical Concepts into Plain English**:
   - *Drift SQLite Delta Vault* ➔ **Armor-Plated Edit Locker**: Edits are stored safely in your PC's user profile, never in the game folder. Stock files stay 100% clean; Gaijin updates cannot wipe your work.
   - *120Hz Virtualized Cockpit & Multi-Threaded Isolates* ➔ **Instant 50,000+ String Cockpit**: Zero lag or stutter when searching through 50,000+ tanks, planes, ammo types, and kill messages.
   - *Immutable Delta-Synthesis* ➔ **Surgical Patching**: Only your customized words are modified. Everything else stays pure stock War Thunder.
   - *1-Click `config.blk` Hook* ➔ **1-Click Game Enabler**: Automatically turns on War Thunder's official custom localization mode (`testLocalization:b=yes`) without manual config editing.
   - *Community Presets* ➔ **Squadron & Community Sharing**: Export and share kill-feed packs, historical designations, or meme packs with friends via 1-click shareable JSON files.
3. **Major Update Survival Guide**:
   - Emphasize the **Automated Snapshot Safety Net**: Gramercy automatically snapshots your edits outside the game directory before any update or purge, with instant 1-click restore.
   - Step-by-step update routine simplified to 3 clear steps.

---

## 6. Testing & Quality Assurance Plan

1. **Unit Tests (`test/snapshot_service_test.dart`)**:
   - `createSnapshot`: successfully creates file in temp directory with valid JSON and metadata.
   - `listSnapshots`: lists snapshots in descending chronological order.
   - `restoreSnapshot`: batch upserts overrides into mock/in-memory database.
   - `deleteSnapshot`: removes file cleanly from disk.
   - Graceful handling: empty overrides, missing directory, corrupt JSON.
2. **Rebuild Integration Test**:
   - Verify `rebuildService.purgeLocalizationCache()` triggers snapshot creation when overrides exist.
3. **Widget Tests**:
   - `SnapshotHistoryDialog` renders list, empty state, and triggers restore callback.
4. **Quality Gates**:
   - `dart format --output=none --set-exit-if-changed .`
   - `flutter analyze` (0 warnings/errors)
   - `flutter test --coverage` ($\ge 80\%$ line coverage)
   - Strict LoC ceilings ($\le 200$ LoC per source file).
