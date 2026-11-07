# ADR 0003: What the game server does for an automatic ladder

Date: 2026-11-07. Status: accepted (phase A built).

## Context

The project's later goal is an automatic ladder: players find a match, play it
on one of our servers and get a result, with no admin by hand
([PROJECT_CONTEXT](../../ai/PROJECT_CONTEXT.md)). The mod already has the
pieces a match needs: `pam_mode` rules, ready-up with auto-resume, the score
set after a crash (`scr_score_allies`/`_axis`, `scr_score_change_mode`), the
`draw` sub-mode, kicks without an IP ban, and `Stats;` lines per player after
each sd and re round (`_player_stat::logStats`). The Plus server can also talk
to the network from script (`httpFetch`, WebSockets, JSON).

What does not exist: accounts. Today a player is his IP plus his name, which
two players behind one IP share and which anyone can type.

The maintainer asked for a design without questions first, and accepted it as
written.

## Decision

1. **The ladder is a separate service; the game server only plays matches.**
   Accounts, queues, ratings and maps live in a ladder service outside this
   repository. The mod knows nothing about ratings. It takes a match, enforces
   who plays, and reports what happened.
2. **The service drives the server by rcon and reads its log.** It runs on the
   same machine as the server, sets the match by rcon (`g_password`,
   `pam_mode`, the map, the roster below) and reads `games_mp.log`. The mod
   writes no network code for this, so it works today and is tested with
   `tools/test_server.py`. `httpFetch` from the mod (a pull model, as CoD2x's
   match system) stays possible later if servers have to run away from the
   service.
3. **A match is one map with a roster.** The service sets, before the map
   starts:
   - `scr_ladder_match` = an id it chooses (empty: no ladder match, the mod
     behaves as today);
   - `scr_ladder_team1` and `scr_ladder_team2` = the players of each team,
     separated by `;` (see 5 for what identifies them);
   - `scr_ladder_ready_timeout` = seconds to join and ready up.
   A best-of-three is three matches the service chains.
4. **The mod enforces the roster.** With a ladder match set, a connecting
   player who is not in the roster joins only as a spectator; a roster player
   is put in his team and cannot switch. The team names come from the service,
   not from `_teamname.gsc`.
5. **Identity, in two steps.** First the roster names the players by their
   in-game name, and the match is protected by a password the service gives
   only to the roster; a wrong name on the right password is refused. Then a
   real account: the Plus client sends a token the ladder service issued, the
   server checks it with the service, and the roster lists account ids. That
   step needs OpenCoD2-Plus and OpenCoD2-Plus Server work and its own ADR.
6. **No-shows and leavers.** If a team is not complete and ready when
   `scr_ladder_ready_timeout` runs out in the first ready-up, the mod ends the
   match as a forfeit by the incomplete team. A roster player who leaves for
   longer than the ready-up auto-resume during the match is logged as a leaver;
   the service decides what that costs.
7. **What the mod reports.** In `games_mp.log`, besides the `Stats;` lines:
   `LadderStart;<match id>;<map>;<pam_mode>` when the first ready-up ends,
   `LadderEnd;<match id>;<score team1>;<score team2>;<winner|draw>` at the end
   of the map, `LadderForfeit;<match id>;<team>` and
   `LadderLeaver;<match id>;<player>;<seconds away>`. Fields go through
   `logSafe`. The service treats a map that ends without `LadderEnd` (crash,
   restart) as not played, and replays it with the score set by rcon.

## Consequences

- Phases, each usable on its own: (A) the report lines of 7 and the `scr_ladder_*`
  cvars with an empty default; (B) the roster of 3 and 4 with names and
  password; (C) the forfeit and leaver of 6; (D) the account token of 5, which
  needs the client and server repositories; (E) the ladder service, a new
  repository.
- `Stats;` stays as it is; the service reads the last one of each player.
- Out of scope for the mod: ratings, queues, map picks, anti-cheat, web pages.
- Risk until (D): names can be copied, so a ladder before (D) is only as safe
  as its match passwords.
- Respawn gametypes have no `Stats;` lines yet; a ladder starts with sd.
