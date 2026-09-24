# Changelog

All notable changes to **Gramercy** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.3.1] - 2026-09-24

### Fixed
- **Complete Cache Purge (`localization.blk` Removal)**: Fixed an issue where `purgeLocalizationCache` only deleted `.csv` and `.orig` files while preserving `localization.blk`. Because War Thunder's Dagor engine uses `localization.blk` as the sentinel for an already-initialized localization directory, the game skipped generating fresh files. Purge now cleanly removes `localization.blk` as well.
- **Safety Auto-Backup (`BackupService`)**: Added automated timestamped backup of all files in `<War Thunder>/lang/` into `<War Thunder>/lang_backups/backup_<timestamp>` prior to executing any purge, preventing accidental loss of local files.
- **Game Running Guard & Confirmation Modal (`PurgeConfirmDialog`)**: Added interactive confirmation modal before purging with live `isGameRunning` process detection (`GameProcessService`). Warns players if War Thunder (`aces.exe`) is actively running and guides them to close the game before purging to prevent file lock and shutdown rewrite conflicts.
- **Modularity & Architecture Refactor**: Decomposed `rebuild_dialog.dart` and `purge_confirm_dialog.dart` into granular widgets (`purge_safety_cards.dart`, `rebuild_dialog_cards.dart`) adhering strictly to the $\le 200$ LoC constraint.

---

## [1.3.0] - 2026-09-23

### Added
- **In-App Rebuild Game Strings Workflow**: Added `RebuildService`, `RebuildDialog`, and `RebuildButton` to streamline surviving major War Thunder updates.
  - **Step 1: Automated Cache Purge**: Safely wipes old CSVs and stale `.orig` backups in `<War Thunder>/lang/` and verifies `testLocalization:b=yes` in `config.blk`.
  - **Step 2: Generation & Live Detection**: Launches War Thunder to extract fresh CSVs and automatically polls/detects when new patch strings appear on disk.
  - **Step 3: 1-Click Reload & Deploy**: Invalidates the in-memory cache to ingest new game strings and re-stamps all active custom overrides from SQLite without restarting Gramercy.
- **Top App Bar Integration**: Mounted the new rebuild button directly into the desktop command header.

---

## [1.2.1] - 2026-09-18

### Added
- **Bundled Fonts**: Bundled **Inter** (Regular 400, Medium 500, SemiBold 600, Bold 700) and **JetBrains Mono** (Regular 400, Medium 500, Bold 700) directly in `assets/fonts/` for 100% offline desktop performance.
- **Font Registration**: Registered font families cleanly in `pubspec.yaml` with cross-platform fallback font stacks in `AppTheme`.

### Changed
- **Text-Editor Class Typography**: Refined table row typography in `LocalizationRowItem` (12.5px `w500` monospace keys with balanced letter-spacing, 13px base text and custom overrides) to match premier code and text editing environments.
- **Version Bump**: Updated app version to `v1.2.1` in `pubspec.yaml` and `AboutGramercyDialog`.

---

## [1.2.0] - 2026-09-18

### Added
- **Community Preset Sharing**: Added `PresetService` allowing players and modders to export their active delta modifications to `.json` files (`gramercy_preset_v1`) or import packs from the community.
- **Batch Upsert Engine**: Added `batchUpsertOverrides` and `getAllOverrides` to `AppDatabase` executing fast atomic SQLite transactions.
- **Presets Menu**: Integrated `PresetsMenuButton` in the top app bar for 1-click import and export via native OS file dialogs.
- **About & BEAC Safety Dialog**: Added comprehensive `AboutGramercyDialog` displaying vintage radio headset branding, app lore origin (`[T-4-6]` radio callout), 100% BattlEye Anti-Cheat (BEAC) safety details, and Windows SmartScreen guidance.
- **Marketing README**: Overhauled `README.md` with visual architecture diagrams, UI screenshots, Major Game Update Survival Guide, and BattlEye compliance documentation.

---

## [1.1.3] - 2026-09-18

### Added
- **CI/CD Automation**: GitHub Actions pipeline for linting, format validation, and test suite execution (`ci.yml`).
- **Release Automation**: Multi-platform release publishing pipeline (`release.yml`) that automatically builds, packages, and attaches release bundles (`windows-x64.zip`, `linux-x64.tar.gz`, `macos.zip`) upon push to `main` or version tags.
- **Strict Formatting Mandate**: Updated `AGENTS.md` and repository standards requiring `dart format --output=none --set-exit-if-changed .` with zero diffs.

---

## [1.1.2] - 2026-09-17

### Added
- **Desktop Launcher Icons**: Generated and integrated native icons across all 3 desktop platforms:
  - Windows: Multi-resolution `app_icon.ico` compiled into executable resources via `Runner.rc`.
  - macOS: Asset catalog `.appiconset` across all display scales.
  - Linux: GTK runtime window icon binding in `my_application.cc`.

---

## [1.1.1] - 2026-09-17

### Added
- **App Logo**: Vintage communications radio headset with tactical `[Δ]` voice callout patch and drafting pencil, reflecting the authentic War Thunder *"Gramercy!"* spirit.

### Fixed
- **Sidebar Header Overflow**: Fixed a 3.0px `RenderFlex` overflow when collapsing the file drawer to standard 56px desktop rail width.

---

## [1.1.0] - 2026-09-17

### Added
- **Master-Detail Desktop UI**: Collapsible `FileSidebar` with real-time modified override counters.
- **Big-File Performance Engine**: Pre-indexed search tokens and 150ms keystroke debounce in `SearchQueryNotifier` for zero-latency searching across 50,000+ entries.
- **Cross-Platform Auto-Detection**: Instant discovery of War Thunder directories across Windows (Steam/Standalone), Linux (Steam paths), and macOS (Application Support).
- **config.blk Hook**: Automated detection and injection of `testLocalization:b=yes` in War Thunder engine configuration.
- **120Hz Virtualized List**: Re-architected localization list with fixed-extent virtualization (`itemExtent: 56.0`).

---

## [1.0.0] - 2026-09-16

### Added
- Initial release of **Gramercy**.
- Drift SQLite Delta Vault for non-destructive local overrides.
- Background isolate workers for CSV parsing, filtering, and export.
- Riverpod 3 reactive state synthesis pipeline.
