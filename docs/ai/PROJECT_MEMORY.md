# Project memory

Append-only. Newest first. Template in
[DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md#memory-entry).

## 2026-11-13 — MG and neck duels

- `dev_duel` takes `mg` (the shooter mounts a map turret, `misc_turret` or `misc_mg42`; `mp_toujane` has only the latter) and `neck`; checked on `mp_toujane_fix`: MG 100 head and neck, 75 torso; a neck hit is `neck` and 90 with an M1 Garand with `scr_hitbox_neck_kill 0`, a head kill with 1.
- The MG barrel is about 50 units ahead of the eye, so the duel aims from the turret pivot at eye height; aimed from the eye the bullets missed. The `J_Neck` tag lies in the head box; 2 units lower is the neck.
- The server repo moved to `~/OpenCoD2-Plus-Server`, now the default of `tools/run-server.sh`; its `bin/` held a 1.0 build until rebuilt with `make PLUS=1`. On that build (`64f12d2`) `re` runs on `mp_toujane_fix` and `mp_burgundy_fix` with bots: the segfault is gone from the debt table.

## 2026-11-07 — ladder phase C

- The first ready-up of a ladder match waits for both rosters (`_ladder::rosterReady` in `areAllPlayersReady`); a missing team after `scr_ladder_ready_timeout` gives `LadderForfeit;`; a roster player away longer than the halftime auto-resume gives `LadderLeaver;` (system time, so map restarts do not reset it). Checked: forfeit, a full roster that starts, and a leaver at map end.
- A player joining a team from "none" keeps the default ready and triggers no ready-up check, so with a roster the ready-up hung; `_ladder` re-runs `Check_All_Ready` on every team join in the first ready-up. Whether that default ready lets a fresh human skip the ready press in normal matches is not checked.
- Test runs: `--rcon "sleep N"`; a `map_restart` reapplies the rules, and bots added during it lose their team.

## 2026-11-07 — ladder phase B

- The roster in `scr_ladder_team1/2` is enforced in `_menus.gsc`'s team menu: a listed player joins his team only, anyone else watches; `scr_ladder_team1_name/_team2_name` (an addition to ADR 0003's point 4) replace the generated names. Checked with three bots and match info.
- `games_mp.log` is buffered unless `g_logSync 1`: a test or a ladder service reading it sees lines late; `tools/test_server.py` now sets it, and the log contract says so.
- Open: phase C (forfeit on no-show, leavers); in rcon a roster with `;` must be quoted.

## 2026-11-07 — ladder design and phase A

- ADR 0003 accepted: a separate ladder service drives the server by rcon and reads `games_mp.log`; phase A logs `LadderStart;` and `LadderEnd;` (team1 = the team on allies at the start, kept across halftime), checked by a two-bot comp match with a halftime that ends `LadderEnd;m1;0;2;team2`. ADR 0002 now holds the Plus 123 decision that had been written into the accepted ADR 0001.
- `tools/run-server.sh` reads machine paths from `.server/env`; `docs/manual-plus.md` says what of the 3.38 manual differs; test runs get `--rcon`, `--log` and `dev_bots_autoready`.
- Bots are frozen by default (`scr_bots_freeze 1`): a duel or a match with bots needs it at 0. Open: phase B, the roster.

## 2026-11-07 — bots that shoot, play test guide

- `dev_duel` and `tools/test_server.py --duel` make one bot shoot another: kar98k head and torso kill, thompson torso does 35, the fixed-pattern shotgun kills at 200 and does 16 at 650, and `Stats;` then shows the kills, the headshot and the damage dealt; `docs/development/playtest.md` lists 22 checks for a session with real players.
- Bots fire their `ps->weapon`, so a duel switches with `setSpawnWeapon` (not `switchToWeapon`) and fills the clip; sd restarts the map when both teams first have players, so a duel waits for a live round.
- Open: duels for the MG and neck hits, and the play test itself.

## 2026-11-07 — server check, CPU, shared intermission, round stats

- `tools/test_server.py` checks a server run in one command (Plus build, `sv_plus`, cvars, no zPAM or script errors); `spawnIntermission` is shared by ctf, dm, htf and tdm; sd and re keep upstream's extended round stats and log a `Stats;` line per player after each round.
- Measured instead of optimizing: with 12 moving bots the whole server uses 4.0% of a core in comp at 40 Hz and 1.9% in pub at 20 Hz (0.7% empty), so the per-frame script loops were left as they are.
- Open: the round stats are checked with bots that do not shoot, so kills, trades, clutches and aces are untested.

## 2026-11-07 — strat waits were a non-Plus build

- The "strat waits last half" entry was wrong: both failing runs used a 1.0 build without `COD2_PLUS` (the server was being rebuilt), where `wait` counts 20 frames a second; the mod refused it with the Plus error just before the assert. On the Plus build strat waits measure 1000 ms each (six in a row).
- When a self-test fails on the test server, check the console for the zPAM installation error and the build line first.

## 2026-11-07 — Plus 123 required, fixed shotgun spread

- The mod requires `sv_plus` 123 (ADR 0001 update): the fast reload, prone peek and MG clip scripts and their cvars are removed, as the engine applies those rules on both sides. `scr_score_change_mode` lets `_lan` change the score at any time.
- The comp rules turn on the server's `g_shotgun_spread_fix` (from `ae124d3`, `sv_plus` unchanged), registered by the mod only if the engine has it, and the shotgun uses upstream's ranges for the fixed pattern.
- Kept: the climbing sound script, because the mod's `weap_raise` is `null.wav` and its script also voices normal weapon raises; dropping it needs a real client to check.

## 2026-11-07 — upstream 4.x review, block 3, and Plus 123

- In: hit feedback merged per frame (kill and hit crosses, a second cross for multi-hits), dm player stats, faster ready-up respawn, sd compass and clock timing, strat bombsite icons, steady clock and hit details, map vote names from match info, debug damage printed after the fixes. The server already had Plus 123 (fast reload, prone peek, MG clip in the engine), so `engineHasPlusRules()` skips those script fixes; the climbing sound fix stays, as zPAM silences `weap_raise`.
- Not taken: the per-player bomb timer, the bash text, `sv_cracked`/`scr_posters` (upstream undid them), the streamer ready-up check (undone upstream), the hit-indicator toggle.
- Open: the LAN options, the shotgun spread (engine handoff), and strat waits lasting half (debt).

## 2026-11-07 — upstream 4.x review, block 2

- Rule changes from upstream: MG use from `isUsingTurret` (player moved once when he leaves), fixed MG damage (100/75/35; the server took the multipliers of the weapon held before mounting), `scr_hitbox_neck_kill` on in comp, a bigger hand-fix head box, the `draw` sub-mode and the engine's `getViewOrigin` for the eye (60 standing, 40 crouched on a bot).
- Changed from upstream: `draw` loads after all rules (upstream loads it in place, so `comp_draw_mr12` kept overtime), and `isUsingTurret` is only called on players (libcod errors on other entities).
- Open: the shotgun ranges wait for a fixed pellet spread in the engine, which goes in the engine handoff with fast reload, prone peek and the climbing sound.

## 2026-11-07 — upstream 4.x review, block 1

- The 105 upstream commits after our 3.36 base (zPAM 4.00 to 4.11, mostly for CoD2x) were triaged; six fixes went in: `getStance` called by path (the bare call reached libcod's and every eye was at standing height), `[{x}]` names renamed, saved weapons checked against the selection at spawn, `sv_kickBanTime 0` in comp, scoped Kar98k/buffed BAR/FG42 in hit stats, stats kept through a match and taken over from a stale 999 slot.
- Rejected: the `va()` length cap in `setClientCvar2` (the Plus server truncates instead of failing), and upstream d6add7f's removal of the weapon-change rule (a weapon chosen mid-round was ignored).
- Open: rule changes (MG with `isUsingTurret`, MG damage, neck kill, hand box, shotgun ranges, `draw` mode, `getvieworigin`), the quality-of-life set and the ladder stats (#20, #25); see [debt](../roadmap/debt.md).

## 2026-11-06 — the desync was WSL

- The movement desync of the first Plus match came from WSL2, whose clock ran about 8% faster than Windows; not the mod, the server or the client.
- For timing or movement tests with a Windows client, run the server where its clock matches the client's (not WSL2), or check the WSL clock first.

## 2026-11-06 — first match with a Plus client

- sd `comp` on `mp_toujane_fix` at 40 Hz on a local `make PLUS=1` build, one Plus client (32 and 64-bit) and bots: www download of both iwds, readyup, rounds and the halftime side swap played with no script error; clients got `rate 40000`.
- `sv_wwwBaseURL` cannot be set with `+set` or rcon: `//` starts a comment and the URL stops at `http:`; set it from an exec'd cfg. Bots stand still with the weapon down because `scr_bots_freeze` defaults to 1.
- Open: movement desync between client and server, seen in that match; it belongs to the server and client repos.

## 2026-11-06 — hq radio index

- `hq_obj_think` read `level.radio[-1]` on its first pass and the script error shut the server down; the index is now guarded (reproduced and checked with 6 bots on `mp_toujane_fix`, pub, on a local `make PLUS=1` build).
- Rejected: dropping `snaps 30` and `rate 25000` from `_cvar_forces.gsc`; the Plus client defaults to `snaps 20` and `rate 5000`, and pub does not set `g_forceSnaps` or `g_forceRate`.
- Kept: the other cvars PunkBuster used to force; they keep every client on the same values.

## 2026-11-05 — optimizations

- `level.fps_multiplier` is gone from the mod's own waits (plain seconds) but stays 1 in `global/cvars.gsc` for `mp_leningrad_mjr` and `mp_leningrad_tls` in `zpam_maps_v6.iwd`; the dm/tdm common file is `global/gametype_dm_tdm_common.gsc`; the sd and re menu handlers moved to `global/gametype_round_common.gsc`; `tools/rcon.py` reads multi-packet replies and says so when the password file is missing.
- Team-name generation uses keyed lookups with identical output: 10 names of 32 characters went from 36-47 ms to 5-6 ms, pinned by `teamnameSelfTest` in `developer_script 1`.
- Left on purpose: `spawnIntermission` is identical in ctf, dm, htf and tdm but no common file has exactly those includers; `onConnecting` and the tdm `playSoundOnPlayers` stay per gametype (see [debt](../roadmap/debt.md)).

## 2026-11-05 — rules at 40 Hz

- Comp, strat and dm warmup rules set `sv_fps 40`, `g_forceSnaps 40`, `g_forceRate 40000` and `sv_maxRate 0`, the 40 Hz setting of the Plus protocol; the two Plus dvars are registered in `global/cvars.gsc`.
- `_cvar_forces.gsc` forced `sv_maxRate 25000` on every map, after the rules, which would have capped the 40 Hz rate; the rules now own it.
- Checked on a local Plus build by rcon (values set, kept across `map_restart`); pub keeps the server config's values, as before.

## 2026-11-05 — audit fixes

- Waits are real seconds at any tick rate (`level.fps_multiplier` is 1); kill replays only for streamers; one time-out per call and per-player rate limits; `pub` refuses suffixes; restored stats need the same name and IP; names go through `logSafe` in `games_mp.log` and team names are computed once per match start.
- About 2,600 lines of dead code removed and identical gametype functions moved to `global/gametype_*_common.gsc` (about 1,800 lines); `tools/` gained `rcon.py` and extra `+set` arguments for the test server.
- Open: comp, strat and warmup rules still force `sv_fps` 30 (the maintainer decides 30 or 40); not tested in game, see [debt](../roadmap/debt.md); the Plus server crashes loading `re` on two maps and `hq` fails at match start.

## 2026-11-05 — documentation system

- The 1,468-line zPAM 3.38 README moved unchanged to `docs/upstream/zpam-3.38.md` (image links fixed); a short Plus README, `docs/CHANGES.md`, architecture, development, debt, glossary and the full AI layer replace it.
- `scripts/check_docs.py` and its tests come from OpenCoD2-Plus Server, skipping `docs/upstream` and `.server`.
- Rejected: rewriting the upstream manual now; its Plus parts are debt.

## 2026-11-05 — renamed zPAM Plus, versions from 1

- Shown as "zPAM Plus 1", iwd `zpamplus1.iwd`, serverinfo `_zpam` = `Plus 1`, help links to JotaJazz/zpam-plus; `zpam338` joins the blacklist so both cannot load together.
- Rejected: `zpamplus10` for 1.0, which reads like 10; versions are whole numbers.

## 2026-11-05 — zPAM Plus joins the OpenCoD2-Plus family

- Agent rules and memory layer added on top of zPAM 3.38 (audit fixes `8ba7504`..`dad08c5`); Plus server only ([ADR 0001](../architecture/adr/0001-plus-server-only.md)).
- `CheckInstallation` requires `sv_plus` 122 or later (server `f5697e8`): stock 1.0 shows the Plus error, a local `make PLUS=1` build passes it and stops at the www check.
- Accepted: an admin can fake `sv_plus` on a non-Plus build; only they are fooled.
