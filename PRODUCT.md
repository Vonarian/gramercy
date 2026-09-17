# Product

<!-- impeccable:product-schema 1 -->

## Platform

windows

## Users

War Thunder players, modders, simulation pilots/tankers, and localized content creators who customize vehicle names, kill feed messages, weapon designations, and UI terminology.

## Product Purpose

Provide a native, ultra-responsive, zero-UI-lag desktop editor for War Thunder localization files. Modders can easily search through 50,000+ game strings, override vehicle/mission/menu names, and deploy them directly to the game without permanently altering original game assets or losing custom names across game updates.

## Positioning

Unlike raw text/spreadsheet editors or destructive patch scripts, Gramercy uses a delta-patching engine: base game files are parsed purely in-memory via multi-threaded background isolates, user edits are stored strictly as delta overrides in a local SQLite vault, and files are synthesized on-the-fly and safely deployed to War Thunder's `lang/` folder with automatic backup and `config.blk` hook management.

## Operating Context

- War Thunder game root directory (`C:\Program Files (x86)\Steam\steamapps\common\War Thunder` or custom Gaijin install).
- `config.blk` engine configuration with `testLocalization:b=yes` in the `debug { ... }` block.
- `lang/` directory containing semicolon-delimited CSVs (`units.csv`, `menu.csv`, `missions.csv`, `ui.csv`, etc.).

## Capabilities and Constraints

- **Delta Vault**: Drift SQLite database storing only `(fileName, stringKey, customValue, updatedAt)`.
- **Isolate Offload**: All CSV parsing and export synthesis run off the UI thread via `worker_manager` isolates.
- **Fixed-Extent Virtualization**: Fixed `itemExtent` virtualized list view ensuring steady 120Hz rendering over 50,000+ localization rows.
- **Preserved Multi-Language Columns**: Exporter preserves all non-English columns and headers from base game CSVs while patching edited keys.
- **Non-Destructive Backups**: Preserves `<filename>.orig` before any write.

## Brand Commitments

Tactical, clean, dark-mode desktop tool aesthetics matching modern military simulation flight-deck instrumentation (dark slate, tactical amber accents, crisp tabular monospace keys, instant responsiveness).
