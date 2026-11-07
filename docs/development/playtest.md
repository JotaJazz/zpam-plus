# Play test with real players

What bots cannot check: how damage feels, menus, sounds, renames, reconnects
and time-outs. Each check names what to do, what should happen and where to
look. Damage numbers per weapon and range are already checked by
`tools/test_server.py --duel` ([building.md](building.md)).

## Setup

- 3 or 4 players with the OpenCoD2-Plus client; one of them knows the rcon
  password. A streamer slot is useful for check 9.
- The server: `tools/run-server.sh sd mp_toujane_fix +set pam_mode comp`, with
  `sv_wwwDownload 1` and `sv_wwwBaseURL` set from an exec'd cfg (`//` in a `+set`
  starts a comment), so players download `zpamplus1.iwd` and the map pack.
- Keep `.server/main/games_mp.log` and the console log after the session;
  most checks read them.
- Turn a check's debug cvar back to 0 when it is done.

## Checks

| # | Area | Do | Expect | Look at |
|---|---|---|---|---|
| 1 | Start | Join, ready up, play two rounds | No script error; `ReadyupDone;`, `RoundEnd;` and one `Stats;` line per player after each round | console, `games_mp.log` |
| 2 | Shotgun | Shoot each other with the shotgun at close, mid and long range (`rcon debug_shotgun 1` shows range and damage) | Up to 280 units one pellet kills; to 400 each pellet does 75, to 500 each does 35; past 500 only the first pellet hurts | screen messages |
| 3 | Neck | Aim at the neck with a Thompson or an MP40 | Damage like a head hit (`hitLoc:head` in the console with `developer 1`) | console `PlayerDamage` |
| 4 | Hand fix | Rifle shot at a player who holds the weapon in front of the body, from more than 200 units (`rcon debug_handhitbox 1`) | Counts as a kill when the head box is hit | screen messages |
| 5 | Eye height | Repeat 4 crouched and prone | The fix still fires; the eye is not at standing height | screen messages |
| 6 | MG | Mount an MG on a map with one; shoot head, torso, legs; then leave it | 100 / 75 / 35; leaving puts you behind the gun, not into a wall | `games_mp.log` `Damage;` |
| 7 | Plus 123 rules | Bolt rifle: fire, reload, scroll twice; prone while leaning; leave an MG | No faster second shot; no head jump; no peek from behind the MG | eyes |
| 8 | Climbing | Climb a ladder normally, then with the weapon held down (scroll down twice, hold fire) | Others hear the first, not the second | ears of another player |
| 9 | Streamer | Join the streamer team; a non-streamer types `/openscriptmenu streamersystem killcam_open` | Streamer sees replays; the other player gets nothing | screen |
| 10 | Hit indicator | Hit, kill, and one grenade into two players | Small yellowish cross for a hit, big white for a kill, a second cross and two sounds for two players | screen, ears |
| 11 | Time-out | Call a time-out; in its ready-up switch from a scope to the shotgun | Next round: shotgun and no scope; one `TO_CALL;` per call | inventory, `games_mp.log` |
| 12 | Kar bug | End a round with the kar98k in the second slot | Next round the kar is the first weapon | inventory |
| 13 | Names | Rename to `a;b`, then to `x[{+attack}]y` | Log shows `a:b`; the second becomes `x__+attack__y` with a message | `games_mp.log`, scoreboard |
| 14 | Reconnect | Mid-map, reconnect without waiting for the old slot (999 ping) | Kills and deaths come back at once; one `Stats;` line for the player | scoreboard, `games_mp.log` |
| 15 | Different IP | A second player takes the name of a disconnected one | He does not get the other player's stats | scoreboard |
| 16 | Kick | `rcon kick <name>`, then he reconnects | He can join again at once (`sv_kickBanTime 0`) | client |
| 17 | Score | Change the score from the rcon map menu in the first ready-up; then try after round 3 in `comp`, then in `comp_lan` | Allowed in the first ready-up; refused later in `comp`; allowed in `comp_lan` | screen |
| 18 | Draw | `rcon pam_mode comp_mr3_draw`, end the map tied | The map ends as a draw, no overtime; label shows "Draw" | screen |
| 19 | Menus | Open the rcon settings menu, the rcon map menu and the server info | Rows line up; the neck row and the draw button work; the server info fits its box | screen |
| 20 | Recording | Ready up in comp | A demo starts for each player (`scr_recording`) | client `demos/` |
| 21 | Plant and defuse | Plant, then defuse; another round, let it explode | Bomb timer, sounds, `plants`/`defuses` in `Stats;` | screen, `games_mp.log` |
| 22 | Strat | `g_gametype strat`: look at the compass, play a recorded bot, shoot a bot | A and B icons; clock at 0:00 when idle; damage messages with metres and the fix | screen |

## After the session

- Every check that failed goes into [roadmap/debt.md](../roadmap/debt.md) with
  what happened; checks that passed leave its "Not tested in game" row.
- The last `Stats;` line of each player is the ladder's view of the match:
  compare kills and deaths with the scoreboard.
