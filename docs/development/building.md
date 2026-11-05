# Building and testing

## Build

`tools/build-iwd.sh` packs `source/` into `<name>.iwd` at the repository root,
with the name read from `level.pam_folder`. `--out <path>` writes elsewhere.
Needs `zip`.

## Test server

`tools/run-server.sh [gametype] [map] [+set ...]` (default `sd mp_toujane_fix`) builds the
iwd into `.server/main/` and runs a LAN server with `fs_homepath` there, so the
game folder stays untouched.

| Variable | Default | Meaning |
|---|---|---|
| `COD2_GAME_DIR` | `/mnt/<drive>/Servers/COD2` | CoD2 folder with stock iwds only |
| `COD2_SERVER_BIN` | `~/CoD2rev_Server/bin/cod2rev_lnxded` | server binary; a Plus build is needed to pass the Plus check |
| `COD2_MAPS_IWD` | `/mnt/<drive>/Servers/COD2-MAPAS/zpam_maps_v6.iwd` | map pack; the script stops if it is missing |
| `COD2_PORT` | 28960 | UDP port |

The game folder must hold only stock iwds: a downloaded mod or map in `main`
changes what loads. Everything after the map goes to the binary unchanged.

The standard way to test with a Plus binary, which passes the installation
check (it needs the www download set):

    COD2_PORT=28981 tools/run-server.sh sd mp_toujane_fix \
        +set sv_wwwDownload 1 +set sv_wwwBaseURL http://127.0.0.1/ +set sv_fps 40

A healthy start has no `zPAM Errors` in the console log. In another shell,
`COD2_PORT=28981 python3 tools/rcon.py <command...>` sends one rcon command
(password from `.server/rcon_password.txt`) and prints the reply; it exits 1
without reply after 2 s. Stop the server by its PID. The mod's rules reset some
cvars at map load (`sv_fps` reads back 30, not 40), so read a cvar back before
trusting a `+set`.

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
