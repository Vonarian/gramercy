# Gramercy Launch Playbook

## Positioning

Gramercy is a free, open-source desktop editor for War Thunder localization files. It keeps your edits in a local database outside the game folder and writes them into `lang/*.csv` when you deploy. After a patch replaces those files, you rebuild once and reapply.

Use that paragraph, or a shorter version, everywhere. Do not add adjectives.

## Who it is for

- Players who renamed vehicles or edited kill feed, HUD, and menu strings by hand.
- Squadrons that share name packs.
- Anyone who tried the raw CSV route and lost edits on patch day.
- Linux and macOS players, with the caveat that Windows is the primary target.

## Proof inventory

Replace claims with these. They are checkable, and checkable things do not read as slop.

| Claim | Evidence |
| :--- | :--- |
| Source is public and GPL-3.0 | https://github.com/Vonarian/gramercy |
| The code is tested | 224 test cases across 42 files, coverage gate enforced in `.github/workflows/ci.yml` |
| Builds come from CI | `.github/workflows/release.yml`, `SHA256SUMS.txt` on every release |
| The app does not touch the game process | Read `lib/`: it writes `lang/*.csv` and `config.blk` only |
| Security issues were fixed publicly | README section 11, `CHANGELOG.md` |
| A human has been maintaining it | `git log`, public issues, release notes |

## Copy rules

1. No emoji in posts, listings, or release notes.
2. No "100%", "guaranteed", "zero lag", "instant", "seamless", "changes everything".
3. One claim per sentence. Every claim must be checkable in the repo or in a recording.
4. Name the limits. Windows first, Linux and macOS less exercised, no code signing, SmartScreen will warn.
5. First person. Past tense for what you did, present tense for what the app does.
6. One post per channel. Reply to comments for 48 hours. Do not run a campaign.
7. No AI art, AI voice, or AI footage. Raw screen capture only.
8. Version strings must match `pubspec.yaml`.
9. Do not argue with "this is AI slop" in the post. Answer one person, once, with a source link.
10. Do not ask for stars. Ask for bug reports and preset files.

## Sequence

### Before any public post

1. Pick five people who already use custom names or who have complained about patch-day wipes. Post in the threads where they complained.
2. Send them the release build and the one-line description. Ask for one thing: a screenshot or clip of it working on their machine. Do not ask for a review, a retweet, or a preset.
3. Fix whatever breaks. Ship a patch release with the fix named in the changelog.

Third-party clips are the only artifact that cannot be accused of being generated.

### Day 1: War Thunder Live

Publish one listing under Other / Mods & Tools using [`WAR_THUNDER_LIVE_POST.md`](WAR_THUNDER_LIVE_POST.md). Attach real screenshots from the running app plus the two bundled preset files. Reply to every comment that day.

### Day 2: r/Warthunder

Post the text from [`REDDIT_LAUNCH_POST.md`](REDDIT_LAUNCH_POST.md) with one GIF and no link post. Put the link inside the body. Answer the anti-cheat question in the thread with the precise wording from the objections section. Do not cross-post to other subreddits the same day.

### Day 3: Gaijin forum

One thread in the community tools section. Same body, shorter. Link the issue tracker.

### After launch

- Patch-day notes: within 24 hours of each War Thunder major update, publish a release with the new strings tested and the patch name in the title. This is the recurring proof that the project is alive.
- Creators: outreach only after a month of public issue traffic, and only to creators who already show custom names. See [`CREATOR_OUTREACH_KIT.md`](CREATOR_OUTREACH_KIT.md).
- Presets: repost community packs with credit. Never generate packs yourself and label them as community.

## Objection handling

**Will this get me banned?**
Custom localization is a documented Gaijin feature, enabled by `testLocalization:b=yes` in `config.blk`. Gramercy writes plain text CSVs and that flag. It does not attach to the game process, read its memory, or modify binaries or network traffic. The source is public; the file writes are the whole mechanism. No ban reports have been attributed to this tool. Do not promise that no future ban is possible, because that depends on Gaijin and BattlEye, not on us.

**Why does Windows warn about the download?**
The builds are not code-signed. Certificates cost several hundred dollars a year. Every release publishes a `SHA256SUMS.txt`; the README has the verify commands. Show the hash check in the recording.

**What happens on patch day?**
The patch overwrites `lang/*.csv`. In Gramercy: Rebuild Game Strings, Purge Cache, launch War Thunder once to the hangar so it dumps fresh strings, then Reload & Apply. Your overrides come back from the local database. Show this whole loop uncut at least once.

**Did AI write this?**
Answer with what is true. If AI assisted with tests, docs, or refactors, say so and point at the commit history for design decisions and the issue tracker for maintenance. Then link the source. Do not hide it; the repo is public and hiding reads worse than the assistance itself.

## Measurement

The app has no telemetry and should not get any for marketing. Measure what is visible:

- Issue reports with real reproduction steps.
- Preset files shared by other people.
- WT Live downloads and comments.
- Returning commenters across two patch cycles.
- Repeat mentions in squadron Discords.

Ignore stars, upvotes, and view counts. They do not survive the next patch.

## Do not

- Do not post the same copy to several subreddits or Discords in one day.
- Do not use AI thumbnails, voiceovers, or stock footage.
- Do not claim an advantage, an unlock, or anything that affects gameplay.
- Do not ship a marketing doc with a version that is not in `pubspec.yaml`.
- Do not ask moderators to pin or endorse the tool.
