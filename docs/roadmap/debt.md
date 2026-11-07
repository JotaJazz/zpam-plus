# Debt and gaps

| Item | State | Next step |
|---|---|---|
| One real match on the Plus server | 2026-11-06: one Plus client and bots, sd comp at 40 Hz on `mp_toujane_fix`, www download, readyup, rounds and halftime side swap, no script error | a match with several Plus clients |
| Admin can fake `sv_plus` on a non-Plus build | accepted in [ADR 0001](../architecture/adr/0001-plus-server-only.md) | none |
| Automatic ladder | designed, not built: [ADR 0003](../architecture/adr/0003-ladder-server-side.md) (proposed) | the maintainer accepts or changes ADR 0003, then phase A |
| Help text points to the zPAM Discord channel | `ingame_aboutpam.menu` | replace when the family has its own channel |
| No automated GSC test | `tools/test_server.py` checks a server run, and `--duel` checks damage, kills and the stats hooks with two bots; rounds with more players, the MG, neck hits, menus and HUD are still checked by hand | duels for the MG (needs a turret) and neck hits (needs an aim at the neck tag) |
| Player identity is IP plus name | restored stats match the IP and the name, not an account; players behind one IP (and all bots, 0.0.0.0) are told apart only by name | the ladder needs real accounts |
| Plus server segfaults loading `re` on `mp_toujane_fix` and `mp_burgundy` | found on the test server, present before `fix/plus-audit`; server side | a fix in OpenCoD2-Plus Server |
| Not tested in game (no real client) | killcam refusal, time-out and rate limits, different-IP refusal, `a;b` and `[{x}]` names, a weapon change in a time-out, a reconnect over a 999 slot, prone eye height, MG damage, neck hits, the feel of the fixed-pattern shotgun (its damage per range is checked by duels), hit indicators, Plus 123 rules with the mod, silent climbing with the weapon down, recording, plant and defuse, match limits | a session with real clients, following [playtest.md](../development/playtest.md) |
| Gametype copies left | `onConnecting` is identical in 7 gametypes (dm also sets the spectator team); `playSoundOnPlayers` is in tdm, hq, round_common and (with a streamer sound) flag_common, and a shared copy would clash in ctf and htf | accept them: a few lines each |
| `level.fps_multiplier` kept for the map pack | `mp_leningrad_mjr` and `mp_leningrad_tls` in `zpam_maps_v6.iwd` still wait `level.fps_multiplier * n` | remove the variable from `global/cvars.gsc` when the map pack is rebuilt |
| Upstream 4.x left to decide | reviewed on 2026-11-07; blocks 1 and 2 are in. Left: lan auto-resume (not taken); the match stats (#20, #25) are in for sd and re | none |
