#include maps\mp\gametypes\global\_global;

/*
Ladder match reporting, phase A of docs/architecture/adr/0003-ladder-server-side.md.
The ladder service sets scr_ladder_match (and later the roster) by rcon before the map;
with it empty the mod behaves as before. games_mp.log gets:
  LadderStart;<match id>;<map>;<pam_mode>                        when the first ready-up ends
  LadderEnd;<match id>;<score team1>;<score team2>;<team1|team2|draw>   when the map ends
Team1 is the team on allies when the match starts; it keeps its number when sides swap.

Roster (phase B): scr_ladder_team1 and scr_ladder_team2 list the players by name, separated
by ";" (colours, case and spaces at the ends do not count). With a match id and a roster, a
player in it can only join his team; anyone else can only watch. scr_ladder_team1_name and
scr_ladder_team2_name, if set, are the team names.
*/

init()
{
	registerCvarEx("I", "scr_ladder_match", "STRING", "");
	registerCvarEx("I", "scr_ladder_team1", "STRING", "");
	registerCvarEx("I", "scr_ladder_team2", "STRING", "");
	registerCvarEx("I", "scr_ladder_team1_name", "STRING", "");
	registerCvarEx("I", "scr_ladder_team2_name", "STRING", "");
	registerCvarEx("I", "scr_ladder_ready_timeout", "INT", 0, 0, 3600);	// forfeit, phase C

	if (!isDefined(game["ladder_started"]))
		game["ladder_started"] = false;
	if (!isDefined(game["ladder_team1_side"]))
		game["ladder_team1_side"] = "allies"; // flips at every halftime

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
	logPrint("LadderStart;" + logSafe(game["ladder_match"]) + ";" + level.mapname + ";" + logSafe(level.pam_mode) + "\n");
}

// Called from _halftime after the teams and their scores swap sides
onSideSwap()
{
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

// The team self must be in: his roster team, or "spectator" if he is not in the roster;
// undefined when there is no ladder match or no roster
rosterTeam()
{
	if (getCvar("scr_ladder_match") == "" || (getCvar("scr_ladder_team1") == "" && getCvar("scr_ladder_team2") == ""))
		return undefined;

	if (inRoster(getCvar("scr_ladder_team1"), self.name))
		return game["ladder_team1_side"];
	if (inRoster(getCvar("scr_ladder_team2"), self.name))
		return otherSide(game["ladder_team1_side"]);
	return "spectator";
}

inRoster(list, name)
{
	key = nameKey(name);
	names = maps\mp\gametypes\global\string::splitString(list, ";");
	for (i = 0; i < names.size; i++)
		if (nameKey(names[i]) == key && key != "")
			return true;
	return false;
}

nameKey(name)
{
	return toLower(maps\mp\gametypes\global\string::trim(removeColorsFromString(name)));
}

otherSide(side)
{
	if (side == "allies")
		return "axis";
	return "allies";
}

// Team name the ladder service set for the team on this side, or "" to let _teamname choose
teamName(side)
{
	// "" asks for a name for all players together; before init the sides are not known
	if (getCvar("scr_ladder_match") == "" || (side != "allies" && side != "axis") || !isDefined(game["ladder_team1_side"]))
		return "";
	if (side == game["ladder_team1_side"])
		name = getCvar("scr_ladder_team1_name");
	else
		name = getCvar("scr_ladder_team2_name");
	return maps\mp\gametypes\_teamname::getSecureString(name);
}
