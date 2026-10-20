# Reddit Launch Post

One post. One title. No alternatives. Post as a text post with one GIF and the link in the body.

**Title:** I made a free editor for War Thunder localization files so custom names stop dying on patch day

---

## Body

I rename vehicles and edit kill feed strings in War Thunder. I got tired of doing it in Notepad, and I got tired of losing it every time a patch replaced the `lang` folder.

So I wrote Gramercy, a desktop editor for the game's localization files. It is free, open source under GPL-3.0, and runs on Windows, Linux, and macOS. Windows is the main target.

What it does:

- Reads the CSVs that War Thunder dumps through the `testLocalization` hook.
- Stores your changes in a local SQLite database, outside the game folder.
- Writes only your changed strings back into `lang/*.csv` when you hit Deploy to Game, after making a `.orig` backup.
- Keeps a snapshot before each rebuild, so you can roll back.
- Exports and imports `.json` preset packs, so a squadron can share one file.
- Reapplies everything after a patch: Rebuild Game Strings, Purge Cache, launch the game once to the hangar, Reload & Apply. Your edits come back from the database, not from a backup copy of the game files.

What it does not do:

- It does not touch game memory, binaries, or network traffic. It writes text files and one line in `config.blk`.
- It does not give an advantage, unlock anything, or change gameplay.
- The game must be closed when you deploy or purge. Gramercy refuses to purge while War Thunder is running, and Windows will refuse the write if a CSV is locked.
- It is not code-signed. Windows SmartScreen will warn you.

On the anti-cheat question: custom localization is a Gaijin feature. `testLocalization:b=yes` in `config.blk` is the documented switch. Gramercy only writes those CSVs and that flag, and the source is public, so you can check that claim instead of trusting it. No ban reports are known to me. I cannot promise what Gaijin or BattlEye will do in the future, because that is not mine to promise.

Verify the download: every release ships a `SHA256SUMS.txt` next to the archives. The README has the one-line command to check it. Do that before you click Run anyway.

Repo and downloads: https://github.com/Vonarian/gramercy

Two preset packs are included, one for meme kill feeds and one for historical designations. Both are plain JSON, so you can read them before importing.

If it breaks, open an issue with your game version and the file you edited. I would rather fix a real bug than argue about whether the tool is useful.

---

## First comment to pin

Screenshots are from my machine, v1.6.0. The GIF shows one edit, Deploy to Game, and the result in the hangar. The patch-day loop is in the README if you want the full sequence.

## Notes

- Do not mention AI unless someone asks. If they ask, answer once with the facts from the playbook and link the repo.
- Do not edit the post to argue with a hostile comment. Reply in the thread, once, then stop.
- If a comment finds a real bug, say "that's a bug", fix it, and post the patch release in the same thread.
