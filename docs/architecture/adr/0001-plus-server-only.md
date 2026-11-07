# ADR 0001: zPAM Plus runs only on the Plus server

Date: 2026-11-05. Status: accepted, built.

## Context

zPAM Plus can rely on what the Plus build gives (40 Hz tick, Plus snapshots,
every player on the same client). Stock servers keep zPAM 3.38.

## Decision

The mod starts only on OpenCoD2-Plus Server built with `make PLUS=1`. On any
other server it stays in a safe state and prints why, in the console and on
screen.

## The signal

A script could not tell the Plus build apart: `sv_plusNotice`, `g_forceRate`
and `g_forceSnaps` exist only there, but `getCvar` returns `""` or `0` for both
a missing and an unset dvar. OpenCoD2-Plus Server `f5697e8` (on `dev`) registers
`sv_plus`, read-only (`DVAR_ROM`, range 122-122), only under `#ifdef COD2_PLUS`
and not in serverinfo. `CheckInstallation` in
`source/maps/mp/gametypes/global/pam.gsc` requires `getCvarInt("sv_plus") >= 122`
and otherwise calls `setError`: black screen, menus blocked, reason in the
console.

## Consequences

- Clients cannot set `sv_plus`, so the anti-goal on trust holds. An admin who
  starts a non-Plus build with `+set sv_plus 122` creates a plain dvar and passes
  the check; accepted, because only the person running the server can do it
  and it fools nobody but them.
- Raising the Plus version does not break the mod while the check is `>=`.

## Update 2026-11-07: Plus 123

Plus 123 moved the fast reload, prone peek and MG clip rules into the shared
engine code, applied by the server and predicted by the client. The check is
now `>= 123`, and the mod's script fixes for them (`_fast_reload.gsc`,
`_prone_peek_fix.gsc`, `_mg_fix.gsc`) are gone. The climbing sound fix stays:
the mod silences `weap_raise` and plays its own sound for every weapon raise.
