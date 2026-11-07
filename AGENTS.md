# AGENTS.md

zPAM Plus: the competition mod of the OpenCoD2-Plus family, a fork of zPAM 3.38
(eyza-cod2/zpam3) for Call of Duty 2. It runs only on the `make PLUS=1` build of
OpenCoD2-Plus Server, which serves only the OpenCoD2-Plus client
([ADR 0001](docs/architecture/adr/0001-plus-server-only.md)).

## Read first

1. [docs/ai/README_AI.md](docs/ai/README_AI.md), then the files it lists.
2. For a change in an area: [docs/architecture/](docs/architecture/overview.md)
   and [docs/architecture/boundaries.md](docs/architecture/boundaries.md).
3. Server side: `plus-protocol.md` in OpenCoD2-Plus Server's architecture docs is
   the source of truth for the Plus protocol; this mod follows it.

## Hard rules

- GSC lives in `source/`; the `.iwd` name must equal `level.pam_folder` in
  `source/maps/mp/gametypes/global/pam.gsc` (the mod refuses any other name).
- Build with `tools/build-iwd.sh`; test with `tools/test_server.py` (or
  `tools/run-server.sh`) against a CoD2 folder with only stock iwds, never a
  player install.
- Plus-only behaviour needs a signal from the server; never trust a value a
  client can set.
- Keep each file's line endings.
- Commit locally; push only when the maintainer asks. Imperative subject, a body
  with the why, and a `Co-Authored-By: Claude` line for AI-assisted commits.
- Never commit `CLAUDE.md`, `docs/superpowers/`, `.superpowers/` or `.claude/`.

## Doc-sync

- A change that makes a document wrong updates it in the same commit; the
  table is in [docs/ai/DEVELOPMENT_GUIDE.md](docs/ai/DEVELOPMENT_GUIDE.md#doc-sync).
- User-visible changes get a [docs/CHANGES.md](docs/CHANGES.md) entry.
- Finished work adds a stage to [docs/ai/PROJECT_MEMORY.md](docs/ai/PROJECT_MEMORY.md).
- Run `python3 scripts/check_docs.py` and
  `python3 -m unittest discover -s scripts` before committing documentation.
