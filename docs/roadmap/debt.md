# Debt and gaps

| Item | State | Next step |
|---|---|---|
| No real match on the Plus server | the mod was tested only to the www check on a local Plus build | a match with Plus clients at 40 Hz |
| The upstream manual describes zPAM 3.38 | `docs/upstream/zpam-3.38.md` keeps its install steps, links and iwd names | write Plus versions of the parts that change |
| Admin can fake `sv_plus` on a non-Plus build | accepted in [ADR 0001](../architecture/adr/0001-plus-server-only.md) | none |
| Automatic ladder | not started | define what results leave the server and how |
| Help text points to the zPAM Discord channel | `ingame_aboutpam.menu` | replace when the family has its own channel |
| Machine paths in `tools/run-server.sh` defaults | personal defaults, overridable by variables | move them to a local, uncommitted file |
| No automated GSC test | manual, with `tools/rcon.py` on a `tools/run-server.sh` server | a scripted run that reads the console log |
| Player identity is IP plus name | restored stats match the IP and the name, not an account; players behind one IP (and all bots, 0.0.0.0) are told apart only by name | the ladder needs real accounts |
| Plus server segfaults loading `re` on `mp_toujane_fix` and `mp_burgundy` | found on the test server, present before `fix/plus-audit`; server side | a fix in OpenCoD2-Plus Server |
| Not tested in game (no real client) | killcam refusal, time-out and rate limits, different-IP refusal, `a;b` names, recording, plant and defuse, match limits | a session with real clients |
| Gametype copies left | `spawnIntermission` is identical in ctf, dm, htf and tdm; `onConnecting` is identical in 7 gametypes (only dm differs); tdm `playSoundOnPlayers` is identical to round_common's; no common file has the right includers for them | a new common file per set, or accept the copies |
| `level.fps_multiplier` kept for the map pack | `mp_leningrad_mjr` and `mp_leningrad_tls` in `zpam_maps_v6.iwd` still wait `level.fps_multiplier * n` | remove the variable from `global/cvars.gsc` when the map pack is rebuilt |
