#include maps\mp\gametypes\global\_global;

init()
{
	addEventListener("onCvarChanged", ::onCvarChanged);

	registerCvarEx("", "scr_score_change_mode", "INT", 1, 0, 2); // 0 - disabled, 1 - only in first ready-up, 2 - always
	registerCvarEx("I", "scr_score_allies", "INT", -1, -1, 9999);
	registerCvarEx("I", "scr_score_axis", "INT", -1, -1, 9999);
}

// This function is called when cvar changes value.
// Is also called when cvar is registered
// Return true if cvar was handled here, otherwise false
onCvarChanged(cvar, value, isRegisterTime)
{
	switch(cvar)
	{
		case "scr_score_change_mode":
			level.scr_score_change_mode = value;
			return true;

		case "scr_score_allies":
			thread handleAllies(cvar, value, isRegisterTime);
			return true;

		case "scr_score_axis":
			thread handleAxis(cvar, value, isRegisterTime);
			return true;
	}
	return false;
}

handleAllies(cvar, value, isRegisterTime)
{
	if (value >= 0)
	{
		if (isRegisterTime)
			wait level.frame; // in register time, score is not defined yet

		roundsplayed = game["axis_score"] + value;

		handle("allies", roundsplayed, value);

		changeCvarQuiet(cvar, -1);
	}
}

handleAxis(cvar, value, isRegisterTime)
{
	if (value >= 0)
	{
		if (isRegisterTime)
			wait level.frame; // in register time, score is not defined yet

		roundsplayed = game["allies_score"] + value;

		handle("axis", roundsplayed, value);

		changeCvarQuiet(cvar, -1);
	}
}




handle(team, roundsplayed, value)
{
	if (level.gametype != "sd" && level.gametype != "re")
	{
		iprintln(&"ZPAM_SCORE_ONLY_SD_RE");
		return false;
	}
	if (level.scr_score_change_mode == 0)
	{
		iprintln(&"ZPAM_SCORE_DISABLED");
		return false;
	}
	if (level.scr_score_change_mode == 1 && !game["readyup_first_run"])
	{
		iprintln(&"ZPAM_SCORE_ONLY_FIRST_READYUP");
		return false;
	}
	if (roundsplayed >= level.matchround && level.matchround > 0)
	{
		iprintln(&"ZPAM_SCORE_OVER_ROUNDS", value, level.matchround);
		return false;
	}
	if (value >= level.scorelimit && level.scorelimit > 0)
	{
		iprintln(&"ZPAM_SCORE_OVER_LIMIT", value, level.scorelimit);
		return false;
	}




	if ((roundsplayed >= level.halfround && level.halfround > 0) || (value >= level.halfscore && level.halfscore > 0))
	{
		game["is_halftime"] = true;

		game["half_2_"+team+"_score"] = value;
	}

	else
	{
		game["is_halftime"] = false;

		game["half_1_"+team+"_score"] = value;
	}




	game[team + "_score"] = value;



	setTeamScore(team, game[team + "_score"]);

	level maps\mp\gametypes\_hud_teamscore::updateScore();

	game["roundsplayed"] = roundsplayed;


	return true;
}
