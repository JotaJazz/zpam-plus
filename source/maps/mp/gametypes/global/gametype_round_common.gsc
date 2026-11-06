#include maps\mp\gametypes\global\_global;

// Functions with the same body in sd and re. Included by those two
// files: fix them here, not in a copy.

HUD_RoundInfo(time)
{
	if (game["round"] == 1)
	{
		roundInfo = addHUD(0, 430, 1.3, (.8, 1, 1), "center", "bottom", "center_safearea", "top");
		roundInfo setText(game["STRING_ROUND_FIRST"]);
		roundInfo.y = 360;
		roundInfo moveovertime(3);
		roundInfo.y = 428;
		level waittill("strat_time_end");
		roundInfo thread destroyHUDSmooth(.5);
	}
	// Last round before half
	else if (level.halfround > 0 && !game["is_halftime"] && game["round"] >= level.halfround)
	{
		roundInfo = addHUD(0, 430, 1.3, (.8, 1, 1), "center", "bottom", "center_safearea", "top");
		roundInfo setText(game["STRING_ROUND_LAST_HALF"]);
		roundInfo.y = 360;
		roundInfo moveovertime(3);
		roundInfo.y = 428;
		level waittill("strat_time_end");
		roundInfo thread destroyHUDSmooth(.5);
	}
	// Last match round
	else if (level.matchround > 0 && game["is_halftime"] && game["round"] >= level.matchround)
	{
		roundInfo = addHUD(0, 430, 1.3, (.8, 1, 1), "center", "bottom", "center_safearea", "top");
		roundInfo setText(game["STRING_ROUND_LAST"]);
		roundInfo.y = 360;
		roundInfo moveovertime(3);
		roundInfo.y = 428;
		level waittill("strat_time_end");
		roundInfo thread destroyHUDSmooth(.5);
	}
	else
	{
		roundInfo1 = addHUD(10, 428, 1.3, (.8, 1, 1), "right", "bottom", "center_safearea", "top");
		roundInfo2 = addHUD(14, 428, 1.3, (.8, 1, 1), "left", "bottom", "center_safearea", "top");

		roundInfo1 setText(game["STRING_ROUND"]);
		roundInfo2 setValue(game["round"]);

		level waittill("strat_time_end");

		roundInfo1 thread destroyHUDSmooth(.5);
		roundInfo2 thread destroyHUDSmooth(.5);
	}


}

// Round limit (20)
checkMatchRoundLimit()
{
	// Is it a round-based Halftime? (in cg is 10)
	if (!game["is_halftime"] && level.halfround != 0)
	{
		if(game["roundsplayed"] >= level.halfround)
		{
			level thread maps\mp\gametypes\_halftime::Do_Half_Time();
			return true;
		}
	}

	// Is it a round-based Map-End? (20)
	if (level.matchround != 0)
	{
		if (game["roundsplayed"] >= level.matchround)
		{
			if (level.scr_overtime && game["allies_score"] == game["axis_score"])
				level thread maps\mp\gametypes\_overtime::Do_Overtime();
			else
				level thread maps\mp\gametypes\_end_of_map::Do_Map_End();

			return true;
		}
	}

	return false;
}

/*
Called when player is about to take a damage.
self is the player that took damage.
Return true to prevent the damage.
*/
onPlayerDamaging(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	// In readyup there is own onPlayerDamaging function
	if (level.in_readyup)
		return false;

	// Prevent damage when:
	if (!level.matchstarted || level.in_strattime || level.roundended)
		return true;

	// In bash mode allow damage only via pistol bash
	if (level.in_bash && (sMeansOfDeath != "MOD_MELEE" || !maps\mp\gametypes\_weapons::isPistol(sWeapon)))
		return true;

	// Friendly fire is disabled - prevent damage
	if(!(iDFlags & level.iDFLAGS_NO_PROTECTION))
	{
		if(isPlayer(eAttacker) && (self != eAttacker) && (self.pers["team"] == eAttacker.pers["team"]))
		{
			if(level.scr_friendlyfire == 0)
			{
				return true;
			}
		}
	}
}

// Score limit (not used in cg)
checkMatchScoreLimit()
{
	// Is it a score-based Halftime?
	if(!game["is_halftime"] && level.halfscore != 0)
	{
		if(game["half_1_allies_score"] >= level.halfscore || game["half_1_axis_score"] >= level.halfscore)
		{
			level thread maps\mp\gametypes\_halftime::Do_Half_Time();
			return true;
		}
	}

	// Is it a score-based Map-End?
	if (level.scorelimit != 0)
	{
		if (game["allies_score"] >= level.scorelimit || game["axis_score"] >= level.scorelimit)
		{
			level thread maps\mp\gametypes\_end_of_map::Do_Map_End();
			return true;
		}
	}

	return false;
}

deadchat()
{
	for(;;)
	{
		if (!level.scr_auto_deadchat)
			return;


		if ( (level.in_readyup || level.in_timeout || level.roundended) && level.deadchat == 0)
		{
			maps\mp\gametypes\global\cvar_system::restoreCvarQuiet("g_deadChat");
			maps\mp\gametypes\global\cvar_system::setCvarQuiet("g_deadChat", 1); //setcvar("g_deadchat", 1);
		}

		// Disable dead chat
		else if (level.roundstarted && !level.roundended && level.deadchat == 1)
		{
			maps\mp\gametypes\global\cvar_system::restoreCvarQuiet("g_deadChat");
			maps\mp\gametypes\global\cvar_system::setCvarQuiet("g_deadChat", 0); //setcvar("g_deadchat", 0);
		}

		wait 1;
	}
}

announceWinner(winner, delay)
{
	wait delay;

	// Announce winner
	if(winner == "allies")
	{
		level thread playSoundOnPlayers("MP_announcer_allies_win");
	}
	else if(winner == "axis")
	{
		level thread playSoundOnPlayers("MP_announcer_axis_win");
	}
	else if(winner == "draw")
	{
		level thread playSoundOnPlayers("MP_announcer_round_draw");
	}
}

playSoundOnPlayers(sound, team)
{
	players = getentarray("player", "classname");

	if(isdefined(team))
	{
		for(i = 0; i < players.size; i++)
		{
			if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
				players[i] playLocalSound(sound);
		}
	}
	else
	{
		for(i = 0; i < players.size; i++)
			players[i] playLocalSound(sound);
	}
}

checkTimeLimit()
{
	if (level.timelimit > 0 && game["timepassed"] >= level.timelimit)
	{
		iprintln(&"MP_TIME_LIMIT_REACHED");

		level thread maps\mp\gametypes\_end_of_map::Do_Map_End();

		return true; // ended
	}

	return false;
}

// This function is called as last after all events are processed
onAfterConnected()
{
	// If the game is at the post game state (scoreboard) the connecting player should spawn into intermission
	if (game["state"] == "intermission")
		self [[level.spawnIntermission]]();

	// If player is just connected and blackout needs to be activated
	else if (self.pers["team"] == "none")
	{
		if (self maps\mp\gametypes\_blackout::isBlackoutNeeded())
			self maps\mp\gametypes\_blackout::spawnBlackout();
		else
			self [[level.spawnSpectator]]();
	}

	// Spectator team
	else if (self.pers["team"] == "spectator" || self.pers["team"] == "streamer")
		self [[level.spawnSpectator]]();

	// If team is selected
	else if (self.pers["team"] == "allies" || self.pers["team"] == "axis")
	{
		// If player have choozen weapon
		if(isDefined(self.pers["weapon"]))
			self [[level.spawnPlayer]]();
		// If player have choosen team, but have not choosen weapon (he is selecting from weapons menu)
		else
			self [[level.spawnSpectator]]();
	}

	else
		assertMsg("Unknown team");
}

menuAutoAssign()
{
	// Team is already selected, do nothing and open menu again
	if(self.pers["team"] == "allies" || self.pers["team"] == "axis")
	{
		return;
	}

	numonteam["allies"] = 0;
	numonteam["axis"] = 0;

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if(player.pers["team"] != "allies" && player.pers["team"] != "axis")
			continue;

		numonteam[player.pers["team"]]++;
	}

	// if teams are equal return the team with the lowest score
	if(numonteam["allies"] == numonteam["axis"])
	{
		if(getTeamScore("allies") == getTeamScore("axis"))
		{
			teams[0] = "allies";
			teams[1] = "axis";
			assignment = teams[randomInt(2)];
		}
		else if(getTeamScore("allies") < getTeamScore("axis"))
			assignment = "allies";
		else
			assignment = "axis";
	}
	else if(numonteam["allies"] < numonteam["axis"])
		assignment = "allies";
	else
		assignment = "axis";


	self.joining_team = assignment; // can be allies or axis
	self.leaving_team = self.pers["team"]; // can be "spectator" or "none"

	if(assignment != self.pers["team"] && (self.sessionstate == "playing" || self.sessionstate == "dead"))
	{
		self.switching_teams = true;
		self suicide();
	}

	self.sessionteam = assignment;
	self.statusicon = "hud_status_dead";
	self.pers["team"] = assignment;
	self.pers["weapon"] = undefined;
	self.pers["weapon1"] = undefined;
	self.pers["weapon2"] = undefined;
	self.pers["savedmodel"] = undefined;

	self notify("joined", assignment);
	self notify("joined_allies_axis");

	level notify("joined", assignment, self); // used in first round to check if someone joined team
}

menuAllies()
{
	// If team is already allies or we cannot join allies (to keep team balance), open team menu again
	if(self.pers["team"] == "allies" || !maps\mp\gametypes\_teams::getJoinTeamPermissions("allies"))
	{
		return;
	}

	self.joining_team = "allies";
	self.leaving_team = self.pers["team"];

	if(self.sessionstate == "playing")
	{
		self.switching_teams = true;
		self suicide();
	}

	self.sessionteam = "allies";
	self.statusicon = "hud_status_dead";
	self.pers["team"] = "allies";
	self.pers["weapon"] = undefined;
	self.pers["weapon1"] = undefined;
	self.pers["weapon2"] = undefined;
	self.pers["savedmodel"] = undefined;


	self notify("joined", "allies");
	self notify("joined_allies_axis");

	level notify("joined", "allies", self); // used in first round to check if someone joined team
}

menuAxis()
{
	// If team is already axis or we cannot join axis (to keep team balance), open team menu again
	if(self.pers["team"] == "axis" || !maps\mp\gametypes\_teams::getJoinTeamPermissions("axis"))
	{
		return;
	}

	self.joining_team = "axis";
	self.leaving_team = self.pers["team"];

	if(self.sessionstate == "playing")
	{
		self.switching_teams = true;
		self suicide();
	}

	self.sessionteam = "axis";
	self.statusicon = "hud_status_dead";
	self.pers["team"] = "axis";
	self.pers["weapon"] = undefined;
	self.pers["weapon1"] = undefined;
	self.pers["weapon2"] = undefined;
	self.pers["savedmodel"] = undefined;


	self notify("joined", "axis");
	self notify("joined_allies_axis");

	level notify("joined", "axis", self); // used in first round to check if someone joined team
}

menuSpectator()
{
	if(self.pers["team"] == "spectator")
		return;

	self.joining_team = "spectator";
	self.leaving_team = self.pers["team"];

	if(isAlive(self))
	{
		self.switching_teams = true;
		self suicide();
	}

	self.sessionteam = "spectator";
	self.statusicon = "";
	self.pers["team"] = "spectator";
	self.pers["weapon"] = undefined;
	self.pers["weapon1"] = undefined;
	self.pers["weapon2"] = undefined;
	self.pers["savedmodel"] = undefined;


	self [[level.spawnSpectator]]();

	self notify("joined", "spectator");
	self notify("joined_spectators");

	level notify("joined", "spectator", self); // used in first round to check if someone joined team
}

menuStreamer()
{
	if(self.pers["team"] == "streamer")
		return;

	self.joining_team = "streamer";
	self.leaving_team = self.pers["team"];

	if(isAlive(self))
	{
		self.switching_teams = true;
		self suicide();
	}

	self.sessionteam = "spectator";
	self.statusicon = "";
	self.pers["team"] = "streamer";
	self.pers["weapon"] = undefined;
	self.pers["weapon1"] = undefined;
	self.pers["weapon2"] = undefined;
	self.pers["savedmodel"] = undefined;


	self [[level.spawnSpectator]]();

	self notify("joined", "streamer");
	self notify("joined_streamers");

	level notify("joined", "streamer", self); // used in first round to check if someone joined team
}
