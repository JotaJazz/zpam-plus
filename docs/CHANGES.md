# Changes

Changes since zPAM 3.38. Earlier history:
[upstream/zpam-3.38.md](upstream/zpam-3.38.md#changelog).

## zPAM Plus 1 (unreleased)

- Renamed to zPAM Plus; the iwd is `zpamplus1.iwd` and serverinfo `_zpam` is
  `Plus 1`.
- Runs only on OpenCoD2-Plus Server built with `make PLUS=1`: anywhere else it
  shows the installation error with the reason.
- `zpam338.iwd` in `main` is refused, as older zPAM iwds already were.
- Help links point to JotaJazz/zpam-plus.
- A `;` in a player name is written as `:` in `games_mp.log`, so a name cannot add
  fields to a log line.
- Timers last real seconds at any `sv_fps`; at 40 Hz they lasted twice as long.
- Comp, strat and dm warmup rules run at 40 Hz: `sv_fps 40`, `g_forceSnaps 40`,
  `g_forceRate 40000` and `sv_maxRate 0` (was `sv_fps 30` and `sv_maxRate 25000`).
- Kill replays only open for players in the streamer team; before, anyone could
  open them from the console.
- Calling a time-out twice in time-based modes no longer stacks two countdowns.
  Time-out call/cancel (2 s), the team-change message (2 s) and scoreboard
  clicks (0.5 s) are rate-limited per player.
- `pam_mode` with a suffix after `pub` (such as `pub_mr12`) is refused as an
  invalid value; before, it crashed the map with a script error.
- Reconnecting restores stats only from the same IP; before, any player with
  the same name got them. Renaming to the name of a disconnected player no
  longer deletes that player's stats: the renamed player keeps his own under the
  old name.
- `hq` no longer stops the server with a script error when the match starts.
- The hand-hitbox and shotgun fixes take the attacker's eye from the engine's
  view origin (stance and lean); on the Plus server it was always the standing
  height.
- A name with `[{...}]`, which the game draws as a key binding ("Unbound"), is
  renamed with `_` in place of the brackets.
- Changing the selected weapon during a time-out no longer lets a player spawn
  with a saved scope and the new shotgun: the saved weapons are checked against
  the selection again at spawn. The selected weapon saved in the secondary slot
  spawns first ("kar bug").
- Hit stats count the scoped Kar98k like the other scoped rifles, and count the
  buffed BAR and the FG42; the round report names them.
- Comp, strat and dm warmup rules set `sv_kickBanTime 0`: a player kicked by the
  mod (or by an admin) can reconnect at once instead of being banned by IP for
  5 minutes.
- Once a non-pub match has started, a disconnected player's stats are kept
  until the map ends (before, 2 minutes). A player who reconnects in the middle
  of a map while his old connection still waits for `sv_timeout` gets his stats
  back instead of a new row.
- Leaving a mounted MG moves the player behind it once, when he leaves; before,
  his position was set every frame while he used it, which made his view tear
  for spectators.
- MG hits do 100 to the head and neck, 75 to the torso and upper legs and 35
  elsewhere; before, the server used the multipliers of the weapon the player
  held before mounting it (a pistol gave pistol damage).
- New `scr_hitbox_neck_kill` (on in comp, strat and dm warmup): a bullet in the
  neck counts as a head hit, with the weapon's head damage. Shown in server info
  and in the rcon settings menu.
- The hand-hitbox fix uses a slightly bigger box around the head (2 units more
  to the right and down; when the player moves, 13 to the left and 15 to the
  right).
- New `draw` sub-mode (`pam_mode comp_mr12_draw`): a tie ends the map as a draw,
  with no overtime. It is in the rcon map menu and the pam modes help, and the
  league label shows "Draw".
- In ready-up a killed player respawns after 0.5 s instead of 2 s.
- sd: the bombsite icons show on the compass one frame after the round starts
  (was 0.2 s), and the round clock turns orange at 0:30 (was 0.3 s earlier).
- `g_debugDamage` prints the damage after the hitbox, shotgun and MG fixes, so
  it shows what is applied.
- Map vote names maps like the match info does: the `_fix` maps get their names
  (they showed as `mp_toujane_fix`); stock maps show their file name (Farmhouse,
  not Beltot).
- dm counts kills, deaths and score in the player stats (scoreboard and match
  info), as sd and re already did.
- strat: the bombsite icons show on the compass, the replay clock is always on
  screen (0:00 when idle), and damage messages give the distance in metres and
  the fix that changed the hit.
- On a Plus 123 server the fast reload, prone peek and MG clip fixes are left to
  the engine, which applies them on both sides; the mod's script versions run
  only on older Plus servers. The climbing sound fix stays: the mod silences
  `weap_raise`, which the Plus client plays for climbing.
- New hit indicator: a hit shows a smaller yellowish cross that fades at once;
  a kill shows a bigger white cross that shrinks back; one shot or grenade that
  hits two or more players adds a second cross and plays one sound per player;
  team hits are red in every team gametype (before, only in sd).
