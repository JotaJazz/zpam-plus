#include maps\mp\gametypes\global\_global;

/*
Ladder match reporting, phase A of docs/architecture/adr/0003-ladder-server-side.md.
The ladder service sets scr_ladder_match (and later the roster) by rcon before the map;
with it empty the mod behaves as before. games_mp.log gets:
  LadderStart;<match id>;<map>;<pam_mode>                        when the first ready-up ends
  LadderEnd;<match id>;<score team1>;<score team2>;<team1|team2|draw>   when the map ends
Team1 is the team on allies when the match starts; it keeps its number when sides swap.
*/

init()
{
	registerCvarEx("I", "scr_ladder_match", "STRING", "");
	registerCvarEx("I", "scr_ladder_team1", "STRING", "");		// roster, phase B
	registerCvarEx("I", "scr_ladder_team2", "STRING", "");		// roster, phase B
	registerCvarEx("I", "scr_ladder_ready_timeout", "INT", 0, 0, 3600);	// forfeit, phase C

	if (!isDefined(game["ladder_started"]))
		game["ladder_started"] = false;

	level thread onReadyUpOver();
}

onReadyUpOver()
{
	level waittill("rupover");

	// Only the first ready-up of the map starts the match; halftime and time-out ready-ups do not
	if (!game["readyup_first_run"] || game["ladder_started"] || getCvar("scr_ladder_match") == "")
		return;

	game["ladder_started"] = true;
	game["ladder_match"] = getCvar("scr_ladder_match");
	game["ladder_team1_side"] = "allies";
	logPrint("LadderStart;" + logSafe(game["ladder_match"]) + ";" + level.mapname + ";" + logSafe(level.pam_mode) + "\n");
}

// Called from _halftime after the teams and their scores swap sides
onSideSwap()
{
	if (!game["ladder_started"])
		return;
	if (game["ladder_team1_side"] == "allies")
		game["ladder_team1_side"] = "axis";
	else
		game["ladder_team1_side"] = "allies";
}

// Called from _end_of_map when the last round is over
onMapEnd()
{
	if (!game["ladder_started"])
		return;

	team2_side = "axis";
	if (game["ladder_team1_side"] == "axis")
		team2_side = "allies";
	score1 = getTeamScore(game["ladder_team1_side"]);
	score2 = getTeamScore(team2_side);

	winner = "draw";
	if (score1 > score2)
		winner = "team1";
	else if (score2 > score1)
		winner = "team2";

	logPrint("LadderEnd;" + logSafe(game["ladder_match"]) + ";" + score1 + ";" + score2 + ";" + winner + "\n");
	game["ladder_started"] = false;
}
