#include maps\mp\gametypes\global\_global;

/*
Ladder match reporting, phase A of docs/architecture/adr/0003-ladder-server-side.md.
The ladder service sets scr_ladder_match (and later the roster) by rcon before the map;
with it empty the mod behaves as before. games_mp.log gets:
  LadderStart;<match id>;<map>;<pam_mode>                        when the first ready-up ends
  LadderEnd;<match id>;<score team1>;<score team2>;<team1|team2|draw>   when the map ends
Team1 is the team on allies when the match starts; it keeps its number when sides swap.

Roster (phase B): scr_ladder_team1 and scr_ladder_team2 list the players by name, separated
by ";" (colours, case and spaces at the ends do not count). An entry "P-XXXX-XXXX-XXXX-XXXX"
(phase D) is a Plus ID: only the player whose connect the server verified with that ID
matches it, whatever his name. With a match id and a roster, a
player in it can only join his team; anyone else can only watch. scr_ladder_team1_name and
scr_ladder_team2_name, if set, are the team names.

No-shows and leavers (phase C): the first ready-up does not end until both rosters are in
their teams and ready. If scr_ladder_ready_timeout seconds pass first, the match is not
played: LadderForfeit;<match id>;<team1|team2|both>. A roster player away from the started
match longer than the halftime auto-resume (2 minutes without one) is logged when he comes
back or at the end of the map: LadderLeaver;<match id>;<player>;<seconds away>, where the
player is his Plus ID when the roster names him by it, else his name key.
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
		game["ladder_away"] = []; // roster key -> system time of the disconnect

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

	// Roster players still away at the end (getArrayKeys errors on an empty array)
	if (game["ladder_away"].size > 0)
	{
		keys = getArrayKeys(game["ladder_away"]);
		for (i = 0; i < keys.size; i++)
			logLeaver(keys[i]);
	}

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

// Every listed player is in that team and ready
teamReady(list, side)
{
	names = maps\mp\gametypes\global\string::splitString(list, ";");
	players = getentarray("player", "classname");
	for (n = 0; n < names.size; n++)
	{
		if (nameKey(names[n]) == "")
			continue;
		found = false;
		for (i = 0; i < players.size; i++)
			if (players[i] rosterKey(names[n]) != "" && players[i].pers["team"] == side && isDefined(players[i].isReady) && players[i].isReady)
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
	iprintlnbold(&"ZPAM_LADDER_FORFEIT", team);
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
	key = self rosterKey(getCvar("scr_ladder_team1") + ";" + getCvar("scr_ladder_team2"));
	if (game["ladder_started"] && hasRoster() && key != "")
		game["ladder_away"][key] = getSystemTime();
}

onConnected()
{
	key = self rosterKey(getCvar("scr_ladder_team1") + ";" + getCvar("scr_ladder_team2"));
	if (key != "" && isDefined(game["ladder_away"][key]))
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

	if (self rosterKey(getCvar("scr_ladder_team1")) != "")
		return game["ladder_team1_side"];
	if (self rosterKey(getCvar("scr_ladder_team2")) != "")
		return otherSide(game["ladder_team1_side"]);
	return "spectator";
}

// A ladder match with a roster is set
hasRoster()
{
	return getCvar("scr_ladder_match") != "" && (getCvar("scr_ladder_team1") != "" || getCvar("scr_ladder_team2") != "");
}

// The key of the entry of list that self matches, or "" when none does
rosterKey(list)
{
	return entriesKey(list, self.name, self getPlusId()); // getPlusId: "" for bots and unverified players
}

// A "P-" entry matches only plusId (verified by the server at connect); any other matches the name
entriesKey(list, name, plusId)
{
	names = maps\mp\gametypes\global\string::splitString(list, ";");
	for (i = 0; i < names.size; i++)
	{
		key = nameKey(names[i]);
		if (key == "")
			continue;
		if (maps\mp\gametypes\global\string::startsWith(key, "p-"))
		{
			if (plusId != "" && toLower(plusId) == key)
				return plusId;
		}
		else if (nameKey(name) == key)
			return key;
	}
	return "";
}

// developer_script 1
ladderSelfTest()
{
	id = "P-ABCD-EFGH-IJKL-MNOP";
	if (entriesKey("x;" + id, "anyone", id) != id) assertMsg("ladder selfTest: id");
	if (entriesKey("x;p-abcd-efgh-ijkl-mnop ", "anyone", id) != id) assertMsg("ladder selfTest: id case");
	if (entriesKey(id, "^1" + id, "") != "") assertMsg("ladder selfTest: name as id");
	if (entriesKey(id, id, "P-ZZZZ-EFGH-IJKL-MNOP") != "") assertMsg("ladder selfTest: other id");
	if (entriesKey(" ^2Bob ;x", "bob", id) != "bob") assertMsg("ladder selfTest: name");
	if (entriesKey("a;;b", "", "") != "") assertMsg("ladder selfTest: empty");
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
