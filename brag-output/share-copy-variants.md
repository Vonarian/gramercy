# Gramercy Showreel — Share Copy Variants

## 1. LinkedIn (Engineering Leadership & Recruiters)
> Ever had a game update completely obliterate hundreds of hours of community modding work?
> 
> In War Thunder, modders customize over 50,000 localization strings (historical vehicle designations, HUD alerts, kill feeds). Every major Gaijin patch permanently overwrites manual CSV modifications, causing client crashes.
> 
> I engineered **Gramercy** to solve this permanently through high-performance desktop architecture:
> • **Immutable Delta Synthesis**: Stock game CSVs are never overwritten. Overrides live in a local Drift SQLite delta vault.
> • **120Hz Virtualized Cockpit**: Zero dropped frames when scrolling and filtering across 50,000+ entries.
> • **Zero UI Thread Hitching**: Parsing, token indexing, and export compilation offloaded to background multi-threaded worker isolates (`worker_manager`).
> • **100% BattlEye Anti-Cheat Safe**: Pure text manipulation via official `testLocalization:b=yes` hook — zero DLL injection or process memory hooks.
> • **1-Click Game Update Rebuild**: Automatically snapshots `.orig` backups, purges cache, and re-stamps saved deltas in seconds.
> 
> Check out the 15-second tactical showreel and source code:
> https://github.com/Vonarian/gramercy

---

## 2. Twitter / X & Discord
> War Thunder modders: stop letting major updates nuke your custom strings.
> 
> Built **Gramercy** — a native 120Hz tactical cockpit with Drift SQLite delta synthesis and isolate multi-threading that makes 50k+ strings 100% BattlEye safe.
> 
> 1-click update survival. Zero stock files overwritten.
> 
> https://github.com/Vonarian/gramercy

---

## 3. Resume / Portfolio Project Bullet Points
- **Gramercy (Lead Architect & Developer)**: Engineered a native cross-platform desktop application (Flutter Desktop, Riverpod 3, Drift SQLite) for War Thunder localization modding with 50,000+ entries.
- **High-Concurrency Isolate Architecture**: Designed a multi-threaded background isolate pipeline (`worker_manager`) for parsing, token indexing, and search debouncing (<150ms latency), maintaining fluid 120Hz virtualized UI rendering.
- **Immutable Delta Storage & Anti-Cheat Compliance**: Architected an isolated SQLite delta synthesis engine ensuring 100% BattlEye Anti-Cheat compliance via official client hooks, preventing data loss across major game updates with automated 1-click rebuild workflows.
