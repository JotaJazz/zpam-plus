# Overview

The mod is GSC scripts, menus and assets under `source/`, packed as one iwd
that loads from `main`. Paths below are under `source/maps/mp/gametypes/`.

## Start of a map or round

```
<gametype>.gsc main()                 sd, dm, tdm, ctf, hq, htf, re, strat
├── global/_init.gsc InitSystems()    every map load and round restart
│   ├── _callbacksetup.gsc            engine callbacks → events
│   ├── global/events.gsc             listener registry (addEventListener)
│   ├── global/cvar_system.gsc        registerCvarEx, defaults, change watch
│   ├── global/pam.gsc                pam_mode, installation check
│   ├── global/rules.gsc              loads the rules of pam_mode
│   ├── global/cvars.gsc              game cvars
│   └── global/precache.gsc           only when game["firstInit"]
└── global/_init.gsc InitModules()    one thread per feature module (_*.gsc)
```

`InitModules` starts the modules in a fixed order; the comments on each line
there say which module depends on which (readyup before timeout, matchinfo
before record, and so on).

## Shared gametype code

Function bodies that were copied between gametype files live once in
`global/gametype_*_common.gsc`, pulled in with `#include`. A gametype must not
define a function its includes define (the compiler refuses it), so each file
holds only what every gametype including it shares.

| File | Included by |
|---|---|
| `global/gametype_common.gsc` | ctf, dm, htf, hq, re, sd, tdm |
| `global/gametype_respawn_common.gsc` | ctf, dm, htf, hq, tdm |
| `global/gametype_team_common.gsc` | ctf, htf, hq, tdm |
| `global/gametype_round_common.gsc` | re, sd |
| `global/gametype_flag_common.gsc` | ctf, htf |

Inside them, calls to a gametype's own spawn functions go through
`level.spawnPlayer`, `level.spawnSpectator` and `level.spawnIntermission`.

## Rules

`pam_mode` is `pub`, or `comp` (also `warmup` in dm) followed by `_<score>` and
`_<toggle>` suffixes in any order, checked by `IsValidPAMModeForGametype` in
`global/rules.gsc`. strat takes any value at map start and refuses changes.

| Part | Values | Files |
|---|---|---|
| mode | `pub` (no suffixes), `comp`; `warmup` in dm | `rules/<gametype>/<mode>.gsc`, `rules/strat/strat.gsc` |
| score | sd and re: `mr3`, `mr10`, `mr12`, `mr15`, `20rounds`; others: `10min`, `15min`, `30min`, `60min`, `unlim` | `rules/<gametype>/score/` |
| toggle | `2v2`, `rifle`, `lan`, `custom` (`developer` when `developer_script` is 1) | `rules/_2v2.gsc`, `rules/rifle.gsc`, `rules/lan.gsc`, `rules/custom.gsc` |

## Installation check

`CheckInstallation` in `global/pam.gsc` runs at each game start. On the first
failure `setError` sets `level.pam_installation_error`, draws a black screen
with the reason and prints it to the console. Players who connect then spawn as
spectators outside the map, get no menu and no force-download message; the
gametype itself keeps running.

Order: `fs_game` empty, `sv_plus` 122 or later
([ADR 0001](adr/0001-plus-server-only.md)), iwd lists readable, the mod's iwd
loaded under its exact name; then, only when `shortversion` is 1.3 or
`g_cod2x` is set (always on Plus): www download on, `zpam_maps_v6` present, the
fixed maps load; then no `zzz_zpam_custom` iwd and no blacklisted iwd.

## Server dependencies

| Dvar | From | Used for |
|---|---|---|
| `sv_plus` | OpenCoD2-Plus Server, Plus build only, read-only | the Plus check |
| `sv_referencedIwdNames`, `sv_iwdNames` | engine | iwd name and blacklist checks |
| `sv_fps` | engine | GSC `wait` follows it (OpenCoD2-Plus Server), so waits are real seconds and `level.fps_multiplier` is always 1 |
| `shortversion`, `g_cod2x` | engine, CoD2x | 1.3 checks (a Plus server reports 1.3) |
