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
- Left: the in-game name is still "zPAM 3.38" and the help URL points to
  eyza-cod2/zpam3.
