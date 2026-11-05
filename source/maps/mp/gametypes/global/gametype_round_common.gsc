#include maps\mp\gametypes\global\_global;

// Round functions with the same body in sd and re. Included by those two
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

		wait level.fps_multiplier * 1;
	}
}

announceWinner(winner, delay)
{
	wait level.fps_multiplier * delay;

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
