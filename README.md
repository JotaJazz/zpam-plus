# zPAM Plus

Competition mod for Call of Duty 2 and the mod of the OpenCoD2-Plus family:
zPAM 3.38 rules and match flow, with the fixes of zPAM 4.x (to 4.11) that work
on the Plus server, for our servers, public servers and, later, an automatic
ladder. Competitive rules run at 40 Hz and use the Plus engine's rules for fast
reload, prone peek, MG clip and a fixed shotgun pellet pattern.

| Needs | |
|---|---|
| Server | OpenCoD2-Plus Server built with `make PLUS=1` (Plus version 123 or later) |
| Players | the OpenCoD2-Plus client ("1.3 Plus") |

On any other server the mod shows "zPAM is not installed correctly" and does
not start a match. Stock 1.0, 1.3 and CoD2x servers keep using
[zPAM 3.38](https://github.com/eyza-cod2/zpam3).

## Install

Put in the server's `main` folder:

- `zpamplus1.iwd` (the name must not change)
- `zpam_maps_v6.iwd`, the fixed maps

Then set `fs_game ""` (the mod runs from `main`), `sv_wwwDownload 1` and
`sv_wwwBaseURL` to a folder that serves the maps.

## Documentation

- [docs/README.md](docs/README.md): index for players, admins and contributors.
- [docs/upstream/zpam-3.38.md](docs/upstream/zpam-3.38.md): the zPAM 3.38
  manual, with every feature, setting and error message.
- [docs/CHANGES.md](docs/CHANGES.md): changes since zPAM 3.38.

zPAM was created by eyza and Fjozek; zPAM Plus is a fork of
[eyza-cod2/zpam3](https://github.com/eyza-cod2/zpam3).
