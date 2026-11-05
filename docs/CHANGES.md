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
- Timers last real seconds at any `sv_fps`; at 40 Hz they lasted twice as long.
- Kill replays only open for players in the streamer team; before, anyone could
  open them from the console.
- Calling a time-out twice in time-based modes no longer stacks two countdowns.
  Time-out call/cancel (2 s), the team-change message (2 s) and scoreboard
  clicks (0.5 s) are rate-limited per player.
- `pam_mode` with a suffix after `pub` (such as `pub_mr12`) is refused as an invalid value; before, it crashed the map with a script error.
