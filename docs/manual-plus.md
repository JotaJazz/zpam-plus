# The zPAM 3.38 manual on zPAM Plus

[upstream/zpam-3.38.md](upstream/zpam-3.38.md) is kept as eyza wrote it. Its
settings, features and questions still hold for zPAM Plus, except the parts
below; every other change is in [CHANGES.md](CHANGES.md).

## Download and installation

- There is no release yet: build `zpamplus1.iwd` from this repository with
  `tools/build-iwd.sh` ([development/building.md](development/building.md)).
- The server is OpenCoD2-Plus Server built with `make PLUS=1`, Plus version
  123 or later; players need the OpenCoD2-Plus client. Stock 1.0 and 1.3,
  CoD2x and other builds keep zPAM 3.38.
- In `main`: `zpamplus1.iwd` (the name must not change), `zpam_maps_v6.iwd` and
  `server.cfg`. Run with `fs_game ""`, as in 3.38.
- WWW download is required: `sv_wwwDownload 1` and `sv_wwwBaseURL` pointing at
  a folder that serves `zpamplus1.iwd` and the map pack. The manual's
  `http://cod2x.me/zpam` does not serve `zpamplus1.iwd`. Set the URL in a cfg:
  on the command line `//` starts a comment and cuts it.
- PunkBuster does not exist on the Plus server: drop `+set sv_punkbuster 0` and
  `+pb_sv_disable` from the manual's example command line. A Plus server needs
  only `+set dedicated 2 +exec server.cfg`.

## Contact

Report problems in the [issues](https://github.com/JotaJazz/zpam-plus/issues).
The manual's Discord channel and e-mail are eyza's, for zPAM 3.38.

## Questions and answers

| Manual section | On zPAM Plus |
|---|---|
| Fast reload ("Clip"), prone peek, MG clip | Done by the Plus 123 engine on the server and in the client's prediction; `scr_fast_reload_fix`, `scr_prone_peek_fix`, `scr_mg_peek_fix` and their debug cvars are gone |
| Consistent shotgun | With the server's fixed pellet pattern (`g_shotgun_spread_fix 1`, on in comp) the ranges are 0-280 a kill, 280-400 75, 400-500 35, 500-800 as before; without it, the manual's ranges |
| Hand hitbox fix | The head box is a little bigger (right 11, down 16; moving 13 left, 15 right) |
| (new) Neck kill | `scr_hitbox_neck_kill`, on in comp: a bullet in the neck counts as a head hit |
| (new) MG damage | 100 head and neck, 75 torso and upper legs, 35 elsewhere, whatever weapon the player held |
| Scoreboard menu, round report | Unchanged; sd and re also log extended stats (`Stats;` lines in `games_mp.log`) |
| Streamer, auto-spectator, XRAY | Unchanged; kill replays open only for the streamer team |

## Troubleshooting

| Message | On zPAM Plus |
|---|---|
| zPAM Plus runs only on OpenCoD2-Plus Server built with PLUS=1. | New. The console prints `sv_plus` and the version needed: run a Plus build, 123 or later |
| Iwd file zpamplus1.iwd must be installed in main folder. | The manual's `zpam334.iwd`: the name is `zpamplus1.iwd` |
| Old zPAM or maps detected in main folder | Also refuses `zpam338.iwd`: zPAM 3.38 and zPAM Plus cannot load together |
| WWW downloading must be enabled | As in the manual, with your own `sv_wwwBaseURL` (see above) |
| Can't create Dvar: 1280 dvars already exist | The Plus client holds 4096 dvars, so a big config no longer hits it |
| fs_game, iwd names with spaces, map pack missing, Info string length, Impure client | As in the manual |
