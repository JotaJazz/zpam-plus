# Building and testing

## Build

`tools/build-iwd.sh` packs `source/` into `<name>.iwd` at the repository root,
with the name read from `level.pam_folder`. `--out <path>` writes elsewhere.
Needs `zip`.

## Test server

`tools/run-server.sh [gametype] [map]` (default `sd mp_toujane_fix`) builds the
iwd into `.server/main/` and runs a LAN server with `fs_homepath` there, so the
game folder stays untouched.

| Variable | Default | Meaning |
|---|---|---|
| `COD2_GAME_DIR` | `/mnt/<drive>/Servers/COD2` | CoD2 folder with stock iwds only |
| `COD2_SERVER_BIN` | `~/CoD2rev_Server/bin/cod2rev_lnxded` | server binary; a Plus build is needed to pass the Plus check |
| `COD2_MAPS_IWD` | `/mnt/<drive>/Servers/COD2-MAPAS/zpam_maps_v6.iwd` | map pack; the script stops if it is missing |
| `COD2_PORT` | 28960 | UDP port |

The game folder must hold only stock iwds: a downloaded mod or map in `main`
changes what loads. The script sets no www download and takes no extra `+set`
arguments, so on a 1.3 or Plus binary the run always stops at the www check;
that error proves every check before it passed. Getting past it needs
`sv_wwwDownload 1` and `sv_wwwBaseURL` added to the script's command line.

## Checks

| What | Command |
|---|---|
| Docs | `python3 scripts/check_docs.py` |
| Docs checker tests | `python3 -m unittest discover -s scripts` |

GSC has no unit tests; a change is checked on a test server, reading the
console in `.server/main/console_mp_server.log`.

## Release a version

1. Raise the number in every line `grep -rn ZPAM_RENAME source` lists, the
   commented ones too: `level.pam_folder` and its error text, the version
   strings in `_pam.gsc`, `scr_motd`, `_zpam` in `source/default_mp.cfg`, both
   texts in `ui_mp/connect.menu`.
2. Add the previous iwd name to the blacklist in `global/pam.gsc` (the
   `ZPAM_RENAME - add old pam` line).
3. Update `source/readme.txt` (release date), `docs/CHANGES.md`, the iwd name in
   `README.md` and `docs/ai/SYSTEM_SUMMARY.md`.
