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
| `COD2_GAME_DIR` | none, required | CoD2 folder with stock iwds only |
| `COD2_SERVER_BIN` | `~/CoD2rev_Server/bin/cod2rev_lnxded` | server binary; a Plus build is needed to pass the Plus check |
| `COD2_MAPS_IWD` | none, required | map pack; the script stops if it is missing |
| `COD2_PORT` | 28960 | UDP port |

Put your machine's paths in `.server/env`, one `NAME=value` per line, once:

    COD2_GAME_DIR=/path/to/CoD2
    COD2_MAPS_IWD=/path/to/zpam_maps_v6.iwd

git ignores `.server/`; a variable set in the shell wins over the file.

The game folder must hold only stock iwds: a downloaded mod or map in `main`
changes what loads. Everything after the map goes to the binary unchanged.

The standard way to test with a Plus binary, which passes the installation
check (it needs the www download set):

    COD2_PORT=28981 tools/run-server.sh sd mp_toujane_fix \
        +set sv_wwwDownload 1 +set sv_wwwBaseURL http://127.0.0.1/ +set sv_fps 40

A healthy start has no `zPAM Errors` in the console log. In another shell,
`COD2_PORT=28981 python3 tools/rcon.py <command...>` sends one rcon command
(password from `.server/rcon_password.txt`) and prints the reply; it collects extra
reply packets for 0.3 s, exits 1 without reply after 2 s, and prints "start
tools/run-server.sh first" if the password file is missing. Stop the server by its PID. The mod's rules reset some
cvars at map load (comp sets `sv_fps` 40 whatever `+set` said), so read a cvar
back before trusting a `+set`.

`python3 tools/test_server.py` does a whole check in one run: it starts the
server on a free port (28990 by default), waits for the map, checks that the
build is 1.3 Plus with `sv_plus` 123 or later, adds bots, waits, reads back each
`--expect cvar=value`, stops the server and fails on any zPAM installation
error, script error, failed self-test or busy port in the console (kept in
`.server/test_server.log`). `--gametype`, `--map`, `--pam-mode`, `--bots`,
`--seconds` and `-- +set ...` choose the run; `python3 tools/test_server.py --help`
lists them.

`--duel weapon,distance,head|torso[,expect]` makes one bot shoot another once
(`dev_duel` in `global/developer.gsc`, `developer_script 1` only): it finds a
clear line, places the target, aims, fires, and checks `kill`, a damage or a
range `lo-hi`. Duels need a live round, and the damage fixes need their cvars:

    python3 tools/test_server.py --pam-mode pub --bots 2 --seconds 5 \
        --duel kar98k_mp,600,head,kill --duel kar98k_mp,600,torso,kill \
        --duel thompson_mp,500,torso,35 --duel shotgun_mp,200,torso,kill \
        --duel shotgun_mp,650,torso,15-17 -- +set scr_sd_strat_time 0 \
        +set scr_bots_freeze 0 +set scr_shotgun_consistent 1 +set g_shotgun_spread_fix 1

The `Stats;` lines in `.server/main/games_mp.log` then hold the kills, headshots
and damage of those shots.

`--rcon "<command>"` runs commands once the map loads, and `--log <regex>`
waits up to 30 s for a matching line in this run's `games_mp.log`.
`dev_bots_autoready 1` makes bots ready up, so a whole ladder match plays with
two bots, a halftime after round one and two rounds:

    python3 tools/test_server.py --pam-mode comp --bots 2 --seconds 5 \
        --rcon "set dev_bots_autoready 1" --rcon "set scr_bots_freeze 0" \
        --rcon "set scr_ladder_match m1" --rcon "set scr_sd_half_round 1" \
        --rcon "set scr_sd_end_round 2" \
        --duel kar98k_mp,600,head,kill --duel kar98k_mp,600,head,kill \
        --log 'LadderStart;m1;mp_toujane_fix;comp$' --log 'LadderEnd;m1;\d+;\d+;(team1|team2|draw)$'

Bots are frozen by default (`scr_bots_freeze 1`): a duel needs them free.

## Checks

| What | Command |
|---|---|
| Docs | `python3 scripts/check_docs.py` |
| Docs checker tests | `python3 -m unittest discover -s scripts` |
| Server run | `python3 tools/test_server.py [--expect cvar=value ...]` |
| Its parser tests and the `.str` check's | `python3 -m unittest discover -s tools` |

GSC has no unit tests; a change is checked on a test server with
`tools/test_server.py`, and by reading the console when it needs more than that.

## Release a version

1. Raise the number in every line `grep -rn ZPAM_RENAME source` lists, the
   commented ones too: `level.pam_folder` and its error text, the version
   strings in `_pam.gsc`, `scr_motd`, `_zpam` in `source/default_mp.cfg`, both
   texts in `ui_mp/connect.menu`.
2. Add the previous iwd name to the blacklist in `global/pam.gsc` (the
   `ZPAM_RENAME - add old pam` line).
3. Update `source/readme.txt` (release date), `docs/CHANGES.md`, the iwd name in
   `README.md` and `docs/ai/SYSTEM_SUMMARY.md`.

## Translations

Players see the mod in their game's language (`loc_language`), the stock way:
`source/localizedstrings/zpam.str` holds one `REFERENCE` per string with a
`LANG_ENGLISH` line, the fallback, and one `LANG_<language>` line per
translation (`LANG_SPANISH`, `LANG_FRENCH`, `LANG_GERMAN`, `LANG_RUSSIAN`...).
GSC uses it as `&"ZPAM_<REFERENCE>"` and menus as `"@ZPAM_<REFERENCE>"`; the
file name gives the `ZPAM_` prefix. Keep the file in Windows-1252 with LF, as
the stock `.str` files, and give each `REFERENCE` its `LANG_ENGLISH` line first:
an English line after a translation hides it. A malformed `.str` stops the
client from loading every `.str` after it, the stock ones too, so
`tools/build-iwd.sh` refuses to build when `tools/check_str.py` finds one
(encoding, order, `&&N` arguments, sizes, `ENDMARKER`). So far the ready-up and time-out HUD and the quick
settings menu use it; text the server builds and sends by cvar
(`cg_objectiveText`, server info, match info) and `iprintln` messages are still
English.
