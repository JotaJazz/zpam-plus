# Changes

Changes since zPAM 3.38. Earlier history:
[upstream/zpam-3.38.md](upstream/zpam-3.38.md#changelog).

## zPAM Plus 1 (unreleased)

- Renamed to zPAM Plus; the iwd is `zpamplus1.iwd` and serverinfo `_zpam` is
  `Plus 1`.
- Runs only on OpenCoD2-Plus Server built with `make PLUS=1`: anywhere else it
  shows the installation error with the reason.
- `zpam338.iwd` in `main` is refused, as older zPAM iwds already were.
- Help links point to JotaJazz/zpam-plus.
- A `;` in a player name is written as `:` in `games_mp.log`, so a name cannot add
  fields to a log line.
- Timers last real seconds at any `sv_fps`; at 40 Hz they lasted twice as long.
- Comp, strat and dm warmup rules run at 40 Hz: `sv_fps 40`, `g_forceSnaps 40`,
  `g_forceRate 40000` and `sv_maxRate 0` (was `sv_fps 30` and `sv_maxRate 25000`).
- Kill replays only open for players in the streamer team; before, anyone could
  open them from the console.
- Calling a time-out twice in time-based modes no longer stacks two countdowns.
  Time-out call/cancel (2 s), the team-change message (2 s) and scoreboard
  clicks (0.5 s) are rate-limited per player.
- `pam_mode` with a suffix after `pub` (such as `pub_mr12`) is refused as an
  invalid value; before, it crashed the map with a script error.
- Reconnecting restores stats only from the same IP; before, any player with
  the same name got them. Renaming to the name of a disconnected player no
  longer deletes that player's stats: the renamed player keeps his own under the
  old name.
- `hq` no longer stops the server with a script error when the match starts.
- The hand-hitbox and shotgun fixes take the attacker's eye height from his
  stance again; on the Plus server it was always the standing height.
