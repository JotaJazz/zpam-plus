# Project memory

Append-only. Newest first.

## 2026-11-05 — zPAM Plus joins the OpenCoD2-Plus family

- Repository identity, agent rules and this memory layer added on top of zPAM
  3.38 (audit fixes in `8ba7504`..`dad08c5`).
- Decided: Plus server only ([ADR 0001](../architecture/adr/0001-plus-server-only.md)).
- The mod checks `sv_plus` (OpenCoD2-Plus Server `f5697e8`) in
  `CheckInstallation` and refuses with the installation error when it is below
  122. Checked with `tools/run-server.sh`: the stock 1.0 build shows the Plus
  error, and a `make PLUS=1` build of `f5697e8` passes it and stops at the next
  1.3 check (`sv_wwwDownload`), as expected without www download.
- Renamed to zPAM Plus, versioned from 1: shown as "zPAM Plus 1", iwd
  `zpamplus1.iwd`, serverinfo `_zpam` = `Plus 1`, help links to
  JotaJazz/zpam-plus. `zpam338` joins the blacklist so the two cannot load
  together. Each version raises the number in every `ZPAM_RENAME` line.
- Left: `README.md` still describes zPAM 3.38 upstream.
