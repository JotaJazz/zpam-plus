# Debt and gaps

| Item | State | Next step |
|---|---|---|
| No real match on the Plus server | the mod was tested only to the www check on a local Plus build | a match with Plus clients at 40 Hz |
| The upstream manual describes zPAM 3.38 | `docs/upstream/zpam-3.38.md` keeps its install steps, links and iwd names | write Plus versions of the parts that change |
| Admin can fake `sv_plus` on a non-Plus build | accepted in [ADR 0001](../architecture/adr/0001-plus-server-only.md) | none |
| Automatic ladder | not started | define what results leave the server and how |
| Help text points to the zPAM Discord channel | `ingame_aboutpam.menu` | replace when the family has its own channel |
| `pam_mode` like `pub_mr12` passes validation but no rules load (`assert(loaded)` in `global/rules.gsc`) | upstream bug, kept | refuse suffixes after `pub` in `IsValidPAMModeForGametype` |
| Machine paths in `tools/run-server.sh` defaults | personal defaults, overridable by variables | move them to a local, uncommitted file |
| No automated GSC test | manual, with `tools/rcon.py` on a `tools/run-server.sh` server | a scripted run that reads the console log |
