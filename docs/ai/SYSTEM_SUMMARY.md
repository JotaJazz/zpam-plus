# System summary

Updated 2026-11-05. Version: zPAM Plus 1, unreleased, on `feat/plus-foundation`.

## Tree

```
source/                     the iwd content
├── maps/mp/gametypes/      gametypes, global/ framework, _*.gsc modules, rules/
├── maps/mp/                map scripts
├── ui_mp/                  menus
└── default_mp.cfg          serverinfo _zpam
tools/                      build-iwd.sh, run-server.sh
scripts/                    check_docs.py and its tests
docs/upstream/              zPAM 3.38 manual, kept as written
images/                     pictures used by the upstream manual
```

## State

| Area | State |
|---|---|
| Rules and match flow | zPAM 3.38 with the audit fixes up to `dad08c5` |
| Plus check | built, `sv_plus` 122 or later; tested on stock 1.0 (refused) and a local Plus build (passes) |
| Name and version | "zPAM Plus 1", `zpamplus1.iwd`, `_zpam` = `Plus 1` |
| Real match on Plus | not yet |
| Automatic ladder | not started |

## Commands

| Task | Command |
|---|---|
| Build | `tools/build-iwd.sh` |
| Test server | `tools/run-server.sh [gametype] [map]` |
| Docs | `python3 scripts/check_docs.py` |
| Checker tests | `python3 -m unittest discover -s scripts` |

## Contracts

| With | Contract |
|---|---|
| OpenCoD2-Plus Server | `sv_plus` read-only, Plus build only, value `PLUS_VERSION` (122) |
| Server admins | iwd name `zpamplus1`, run from `main`, www download on, `zpam_maps_v6.iwd` |
