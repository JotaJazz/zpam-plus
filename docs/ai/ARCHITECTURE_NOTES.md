# Architecture notes

Normative summary; detail in [boundaries.md](../architecture/boundaries.md) and
[overview.md](../architecture/overview.md).

## Must

- Keep zPAM 3.38 match behaviour unless `docs/CHANGES.md` says otherwise.
- Refuse to run unless `sv_plus` is 123 or later.
- Precache before the first `wait`; new `SetText` strings through `precacheString2` in `game["firstInit"]`.
- Add features as `_<name>.gsc` modules in `InitModules`, in dependency order.
- Mark every name or version line `// ZPAM_RENAME`.
- Call a mod method that shares its name with a libcod builtin (such as
  `getStance`) with its path: the server looks up builtins first.

## Must not

- Trust client-set values for Plus, rules or results.
- Run from `fs_game`.
- Change server or client code from this repository.

## Irreversible

- Plus server only: [ADR 0001](../architecture/adr/0001-plus-server-only.md).
- Versions count from 1 (`zpamplus<N>`); zPAM 3.x numbering is not continued.
