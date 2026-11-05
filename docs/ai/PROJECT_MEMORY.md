# Project memory

Append-only. Newest first. Template in
[DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md#memory-entry).

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
