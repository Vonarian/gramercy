# Hyperframes Composition Brief: Gramercy

## Objective
Create a dynamic 15-second motion graphics resume showreel for Gramercy, showcasing its senior desktop software architecture and tactical cockpit UI.

## Output
- Composition directory: `brag-output/composition/`
- Rendered video: `brag-output/brag.mp4`
- Format: landscape — 1920x1080 (60 FPS)
- Duration: 15.0 seconds

## Source Material
- Project root: `/Users/vonar/personal_src/gramercy/`
- Primary files read: `README.md`, `pubspec.yaml`, `assets/images/app_logo.png`, `docs/screenshots/cockpit_populated.png`
- Product name: Gramercy
- Tagline / strongest claim: "War Thunder Localization Cockpit & Community Delta Vault — 100% BattlEye Anti-Cheat Safe"
- Key UI or visual moment to recreate:
  - Live virtualized cockpit with real vehicle designations (`germ_leopard_2a7v`, `ussr_t_80bvm`)
  - Drift SQLite immutable delta synthesis model
  - 1-Click Game Update Rebuild engine
- Copy that must appear verbatim:
  - "50,000+ War Thunder Strings"
  - "Manual CSV modding breaks every patch"
  - "GRAMERCY"
  - "Tactical Delta Vault"
  - "Immutable Delta Synthesis"
  - "100% BattlEye Anti-Cheat Safe"
  - "Multi-Threaded Isolate Engine"
  - "Survive Major Game Updates in 1 Click"
  - "Engineered for Extreme Stability"

## Creative Direction
- Tone preset: `cinematic` / `polished`
- Creative direction: Tactical Cyber-Cockpit & Senior Desktop Engineering Showreel
- Interpretation: Fast-paced military flight HUD styling, high-contrast monospace typography, 3D floating cockpit UI windows, glowing telemetry callouts, and clean architectural authority.
- Angle: Senior desktop software engineering solves a massive gaming community headache through immutable SQLite delta synthesis, isolate multi-threading, and 120Hz virtualization.
- Hook: Red alert tactical HUD warning of 50k+ strings breaking on patch day.
- Outro: Golden Gramercy emblem with docked engineering stack badges.
- Avoid:
  - Generic SaaS language ("streamline your workflow", etc.)
  - Abstract decorative filler unrelated to aviation/tactical telemetry
  - Slow or unreadable typography

## Visual Identity
- Background: `#0A0D12` (deep cockpit slate), `#121721` (hud container background)
- Text: `#F1F5F9` (flight white), `#94A3B8` (muted telemetry), `#64748B` (secondary labels)
- Accent: `#FF9F1C` (tactical amber), `#00E5FF` (radar cyan), `#00FF66` (weapons green), `#EF4444` (hazard red)
- Display font: monospace system font, `Courier New`, `ui-monospace`
- Body font: system-ui, `-apple-system`, `Inter`, sans-serif
- Visual references from the project: `assets/images/app_logo.png`, `docs/screenshots/cockpit_populated.png`

## Storyboard
Follows the 5 scenes in `brag-output/brag-plan.md`:
1. **Scene 1 (0.0s – 3.0s)**: Hazard hook with glitch scanlines and shattering CSV warning.
2. **Scene 2 (3.0s – 6.5s)**: Gramercy title lock + 3D floating cockpit window with 3 delta engine callouts.
3. **Scene 3 (6.5s – 10.0s)**: Search debouncing counter (<150ms / 50k entries) + 100% BattlEye safe shield + isolate threading badge.
4. **Scene 4 (10.0s – 13.0s)**: 1-Click Game Update Rebuild pipeline (3 steps + all overrides preserved stamp).
5. **Scene 5 (13.0s – 15.0s)**: Gramercy golden crest lock-on + architecture tech stack badges.

## Audio
- Audio role: High-energy electronic rhythm bed with tactical mechanical SFX
- Music: `happy-beats-business-moves-vol-11-by-ende-dot-app.mp3`
- Music treatment: Starts at 0.0s, high energy through 14.5s, clean fadeout on stinger.
- SFX: Tactical interface clicks, keyboard typing sounds, glitch risers, heavy plate impact on cockpit reveal.

## Hyperframes Instructions
- Use pure deterministic GSAP timelines seeking from `data-duration="15.0"`.
- Size canvas explicitly to 1920x1080.
- All font-families must use system-safe stacks or defined fonts.
- Center layouts cleanly without CSS transform conflict on GSAP target properties.
- Run `npx hyperframes check` to ensure zero lint, layout, or contrast errors.
