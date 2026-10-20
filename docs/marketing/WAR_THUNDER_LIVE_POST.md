# War Thunder Live Listing

**Category:** Other / Mods & Tools
**Tags:** `#tool #localization #names #killfeed #utility`

**Title:** Gramercy: a free desktop editor for War Thunder localization files

---

## Body

Gramercy edits the text strings War Thunder loads through its own localization hook. Rename vehicles, change kill feed and HUD messages, then write the changes back into `lang/*.csv`. Your edits live in a local database outside the game folder, so a patch that replaces those files does not delete them.

It is free, open source under GPL-3.0, and runs on Windows (primary), Linux, and macOS.

### What it actually does

- Search and edit the game's localization strings in one list, with token filtering.
- Store overrides in SQLite, outside the War Thunder directory.
- Write only changed strings back to `lang/*.csv`, with a `.orig` backup and an atomic rename.
- Save a snapshot before each cache purge or rebuild, and restore it later.
- Export and import `.json` preset packs.
- Toggle `testLocalization:b=yes` in `config.blk` for you.

### Patch day

A patch overwrites the localization files. The rebuild is manual on purpose:

1. Rebuild Game Strings, then Purge Cache.
2. Launch War Thunder once to the hangar so it dumps fresh strings.
3. Reload & Apply. Overrides come back from the database.

### Anti-cheat

Custom localization is a Gaijin feature. `testLocalization:b=yes` is the documented flag. Gramercy writes plain CSVs and that one line in `config.blk`. It does not attach to the game, read its memory, or modify binaries or network traffic. The source is public, so the file writes are auditable. No ban reports are known to me. Future enforcement is Gaijin's call, not mine.

### Quick start

1. Download the archive for your platform from Releases and verify it against `SHA256SUMS.txt`.
2. Extract and run `gramercy.exe` (or `./gramercy`, or `gramercy.app`).
3. Point Gramercy at your War Thunder install, or let it scan Steam.
4. Click Enable in config.blk.
5. Pick a file, search a string, save an override, then Deploy to Game.

Windows SmartScreen will warn about an unknown publisher. The builds are not code-signed, and that is explained in the README along with the hash check.

### Included presets

- `meme_killfeed_pack.json`
- `historical_realistic_designations.json`

Both are plain JSON. Read them before importing.

### Known limits

- Windows is the primary target. Linux and macOS builds exist and are less exercised.
- The game must be closed while deploying or purging. Gramercy blocks the purge when War Thunder is running, and Windows blocks the write if a CSV is locked.

### Links

- Releases: https://github.com/Vonarian/gramercy/releases/latest
- Source and issues: https://github.com/Vonarian/gramercy

Bug reports with the game version and the edited file are more useful than a star.
