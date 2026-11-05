#include maps\mp\gametypes\global\_global;

// Functions with the same body in ctf and htf. Included by those two files:
// fix them here, not in a copy.

menuWeapon(response)
{
	// You has to be "allies" or "axis" to change a weapon
	if(self.pers["team"] != "allies" && self.pers["team"] != "axis")
		return;

	// Used by bots
	if (response == "random")
		response = self maps\mp\gametypes\_weapons::getRandomWeapon();

	// Weapon is not valid or is in use
	if(!self maps\mp\gametypes\_weapon_limiter::isWeaponAvailable(response))
	{
		// Open menu with weapons again
		if(self.pers["team"] == "allies")
			self openMenu(game["menu_weapon_allies"]);
		else if(self.pers["team"] == "axis")
			self openMenu(game["menu_weapon_axis"]);
		return;
	}

	weapon = response;



	// After selecting a weapon, show "ingame" menu when ESC is pressed
	self setClientCvar2("g_scriptMainMenu", game["menu_ingame"]);

	// If new selected weapon is same as actualy selected weapon, do nothing
	if(isdefined(self.pers["weapon"]) && self.pers["weapon"] == weapon)
	{
		self switchToWeapon(weapon);
		return;
	}

	// Save weapon before change (used in weapon_limiter)
	leavedWeapon = undefined;
	leavedWeaponFromTeam = undefined;
	if (isDefined(self.pers["weapon"]))
	{
		leavedWeapon = self.pers["weapon"];
		leavedWeaponFromTeam = self.pers["team"];
	}

	// Readyup-mode
	if (level.in_readyup && !level.in_timeout)
	{
		if(isDefined(self.pers["weapon"]))
		{
			self.pers["weapon"] = weapon;

			// Remove weapon from slot (can be "none", takeWeapon() will take it)
			self takeWeapon(self getWeaponSlotWeapon("primary"));
			self takeWeapon(self getWeaponSlotWeapon("primaryb"));

			// Give weapon to primary slot
			self setWeaponSlotWeapon("primary", weapon);
			self giveMaxAmmo(weapon);

			// Give pistol to secondary slot + give grenades and smokes
			maps\mp\gametypes\_weapons::givePistol();
			maps\mp\gametypes\_weapons::giveSmokesFor(weapon, 0);
			maps\mp\gametypes\_weapons::giveGrenadesFor(weapon, 0);

			// Switch to main weapon
			self switchToWeapon(weapon);
		}
		else
		{
			self.pers["weapon"] = weapon;

			self [[level.spawnPlayer]]();
		}
	}
	else
	{
		if(isDefined(self.pers["weapon"]))
		{
			self.pers["weapon"] = weapon;

			weaponname = maps\mp\gametypes\_weapons::getWeaponName(self.pers["weapon"]);

			if(maps\mp\gametypes\_weapons::useAn(self.pers["weapon"]))
				self iprintln(&"MP_YOU_WILL_RESPAWN_WITH_AN", weaponname);
			else
				self iprintln(&"MP_YOU_WILL_RESPAWN_WITH_A", weaponname);
		}
		else
		{
			self.pers["weapon"] = weapon;

			if(isDefined(self.respawnAt) && getTime() < self.respawnAt)
				self thread respawn_wait_remaining();
			else
				self [[level.spawnPlayer]]();
		}
	}


	// Used in wepoan_limiter
	self notify("weapon_changed", weapon, leavedWeapon, leavedWeaponFromTeam);
}

respawn_wait_remaining()
{
	self endon("disconnect");
	self notify("end_respawn_wait");
	self endon("end_respawn_wait");

	remaining = int((self.respawnAt - getTime()) / 1000) + 1;
	self iprintln("You will respawn in " + remaining + " seconds.");
	wait level.fps_multiplier * (self.respawnAt - getTime()) / 1000;

	while(level.in_timeout)
		wait level.fps_multiplier * 1;

	if(isDefined(self.pers["weapon"]) && self.sessionstate != "playing")
		self thread [[level.spawnPlayer]]();
}

endMap()
{
	alliedscore = getTeamScore("allies");
	axisscore = getTeamScore("axis");

	if(alliedscore == axisscore)
	{
		winningteam = "tie";
		losingteam = "tie";
		text = &"MP_THE_GAME_IS_A_TIE";
	}
	else if(alliedscore > axisscore)
	{
		winningteam = "allies";
		losingteam = "axis";
		text = &"MP_ALLIES_WIN";
	}
	else
	{
		winningteam = "axis";
		losingteam = "allies";
		text = &"MP_AXIS_WIN";
	}

	winners = "";
	losers = "";

	if(winningteam == "allies")
		level thread playSoundOnPlayers("MP_announcer_allies_win");
	else if(winningteam == "axis")
		level thread playSoundOnPlayers("MP_announcer_axis_win");
	else
		level thread playSoundOnPlayers("MP_announcer_round_draw");

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		player closeMenu();
		player closeInGameMenu();
		player setClientCvar("cg_objectiveText", text);
	}


	level thread maps\mp\gametypes\_end_of_map::Do_Map_End();
}

playSoundOnPlayers(sound, team, streamersound)
{
	players = getentarray("player", "classname");

	if(isdefined(team))
	{
		for(i = 0; i < players.size; i++)
		{
			if(isdefined(players[i].pers["team"]) && players[i].pers["team"] == team)
				players[i] playLocalSound(sound);

			if(isdefined(streamersound) && isdefined(players[i].pers["team"]) && players[i].pers["team"] == "streamer")
			{
				players[i] playLocalSound(sound);
			}
		}
	}
	else
	{
		for(i = 0; i < players.size; i++)
			players[i] playLocalSound(sound);
	}

}

checkScoreLimit()
{
	waittillframeend;
	if(level.mapended) return;

	// Is it a score-based Halftime?
	if(level.halftime_enabled && !game["is_halftime"] && level.halfscore != 0)
	{
		if(game["half_1_allies_score"] >= level.halfscore || game["half_1_axis_score"] >= level.halfscore)
		{
			level.mapended = true;
			level thread maps\mp\gametypes\_halftime::Do_Half_Time();
			return true;
		}
	}


	/* Match Score Check */
	if (level.scorelimit > 0)
	{
		if(game["allies_score"] < level.scorelimit && game["axis_score"] < level.scorelimit)
			return;

		iprintln(&"MP_SCORE_LIMIT_REACHED");

		level.mapended = true;
		thread endMap();
	}
}
