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

No-shows and leavers (phase C): the first ready-up does not end until both rosters are in
their teams and ready. If scr_ladder_ready_timeout seconds pass first, the match is not
played: LadderForfeit;<match id>;<team1|team2|both>. A roster player away from the started
match longer than the halftime auto-resume (2 minutes without one) is logged when he comes
back or at the end of the map: LadderLeaver;<match id>;<player>;<seconds away>.
*/

init()
{
	registerCvarEx("I", "scr_ladder_match", "STRING", "");
	registerCvarEx("I", "scr_ladder_team1", "STRING", "");
	registerCvarEx("I", "scr_ladder_team2", "STRING", "");
	registerCvarEx("I", "scr_ladder_team1_name", "STRING", "");
	registerCvarEx("I", "scr_ladder_team2_name", "STRING", "");
	registerCvarEx("I", "scr_ladder_ready_timeout", "INT", 0, 0, 3600);

	if (!isDefined(game["ladder_started"]))
		game["ladder_started"] = false;
	if (!isDefined(game["ladder_team1_side"]))
		game["ladder_team1_side"] = "allies"; // flips at every halftime
	if (!isDefined(game["ladder_forfeit"]))
		game["ladder_forfeit"] = false;
	if (!isDefined(game["ladder_away"]))
		game["ladder_away"] = []; // name key -> system time of the disconnect

	addEventListener("onConnected", ::onConnected);
	addEventListener("onDisconnect", ::onDisconnect);
	addEventListener("onJoinedTeam", ::onJoinedTeam);

	level thread onReadyUpOver();
	level thread forfeitWatch();
}

onReadyUpOver()
{
	level waittill("rupover");

	// Only the first ready-up of the map starts the match; halftime and time-out ready-ups do not
	if (!game["readyup_first_run"] || game["ladder_started"] || game["ladder_forfeit"] || getCvar("scr_ladder_match") == "")
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

	// Roster players still away at the end
	keys = getArrayKeys(game["ladder_away"]);
	for (i = 0; i < keys.size; i++)
		logLeaver(keys[i]);

	game["ladder_started"] = false;
}

// The first ready-up waits for both rosters; true when there is no roster or when both are in and ready
rosterReady()
{
	if (!isDefined(game["readyup_first_run"]) || !game["readyup_first_run"] || !hasRoster())
		return true;
	return teamReady(getCvar("scr_ladder_team1"), game["ladder_team1_side"]) &&
	       teamReady(getCvar("scr_ladder_team2"), otherSide(game["ladder_team1_side"]));
}

// Every listed name has a player in that team who is ready
teamReady(list, side)
{
	names = maps\mp\gametypes\global\string::splitString(list, ";");
	players = getentarray("player", "classname");
	for (n = 0; n < names.size; n++)
	{
		key = nameKey(names[n]);
		if (key == "")
			continue;
		found = false;
		for (i = 0; i < players.size; i++)
			if (nameKey(players[i].name) == key && players[i].pers["team"] == side && isDefined(players[i].isReady) && players[i].isReady)
				found = true;
		if (!found)
			return false;
	}
	return true;
}

forfeitWatch()
{
	level endon("rupover");

	timeout = getCvarInt("scr_ladder_ready_timeout");
	if (timeout <= 0 || !hasRoster() || !game["readyup_first_run"] || game["ladder_forfeit"])
		return;

	wait timeout;

	ready1 = teamReady(getCvar("scr_ladder_team1"), game["ladder_team1_side"]);
	ready2 = teamReady(getCvar("scr_ladder_team2"), otherSide(game["ladder_team1_side"]));
	if (ready1 && ready2)
		return;

	team = "both";
	if (ready1)
		team = "team2";
	else if (ready2)
		team = "team1";
	game["ladder_forfeit"] = true;
	logPrint("LadderForfeit;" + logSafe(getCvar("scr_ladder_match")) + ";" + team + "\n");
	iprintlnbold("^3Ladder match not played: " + team + " did not join and ready up in time.");
}

// With a roster, who is in which team decides the first ready-up, and a team change from
// "none" (a fresh connect) keeps the ready of the watchers and triggers no ready-up check
onJoinedTeam(team)
{
	if (hasRoster() && game["readyup_first_run"] && isDefined(level.in_readyup) && level.in_readyup)
		level thread maps\mp\gametypes\_readyup::Check_All_Ready();
}

onDisconnect()
{
	if (game["ladder_started"] && hasRoster() && self rosterTeam() != "spectator")
		game["ladder_away"][nameKey(self.name)] = getSystemTime();
}

onConnected()
{
	key = nameKey(self.name);
	if (isDefined(game["ladder_away"][key]))
		logLeaver(key);
}

// Logs a roster player who was away longer than the halftime auto-resume, and forgets him
logLeaver(key)
{
	away = getSystemTime() - game["ladder_away"][key];
	game["ladder_away"][key] = undefined;

	limit = 120;
	if (level.scr_readyup_autoresume_half > 0)
		limit = int(level.scr_readyup_autoresume_half * 60);
	if (away > limit)
		logPrint("LadderLeaver;" + logSafe(game["ladder_match"]) + ";" + logSafe(key) + ";" + away + "\n");
}

// The team self must be in: his roster team, or "spectator" if he is not in the roster;
// undefined when there is no ladder match or no roster
rosterTeam()
{
	if (!hasRoster())
		return undefined;

	if (inRoster(getCvar("scr_ladder_team1"), self.name))
		return game["ladder_team1_side"];
	if (inRoster(getCvar("scr_ladder_team2"), self.name))
		return otherSide(game["ladder_team1_side"]);
	return "spectator";
}

// A ladder match with a roster is set
hasRoster()
{
	return getCvar("scr_ladder_match") != "" && (getCvar("scr_ladder_team1") != "" || getCvar("scr_ladder_team2") != "");
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
