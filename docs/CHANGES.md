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
