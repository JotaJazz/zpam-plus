# ADR 0004: The ladder roster names players by Plus ID

Date: 2026-11-13. Status: accepted. Supersedes the second step of point 5 of
[ADR 0003](0003-ladder-server-side.md) (a token the ladder service issues); the
rest of ADR 0003 stands.

## Context

ADR 0003 left real accounts for phase D: the Plus client would send a token
the ladder service issued, the server would check it with the service, and the
roster would list account ids. That needed work in the client and the server.

OpenCoD2-Plus Server already has the Plus ID (its ADR 0019, `plus-id.md`): the
Plus client keeps an ECDSA P-256 key pair and signs every connect with the
server's challenge and address; the server verifies it and gives the player an
ID, `P-XXXX-XXXX-XXXX-XXXX`, that no one else can take. Scripts read it with
`self getPlusId()` (`""` without a verified ID, and for bots).

## Decision

1. A roster entry that starts with `P-` (case ignored) is a Plus ID: it matches
   only the player whose `getPlusId()` equals it, whatever his name. Any other
   entry is a name, as in phase B. One roster may mix both.
2. The ladder service links each account to a Plus ID (for example, the player
   connects once to a link server and the service reads `plusIdStatus` by
   rcon) and writes the IDs in the roster. No token, no new server or client
   code.
3. `LadderLeaver;` names the player by his Plus ID when the roster names him by
   it, else by his name key, so the service gets back what it wrote.
4. A ladder server sets `sv_publicAddress` (without it only LAN players get an
   ID) and may set `sv_requirePlusId 1`. The mod does not force either: they
   are the operator's, and a roster by name still works without them.

## Consequences

- Phase D needs nothing from the client and server repositories; it is in the
  mod and checked by `_ladder::ladderSelfTest` and by bots, which have no ID.
  A Plus client that joins by its ID is checked in a play test.
- A player whose name is literally `P-...` cannot match a name entry: a name
  that starts with `P-` is read as an ID.
- A Plus ID is a key on one install: a player who loses the key gets a new ID,
  and the service links it again. A stolen key is the service's problem, as a
  stolen password would be.
- Phase E (the service) is the only ladder work left.
