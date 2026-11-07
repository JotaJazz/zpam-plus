# ADR 0002: Require Plus 123 and leave three fixes to its engine

Date: 2026-11-07. Status: accepted. Supersedes the `sv_plus >= 122` check of
[ADR 0001](0001-plus-server-only.md); the rest of ADR 0001 stands.

## Context

OpenCoD2-Plus Server 123 moved the fast reload, prone peek and MG clip rules
into the shared bgame and game code, applied by the server and predicted by the
client. The mod's script versions of them (a client dvar delay, a `linkto`, a
`setOrigin`) fight that prediction and would add a second fix on a 123 server.
No Plus 122 server is in use.

## Decision

`CheckInstallation` requires `getCvarInt("sv_plus") >= 123`. `_fast_reload.gsc`,
`_prone_peek_fix.gsc` and `_mg_fix.gsc`, with their cvars, rules, server-info
lines and rcon settings rows, are removed. The climbing sound fix stays: the
mod maps `weap_raise` to `null.wav` and plays its own sound on every weapon
raise, so dropping it would change normal switches too.

## Consequences

- A Plus 122 server shows the Plus error, as a non-Plus build does.
- Those three behaviours are now OpenCoD2-Plus Server's to fix or tune.
- The climbing sound can move to the client only together with restoring
  `weap_raise`, checked with a real client.
