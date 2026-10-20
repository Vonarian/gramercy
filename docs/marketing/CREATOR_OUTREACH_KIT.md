# Creator and Community Outreach

Short messages. No flattery paragraph, no feature list, no ask. The goal is a working build in their hands, not a review.

## 1. Direct message to a creator

Send only to creators who already show custom names, kill feed text, or localization edits in their videos. If they do not, do not send it.

**Subject:** Gramercy, an editor for War Thunder localization files

> Hey [name],
>
> You use custom vehicle names in your videos, so this may save you time. I wrote Gramercy, a free open-source editor for War Thunder's localization files. It keeps your edits outside the game folder and reapplies them after patches.
>
> Build for your platform: [release link]. Windows will warn about an unknown publisher; the release has a SHA256SUMS file and the README shows how to check it.
>
> No ask. If it is useful, use it. If it breaks, tell me and I will fix it.

Keep it under 100 words. Do not offer money, a "partnership", or a featured spot in the first message.

## 2. Squadron Discord message

Post in the tools or mods channel, not in general chat, and only with the moderator's permission.

> Gramercy, free open-source editor for War Thunder localization files: [link]
>
> Renames vehicles and edits kill feed and HUD strings, keeps them in a local database outside the game folder, and reapplies them after patches. Writes only `lang/*.csv` and the `testLocalization` flag in `config.blk`; it does not touch the game process.
>
> Windows, Linux, macOS. Not code-signed, so verify the release hash. Bug reports go to the issue tracker.

Do not paste a feature grid. Do not use emoji headers.

## 3. Sharing a preset with a creator

Only with their consent, and only from strings they actually published.

1. Ask if they want their setup packaged as a `.json` preset.
2. If yes, ask them to export it themselves from Gramercy, or send you the exact strings and the file they belong to.
3. Name the file after them, credit them in the release notes, and link their channel.
4. Never reverse-engineer a creator's list from a video and ship it as a pack. That is the fastest way to lose the community.

## 4. What to do when someone calls it AI slop

Reply once, in the same thread, without defensiveness:

> Fair to be suspicious. The source is at [repo], GPL-3.0. It writes CSVs and one line in `config.blk`; you can read the whole write path. Here is the CI run and the release checksums: [links]. If something looks generated rather than built, point at it and I will fix it.

Then stop. Do not repeat the defense in other threads, and do not ask allies to argue for you.
