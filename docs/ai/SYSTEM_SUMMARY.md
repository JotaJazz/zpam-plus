# System summary

Updated 2026-11-07. Version: zPAM Plus 1, unreleased.

## Tree

```
source/                     the iwd content
├── maps/mp/gametypes/      gametypes, global/ framework, _*.gsc modules, rules/
├── maps/mp/                map scripts
├── ui_mp/                  menus
└── default_mp.cfg          serverinfo _zpam
tools/                      build-iwd.sh, run-server.sh, rcon.py
scripts/                    check_docs.py and its tests
docs/upstream/              zPAM 3.38 manual, kept as written
images/                     pictures used by the upstream manual
```

## State

| Area | State |
|---|---|
| Rules and match flow | zPAM 3.38 with the audit fixes up to `dad08c5`, the `fix/plus-audit` branch and the zPAM 4.x fixes that work on Plus (see debt for what is untested) |
| Upstream | eyza-cod2/zpam3 reviewed to zPAM 4.11 (`c05f226`), recorded by an `ours` merge (`38d13ae`); what was left out is in debt and project memory. New upstream commits: fetch it, then `git log master..<upstream>/master` |
| Plus check | built, `sv_plus` 123 or later; tested on stock 1.0 and a non-Plus 1.0 build of the server (refused) and a local Plus build (passes) |
| Name and version | "zPAM Plus 1", `zpamplus1.iwd`, `_zpam` = `Plus 1` |
| Real match on Plus | one, on 2026-11-06: one Plus client and bots, sd comp at 40 Hz; none yet with the 4.x fixes |
| Automatic ladder | not started |

## Commands

| Task | Command |
|---|---|
| Build | `tools/build-iwd.sh` |
| Test server | `tools/run-server.sh [gametype] [map] [+set ...]`; `python3 tools/rcon.py <command>` |
| Server check | `python3 tools/test_server.py [--gametype] [--pam-mode] [--expect cvar=value]` |
| Docs | `python3 scripts/check_docs.py` |
| Checker tests | `python3 -m unittest discover -s scripts` |

## Contracts

| With | Contract |
|---|---|
| OpenCoD2-Plus Server | `sv_plus` read-only, Plus build only, value `PLUS_VERSION` (123); the engine applies the fast reload, prone peek and MG clip rules; `g_shotgun_spread_fix` (from `ae124d3`, same `sv_plus`) is used only if the engine registered it |
| Server admins | iwd name `zpamplus1`, run from `main`, www download on, `zpam_maps_v6.iwd` |
| Log readers (ladder) | `games_mp.log`: after each sd and re round, `Stats;<name>;<team>;key=value;...` per player with match totals (`_player_stat::logStats`); with `scr_ladder_match` set, `LadderStart;<id>;<map>;<pam_mode>` when the first ready-up ends and `LadderEnd;<id>;<score team1>;<score team2>;<team1\|team2\|draw>` at map end, team1 being the team on allies at the start ([ADR 0003](../architecture/adr/0003-ladder-server-side.md)); fields through `logSafe`; run the server with `g_logSync 1`, or lines reach the file late |
| Ladder service (rcon) | `scr_ladder_match` turns a match on; `scr_ladder_team1` / `scr_ladder_team2` list players by name, `;`-separated and quoted in rcon (`set scr_ladder_team1 "a;b"`), colours, case and end spaces ignored; a listed player joins only his team, anyone else only spectator or streamer; `scr_ladder_team1_name` / `_team2_name` replace the generated team names |
