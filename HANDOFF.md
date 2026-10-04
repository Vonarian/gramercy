# Gramercy v1.4.0 — Project Hand-off & Launch Runbook

> **Date**: Sunday, October 4, 2026  
> **Status**: Ready for Release / Marketing Execution  
> **Branch**: `dev` (synchronized with `origin/dev`), verified clean  
> **Primary Launch Window**: **17:30 – 19:30 IRST** (14:00 – 16:00 UTC)

---

## 1. Executive Summary

All engineering, documentation, test suites, starter presets, in-game screenshot proof captures (with Afterburner OSD removed), demo walkthroughs, and cinematic trailers are **100% complete and verified**.

The repository has passed strict quality directives:
* `dart format --output=none --set-exit-if-changed .` — Clean (0 diffs).
* `flutter analyze` — Zero issues.
* `flutter test --coverage` — 83/83 tests passing.
* `hyperframes check` — 0 errors, 43/43 WCAG AA contrast compliance.

---

## 2. Core Deliverables & Asset Map

### 2.1 Video Media
| File Path | Description | Spec / Duration |
| :--- | :--- | :--- |
| [`docs/marketing/gramercy_brag_launch.mp4`](file:///d:/src/gramercy/docs/marketing/gramercy_brag_launch.mp4) | High-energy kinetic launch video rendered via Hyperframes | 1080p, 30 FPS, 15.0s, Beat-synced |
| [`docs/marketing/gramercy_cockpit_demo.mp4`](file:///d:/src/gramercy/docs/marketing/gramercy_cockpit_demo.mp4) | Real desktop recording showing search debounce, editing, and deployment | 1080p, 60 FPS, 20.8s, High-bitrate |
| [`brag-output/`](file:///d:/src/gramercy/brag-output/) | Full Hyperframes HTML/GSAP/audio composition project | Reproducible rendering pipeline |

### 2.2 In-Game Screenshots (MSI Afterburner OSD Cleaned via Radial Vignette LUT)
| File Path | In-Game Text / Context | Target CSV Key |
| :--- | :--- | :--- |
| [`docs/screenshots/wt_target_obliterated.jpg`](file:///d:/src/gramercy/docs/screenshots/wt_target_obliterated.jpg) | `"TARGET OBLITERATED"` (Tank kill fireball) | `exp_reasons/kill_gm` |
| [`docs/screenshots/wt_sent_back_to_hangar.jpg`](file:///d:/src/gramercy/docs/screenshots/wt_sent_back_to_hangar.jpg) | `"SENT BACK TO HANGAR"` (Air kill in sniper view) | `exp_reasons/kill_air` |
| [`docs/screenshots/wt_hangar_custom.jpg`](file:///d:/src/gramercy/docs/screenshots/wt_hangar_custom.jpg) | `"SUFFER IN BATTLE!"` & `"M3A3 Bradley CFV"` | `exp_reasons/kill_mission` |
| [`docs/screenshots/wt_tickle_hit.jpg`](file:///d:/src/gramercy/docs/screenshots/wt_tickle_hit.jpg) | `"TICKLE (+10 SL)"` (Gepard 3rd-person hit) | `exp_reasons/hit` |
| [`docs/screenshots/cockpit_populated.png`](file:///d:/src/gramercy/docs/screenshots/cockpit_populated.png) | High-resolution populated Windows cockpit screenshot | 48,514 strings, 37 active overrides |

### 2.3 Community Presets (`presets/`)
| File Path | Contents | Purpose |
| :--- | :--- | :--- |
| [`presets/meme_killfeed_pack.json`](file:///d:/src/gramercy/presets/meme_killfeed_pack.json) | 16 meme overrides (`TARGET OBLITERATED`, `SENT BACK TO HANGAR`, `SUFFER IN BATTLE!`, `TICKLE (+10 SL)`) | Instant fun killfeed overhaul |
| [`presets/historical_realistic_designations.json`](file:///d:/src/gramercy/presets/historical_realistic_designations.json) | 21 realistic military designations (`M3A3 Bradley CFV`, `Leopard 2A7V`, `ZSU-23-4V Shilka`) | Historical immersion |

---

## 3. Marketing Launch Schedule (Sunday, Oct 4, 2026)

All times are aligned for maximum European evening + US East Coast morning/lunch overlap.

### Phase 1: Pre-Launch Setup (16:30 – 17:15 IRST / 13:00 – 13:45 UTC)
1. **Merge `dev` to `main` via PR**:
   - URL: [https://github.com/Vonarian/gramercy/compare/main...dev?expand=1](https://github.com/Vonarian/gramercy/compare/main...dev?expand=1)
   - PR Title: `release(v1.4.0): War Thunder Localization Cockpit & Community Delta Vault`
   - Merge the PR once opened.
2. **Draft GitHub Release**:
   - URL: [https://github.com/Vonarian/gramercy/releases/new](https://github.com/Vonarian/gramercy/releases/new)
   - Tag: `v1.4.0` (target `main`)
   - Title: `Gramercy v1.4.0 — War Thunder Localization Cockpit & Community Delta Vault`
   - Body: Copy directly from [`docs/marketing/release_notes_v1.4.0.md`](file:///d:/src/gramercy/docs/marketing/release_notes_v1.4.0.md).
   - Attach: Release binaries and the two `.json` preset files in [`presets/`](file:///d:/src/gramercy/presets/).

---

### Phase 2: Official Launch (17:30 IRST / 14:00 UTC)
1. **Publish GitHub Release**:
   - Switch release draft to **Published**.
2. **War Thunder Live Post**:
   - Portal: [live.warthunder.com](https://live.warthunder.com)
   - Category: **Sounds & Language** / **Game Modifications**
   - Title: `Gramercy v1.4.0: Modern Localization Cockpit & Delta Vault (100% Patch-Proof)`
   - Text Copy: Copy from [`docs/marketing/wt_live_post.md`](file:///d:/src/gramercy/docs/marketing/wt_live_post.md).
   - Images to attach:
     - Cover: `docs/screenshots/cockpit_populated.png`
     - Action shots: `docs/screenshots/wt_target_obliterated.jpg`, `docs/screenshots/wt_sent_back_to_hangar.jpg`, `docs/screenshots/wt_hangar_custom.jpg`.

---

### Phase 3: The Reddit Wave (18:00 – 18:15 IRST / 14:30 – 14:45 UTC)
*(Peak browsing start for r/Warthunder)*

1. **Subreddit**: `r/Warthunder`
2. **Post Format**: **Video Post** (native video upload for autoplay)
   - Upload file: [`docs/marketing/gramercy_brag_launch.mp4`](file:///d:/src/gramercy/docs/marketing/gramercy_brag_launch.mp4) (or `docs/marketing/gramercy_cockpit_demo.mp4`)
   - Title:
     > *Tired of War Thunder patches wiping your custom kill messages? I built Gramercy — a free, open-source tool that keeps vanilla files untouched and restores your strings in 1 click [v1.4.0]*
   - Flair: `Datamine / Custom Content` or `Other`
3. **First Comment (Within 60 Seconds)**:
   - Post the comprehensive explanatory comment copied from [`docs/marketing/reddit_post.md`](file:///d:/src/gramercy/docs/marketing/reddit_post.md) (features, presets, safety notes, and GitHub link).

---

### Phase 4: Socials & Video Platforms (18:30 – 19:30 IRST)
1. **YouTube Shorts / TikTok / X (Twitter)**:
   - Video: `docs/marketing/gramercy_brag_launch.mp4`
   - Hashtags: `#WarThunder #WarthunderMoments #PCGaming #GamingMods #OpenSource`
2. **War Thunder Discord Hubs**:
   - Post in community modding and content channels linking WT Live and GitHub.

---

## 4. Documentation Reference Index

All detailed promotional copy and step-by-step guides reside in `docs/marketing/`:
* 📄 [`docs/marketing/launch_schedule_and_checklist.md`](file:///d:/src/gramercy/docs/marketing/launch_schedule_and_checklist.md) — Comprehensive timeline & checklist
* 📄 [`docs/marketing/release_notes_v1.4.0.md`](file:///d:/src/gramercy/docs/marketing/release_notes_v1.4.0.md) — GitHub release notes
* 📄 [`docs/marketing/reddit_post.md`](file:///d:/src/gramercy/docs/marketing/reddit_post.md) — Complete Reddit post title & comment copy
* 📄 [`docs/marketing/wt_live_post.md`](file:///d:/src/gramercy/docs/marketing/wt_live_post.md) — WT Live mod page description
* 📄 [`docs/marketing/distribution_strategy.md`](file:///d:/src/gramercy/docs/marketing/distribution_strategy.md) — Audience segmentation and engagement playbook
