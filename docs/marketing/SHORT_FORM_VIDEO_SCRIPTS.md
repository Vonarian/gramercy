# Short-Form Video: Raw Capture Shot List

No voiceover. No AI footage, art, or voice. No stock clips. One screen recording, trimmed only where the app loads. Game audio only, or silence.

This format exists because a produced ad reads as generated. An uncut capture of the app working is the opposite signal, and it is cheaper to make.

## Setup

- 1080p at 60 fps, OBS or the OS recorder.
- Show the system clock. Window edges visible. Mouse cursor visible.
- Clean desktop, no unrelated windows.
- Record on the machine you actually play on.
- Captions typed into the editor, correct spelling, no emoji.
- Final length 60 to 90 seconds. Vertical crop for Shorts and Reels, same file.

## Clip A: patch day (primary)

| Time | Screen | Caption |
| :--- | :--- | :--- |
| 0:00 | Hangar with a broken or stock vehicle name after a patch. Show the actual client, not a mockup. | A patch replaced my `lang` folder |
| 0:08 | Open Gramercy. Localization strings are still listed. | My edits were never in that folder |
| 0:15 | Search a vehicle. `units.csv` filters as you type. | Stored in a local database |
| 0:25 | Edit one string, Save Override. Show the row change. | Save Override |
| 0:32 | Click Rebuild Game Strings. Read the dialog aloud on screen. | Rebuild Game Strings |
| 0:40 | Purge Cache. Snapshot is created, show the confirmation. | Purge Cache, snapshot taken |
| 0:48 | Launch the game once to the hangar, then return. | Launch once so the game dumps new strings |
| 0:56 | Reload & Apply. Show the applied count. | Reload & Apply |
| 1:04 | Back in the hangar with the custom name. | Same edit, new patch |
| 1:10 | Cut to the release page and `SHA256SUMS.txt`. | Source, checksums, free |

If any step fails on camera, keep the failure in and show the fix. That is more convincing than a clean run.

## Clip B: one rename (secondary)

| Time | Screen | Caption |
| :--- | :--- | :--- |
| 0:00 | Gramercy open on `units.csv`. | 40 seconds, one rename |
| 0:05 | Type a search, click a row, change the name. | No Notepad |
| 0:15 | Save Override, Deploy to Game. | Deploy to Game |
| 0:25 | Alt-tab to the hangar. Name changed. | No game restart |
| 0:35 | Open the preset export dialog. | One JSON file to share |

## Clip C: realism pair (optional)

Only with the bundled historical preset and real client footage.

| Time | Screen | Caption |
| :--- | :--- | :--- |
| 0:00 | Vanilla name in the hangar. | Stock |
| 0:06 | Same vehicle, historical designation. | With the historical preset |
| 0:14 | Scroll the preset file in a text editor. | It is a JSON file, read it |
| 0:22 | Show the import and Deploy to Game. | Import, deploy, done |

## Posting

- One caption per platform. No hashtag walls. Three tags at most.
- Put the repo link in the first comment, not in the video.
- Pin a comment with the checksum verification step.
- Reply to every comment for 48 hours.
- Do not repost the same clip to four platforms in one hour. Stagger by a day.

## Do not

- Do not use a synthetic voice. If you will not speak, use captions.
- Do not add a phonk track over footage you did not record.
- Do not show a benchmark number you have not measured on camera.
