# Glossary

| Term | Meaning |
|---|---|
| GSC | CoD2 game script language; `source/maps/` |
| iwd | zip archive the game loads from `main`; the mod is one iwd |
| Plus | OpenCoD2-Plus Server built with `make PLUS=1`, serving only the OpenCoD2-Plus client ("1.3 Plus") |
| `sv_plus` | read-only server dvar with the Plus version; only the Plus build has it |
| pam_mode | cvar that picks the rules: mode, score, toggles |
| comp / pub | competition rules / public server rules |
| readyup | phase before a match where every player must be ready |
| strat | gametype to practice strategies, without a match |
| firstInit | `game["firstInit"]`, true on the first load of a map, false on round restarts |
| `ZPAM_RENAME` | marker on every line that carries the mod's name or version |
| blacklist | iwds that make the installation check fail (old zPAM, old maps) |
