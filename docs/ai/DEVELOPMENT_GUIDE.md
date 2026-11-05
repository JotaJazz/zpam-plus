# Development guide

## Workflow

1. Branch from the current work branch; `master` gets finished work.
2. Change `source/`, then run it on a test server
   ([building.md](../development/building.md)).
3. Update the docs in the same commit; run `python3 scripts/check_docs.py` and
   `python3 -m unittest discover -s scripts`.
4. Commit locally: imperative subject, a body with the why, `Co-Authored-By`
   for AI-assisted commits. Push only when the maintainer asks.

## Doc-sync

| When you change | Update |
|---|---|
| Behaviour players or admins see | `docs/CHANGES.md` |
| The installation check | `architecture/overview.md` (order), `README.md` if a requirement changes |
| A module, its order or a dependency | `architecture/overview.md` |
| pam_mode values or `rules/` | `architecture/overview.md` (rules table) |
| Name or version | follow the release steps in `development/building.md` |
| What the mod needs from the server | `SYSTEM_SUMMARY.md` (contracts), an ADR if it is a decision |
| `tools/` | `development/building.md` |
| Any finished piece of work | a stage in `PROJECT_MEMORY.md` |
| Project state | `SYSTEM_SUMMARY.md` and its date |

## Memory entry

```markdown
## YYYY-MM-DD — topic

- What changed and why it mattered.
- What was rejected.
- What is left open.
```

At most 3 bullets; newest first; never rewrite an old stage.
