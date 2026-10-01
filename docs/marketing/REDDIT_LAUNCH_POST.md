# Reddit Launch Posts (`r/Warthunder` & `r/warthundermemes`)

## 1. Primary Post: `r/Warthunder` (Showcase / Mod / Utility)

**Post Type:** Video / Link / Text Post with Media  
**Flair:** `Other` / `News` / `Art / Screenshot` (or Subreddit Mod Tool flair if approved)  

### Title Options
- **Option 1 (Recommended):** *I built an open-source tool so you never lose your custom vehicle names and kill feed memes when Gaijin drops an update [Gramercy v1.4.0]*
- **Option 2:** *Tired of major updates breaking your custom localization? Meet Gramercy: an open-source desktop cockpit with 1-click update rebuilds & JSON presets*
- **Option 3:** *No more Notepad crashes: Gramercy, a 120Hz localization editor that keeps your custom tank names safe across every WT patch*

### Recommended Media Attachment
Attach a short 20-30 second video or high-FPS GIF showing:
1. Searching `tiger_II` in 50,000 strings with instant filtering.
2. Changing the kill message to `"Sent to the Shadow Realm"`.
3. Clicking **Apply to Game**.
4. Showing the 3-step **Rebuild Game Strings Wizard** ("Purge Cache -> Launch WT -> Reload & Apply") showing how edits survive a patch.

---

### Post Body (Markdown)

Hey everyone,

If you’ve ever customized your War Thunder vehicle names, installed a meme kill feed, or used realistic NATO/Soviet vehicle designations, you already know the pain: **every time Gaijin drops a major patch, your files either break the game with missing `#hud_mission_fail` text or get completely wiped.**

Editing raw semicolon-delimited CSVs in Notepad or Excel sucks, one accidental missing quote crashes the client on launch, and sharing packs with your squadron requires manually copying giant files.

To fix this once and for all, I built **[Gramercy](https://github.com/Vonarian/gramercy)** — a free, open-source desktop cockpit for War Thunder custom localizations (Windows, Linux, and macOS).

---

### What it actually does:

- **🛡️ Your edits survive game updates**: Your customizations live in an isolated SQLite vault outside the War Thunder directory. When a patch drops, just open Gramercy, hit **Purge Cache**, open WT to hangar once so it dumps fresh strings, and click **Reload & Apply**. Gramercy automatically re-stamps all your customizations onto the new update.
- **⚡ Instant 50,000+ String Cockpit**: Zero UI lag. Multi-threaded background workers parse the massive CSVs so you can search through every vehicle, weapon, and radio command with instant 120Hz response.
- **📦 1-Click Community Presets (.json)**: You can export and import entire customization packs in compact `.json` files. We already bundled two starter packs:
  - *Classic Memes & Tactical Kill Feed* (e.g. "Sent to the shadow realm", "Turret Toss Champion", "Snail Shekels")
  - *Historical Military Nomenclature* (Realistic German, US, Soviet, and British designations)
- **🔄 Auto-Snapshot Safety Net**: Before every purge or rebuild, it automatically captures a restore point so you can roll back experimental changes with 1 click.
- **🛠️ 1-Click Game Enabler**: Automatically toggles `testLocalization:b=yes` in `config.blk`.

---

### Is this safe from BattlEye / Anti-Cheat bans?
**Yes, 100%.**
Custom localizations are an **officially documented feature** provided directly by Gaijin via the `testLocalization` flag in `config.blk`. Gramercy **never touches game memory**, runs zero code inside the game process, and doesn't modify network packets. It strictly writes plain text CSVs to your official `lang/` folder.

---

### Links & Downloads:
- **Download Latest Release:** [GitHub Releases](https://github.com/Vonarian/gramercy/releases/latest) (Windows `.zip`, Linux `.tar.gz`, macOS)
- **Source Code (GPL-3.0):** [GitHub Repository](https://github.com/Vonarian/gramercy)
- **Included Presets:** Check the `/presets` folder in the release for ready-to-import packs!

*(Note for Windows users: Because code signing certificates cost hundreds of dollars a year, Windows SmartScreen might pop up with "Unknown Publisher" — click "More Info" -> "Run anyway". The entire app is open-source and built transparently via GitHub Actions).*

Feedback, bug reports, and preset ideas are welcome! Let me know what you think.

---

## 2. Meme Post: `r/warthundermemes`

**Title:** *POV: You spend 2 hours editing CSV files in Notepad just for Gaijin to wipe it 10 minutes later*  
**Media:** Side-by-side meme image or video:
- *Top panel:* Player crying over a corrupted `units.csv` after an update.
- *Bottom panel:* Gigachad clicking "Reload & Apply" in Gramercy with 0 effort.
**Comment from OP:**  
*"Shameless plug for [Gramercy](https://github.com/Vonarian/gramercy) — made it so you never have to deal with broken CSVs or lost custom names on update day again. Fully open-source and free."*
