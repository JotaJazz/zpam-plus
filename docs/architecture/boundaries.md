# Boundaries

| Rule | Why |
|---|---|
| Match behaviour stays zPAM 3.38 unless a change is written in `docs/CHANGES.md` | competitors and admins expect zPAM rules |
| The mod runs only where `sv_plus` is 122 or later | [ADR 0001](adr/0001-plus-server-only.md) |
| Never trust a value a client can set to decide Plus, rules or results | a client controls its userinfo and cvars |
| Precache before the first `wait` of a map; new strings for `SetText` go through `precacheString2` in `game["firstInit"]`, as the existing code does | the engine only precaches at map start; `game[]` keeps the string across round restarts |
| A feature is a `_<name>.gsc` module started from `InitModules`, in dependency order, and talks to others through `global/events.gsc` | keeps modules independent of the call order of engine callbacks |
| Rule values live in `rules/`, read through `global/cvar_system.gsc` | one place per pam_mode, defaults restored on mode change |
| The iwd name equals `level.pam_folder`; every line that carries the name or version is marked `// ZPAM_RENAME` | the installation check refuses any other name |
| The mod runs from `main`, never from `fs_game` | mods do not exec player configs |

## Forbidden

- Server or client code in this repository: those changes go to their own
  repositories.
- Renaming or versioning without updating every `ZPAM_RENAME` line.
