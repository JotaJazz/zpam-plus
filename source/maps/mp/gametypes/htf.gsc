#include maps\mp\gametypes\global\_global;
#include maps\mp\gametypes\global\gametype_common;
#include maps\mp\gametypes\global\gametype_respawn_common;
#include maps\mp\gametypes\global\gametype_team_common;
#include maps\mp\gametypes\global\gametype_flag_common;

main()
{
	// Initialize global systems (scripts for events, cvars, hud, player...)
	InitSystems();


	// Register events that should be caught
	addEventListener("onStartGameType", ::onStartGameType);
	addEventListener("onConnecting", ::onConnecting);
	addEventListener("onConnected", ::onConnected);
	addEventListener("onDisconnect", ::onDisconnect);
	addEventListener("onPlayerDamaging", ::onPlayerDamaging);
	addEventListener("onPlayerDamaged", ::onPlayerDamaged);
	addEventListener("onPlayerKilling", ::onPlayerKilling);
	addEventListener("onPlayerKilled", ::onPlayerKilled);
	addEventListener("onCvarChanged", ::onCvarChanged);

	// Events for this gametype that are called last after all events are processed
	level.onAfterConnected = ::onAfterConnected;
	level.onAfterPlayerDamaged = ::onAfterPlayerDamaged;
	level.onAfterPlayerKilled = ::onAfterPlayerKilled;

	// Same functions across gametypes
	level.autoassign = ::menuAutoAssign;
	level.allies = ::menuAllies;
	level.axis = ::menuAxis;
	level.spectator = ::menuSpectator;
	level.streamer = ::menuStreamer;
	level.weapon = ::menuWeapon;

	level.spawnPlayer = ::spawnPlayer;
	level.spawnSpectator = ::spawnSpectator;
	level.spawnIntermission = ::spawnIntermission;


	// Define gametype specific cvars here
	// Default values of these variables are overwrited by rules
	// Event onCvarChanged is called on every cvar registration
	// Make sure that onCvarChanged event is added first before cvar registration
	registerCvarEx("C", "scr_htf_timelimit", "FLOAT", 0, 0, 99999);
	registerCvarEx("C", "scr_htf_half_score", "INT", 0, 0, 99999);
	registerCvarEx("C", "scr_htf_end_score", "INT", 0, 0, 99999);
	registerCvarEx("C", "scr_htf_halftime", "BOOL", 0);

	registerCvar("scr_htf_strat_time", "INT", 5, 0, 10);
	registerCvar("scr_htf_respawn_time",  "INT", 7, 0, 60);
	registerCvar("scr_htf_flag_spawndelay", "INT", 15, 0, 300);
	registerCvar("scr_htf_flag_autoreturn", "INT", 115, 0, 180);
	registerCvar("scr_htf_objective_points", "BOOL", 1);




	// Init all shared modules in this pam (scripts with underscore)
	InitModules();
}


// This function is called when cvar changes value.
// Is also called when cvar is registered
// Return true if cvar was handled here, otherwise false
onCvarChanged(cvar, value, isRegisterTime)
{
	// Server info update
	if (!isRegisterTime && !game["firstInit"] && !isDefined(game["cvars"][cvar]["inQuiet"]) && cvar != "pam_mode_custom")
	{
		thread serverInfo();
	}

	switch(cvar)
	{
		case "scr_htf_timelimit": 	level.timelimit = value; 	return true;
		case "scr_htf_half_score": 	level.halfscore = value; 	return true;
		case "scr_htf_end_score": 	level.scorelimit = value; 	return true;

		case "scr_htf_halftime": 		level.halftime_enabled = value; return true;
		case "scr_htf_strat_time": 		level.strat_time = value; return true;

		case "scr_htf_respawn_time": 		level.respawndelay = value; return true;
		case "scr_htf_flag_spawndelay": 	level.flagspawndelay = value; return true;
		case "scr_htf_flag_autoreturn": 	level.flagautoreturn = value; return true;
		case "scr_htf_objective_points": 	level.show_objective_points = value; return true;
	}
	return false;
}




// Precache specific stuff for this gametype
// Is called only once per map
precache()
{
	precacheStatusIcon(level.hudflag_allies);
	precacheStatusIcon(level.hudflag_axis);
	precacheStatusIcon("compassping_enemyfiring"); // for streamers
	precacheShader(level.compassflag_allies);
	precacheShader(level.compassflag_axis);
	precacheShader(level.compassflag_none);
	precacheShader(level.objpointflag_allies);
	precacheShader(level.objpointflag_axis);
	precacheShader(level.objpointflag_none);
	precacheShader(level.hudflag_allies);
	precacheShader(level.hudflag_axis);

	precacheRumble("damage_heavy");
	precacheModel("xmodel/prop_flag_base");
	precacheModel("xmodel/prop_flag_" + game["allies"]);
	precacheModel("xmodel/prop_flag_" + game["axis"]);
	precacheModel("xmodel/prop_flag_" + game["allies"] + "_carry");
	precacheModel("xmodel/prop_flag_" + game["axis"] + "_carry");
	precacheString(&"MP_TIME_TILL_SPAWN");
	precacheString(&"MP_CTF_OBJ_TEXT");
	precacheString(&"PLATFORM_PRESS_TO_SPAWN");

	// HUD: Strattime
	precacheString2("STRING_STRAT_TIME", &"Strat Time");
}



// Called after the <gametype>.gsc::main() and <map>.gsc::main() scripts are called
// At this point game specific variables are defined (like game["allies"], game["axis"], game["american_soldiertype"], ...)
// Called again for every round in round-based gameplay
onStartGameType()
{
	if(game["firstInit"])
	{
		// defaults if not defined in level script
		if(!isdefined(game["allies"]))
			game["allies"] = "american";
		if(!isdefined(game["axis"]))
			game["axis"] = "german";

		// Other variables
		game["state"] = "playing";

		game["allies_score"] = 0;
		game["axis_score"] = 0;
		game["half_1_allies_score"] = 0;
		game["half_1_axis_score"] = 0;
		game["half_2_allies_score"] = 0;
		game["half_2_axis_score"] = 0;

	}

	// Main scores
	setTeamScore("allies", game["allies_score"]);
	setTeamScore("axis", game["axis_score"]);


	// Gametype specific variables
	level.mapended = false;
	level.matchstarted = false;
	level.teamholdtime["axis"] = 0;
	level.teamholdtime["allies"] = 0;
	level.oldteamholdtime["allies"] = level.teamholdtime["allies"];
	level.oldteamholdtime["axis"] = level.teamholdtime["axis"];
	level.compassflag_allies = "compass_flag_" + game["allies"];
	level.compassflag_axis = "compass_flag_" + game["axis"];
	level.compassflag_none	= "objective";
	level.objpointflag_allies = "objpoint_flag_" + game["allies"];
	level.objpointflag_axis = "objpoint_flag_" + game["axis"];
	level.objpointflag_none = "objpoint_star";
	level.hudflag_allies = "compass_flag_" + game["allies"];
	level.hudflag_axis = "compass_flag_" + game["axis"];
	level.team["allies"] = 0;
	level.team["axis"] = 0;
	level.hasspawned["axis"] = false;
	level.hasspawned["allies"] = false;
	level.hasspawned["flag"] = false;
	level.barlength = 170;



	// Precache gametype specific stuff
	if (game["firstInit"])
		precache();




	spawnpointname = "mp_tdm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");
	if(!spawnpoints.size)
	{
		maps\mp\gametypes\_callbacksetup::AbortLevel();
		return;
	}
	for(i = 0; i < spawnpoints.size; i++)
		spawnpoints[i] placeSpawnpoint();

	allowed[0] = "tdm";
	maps\mp\gametypes\_gameobjects::main(allowed);


	if(!isDefined(game["state"]))
		game["state"] = "playing";



	minefields = [];
	minefields = getentarray("minefield", "targetname");
	trigger_hurts = [];
	trigger_hurts = getentarray("trigger_hurt", "classname");

	level.flag_returners = minefields;
	for(i = 0; i < trigger_hurts.size; i++)
		level.flag_returners[level.flag_returners.size] = trigger_hurts[i];


	setClientNameMode("auto_change");

	thread serverInfo();


	// Wait here untill there is atleast one player connected
	if (game["firstInit"])
	{
		for(;;)
		{
			players = getentarray("player", "classname");
			if (players.size > 0)
				break;
			wait 1;
		}

		// For public mode, wait untill most of player connect
		if (game["is_public_mode"])
		{
			for(;;)
			{
				allies = 0;
				axis = 0;

				players = getentarray("player", "classname");
				for(i = 0; i < players.size; i++)
				{
					if (players[i].pers["team"] == "allies")
						allies++;
					else if (players[i].pers["team"] == "axis")
						axis++;
				}

				if (allies > 0 && axis > 0)
				{
					iprintln("Match is starting");

					wait 8;

					if (!level.pam_mode_change)
						map_restart(true);

					break;
				}

				wait 3;
			}
		}
	}




	if (!level.in_readyup)
	{
		thread startGame();
	}

}







/*================
Called when a player begins connecting to the server.
Called again for every map change or tournement restart.

Return undefined if the client should be allowed, otherwise return
a string with the reason for denial.

Otherwise, the client will be sent the current gamestate
and will eventually get to ClientBegin.

firstTime will be qtrue the very first time a client connects
to the server machine, but qfalse on map changes and tournement
restarts.
================*/
onConnecting()
{
	self.statusicon = "hud_status_connecting";
}

/*
Called when player is fully connected to game
*/
onConnected()
{
	self.statusicon = "";

	// Variables in self.pers[] stay defined after scriped map restart
	// Other like self.ownvariable will be undefined after scriped map restart
	// Except a few special vars, like self.sessionteam, their are defined after map restart, but with default value

	// If is players first connect, his team is undefined
	if (!isDefined(self.pers["team"]))
	{
		// Show player in spectator team
		// If mod is not downloaded or blackout is needed to show, player is moved to none team in another script
		self.pers["team"] = "none";
		self.sessionteam = "none";

		// Print "<NAME> Connected" to all
		iprintln(&"MP_CONNECTED", self.name);
	}
	else
	{
		// If is team selected from last round, set the real team variable
		team = self.pers["team"];
		if (team == "streamer")
			team = "spectator";
		self.sessionteam = team;
	}

	// Define default variables specific for this gametype

	// Set score and deaths
	if(!isdefined(self.pers["score"]))
		self.pers["score"] = 0;
	self.score = self.pers["score"];

	if(!isdefined(self.pers["deaths"]))
		self.pers["deaths"] = 0;
	self.deaths = self.pers["deaths"];


	self thread checkFlag();
}


/*================
Called when a player drops from the server.
Will not be called between levels.
self is the player that is disconnecting.
================*/
onDisconnect()
{
	self dropFlag();

	iprintln(&"MP_DISCONNECTED", self.name);
}


onPlayerDamaging(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	// In readyup there is own onPlayerDamaging function
	if (level.in_readyup)
		return false;

	// Prevent damage when:
	if (!level.matchstarted || level.in_strattime || level.mapended)
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

// Called as last funtction after all onPlayerKilled events are processed
onAfterPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	self endon("disconnect");
	self endon("spawned");

	self dropFlag();

	// Kill is handled in readyup functions
	if (level.in_readyup)
		return;

	// send out an obituary message to all clients about the kill
	obituary(self, attacker, sWeapon, sMeansOfDeath);

	// Weapon/Nade Drops
	if (!isDefined(self.switching_teams) && level.matchstarted && !level.mapended)
		self thread maps\mp\gametypes\_weapons::dropWeapons();

	self.sessionstate = "dead";
	self.statusicon = "hud_status_dead";

	if(!isdefined(self.switching_teams))
	{
		self.pers["deaths"]++;
		self.deaths = self.pers["deaths"];
	}

	doKillcam = false;
	attackerNum = -1;
	if(isPlayer(attacker))
	{
		if(attacker == self) // killed himself
		{
			doKillcam = false;
		}
		else
		{
			doKillcam = true;
			attackerNum = attacker getEntityNumber();

			if(self.pers["team"] == attacker.pers["team"]) // killed by a friendly
			{
				attacker.pers["score"]--;
				attacker.score = attacker.pers["score"];
			}
			else
			{
				attacker.pers["score"]++;
				attacker.score = attacker.pers["score"];
			}
		}
	}
	else // If you weren't killed by a player, you were in the wrong place at the wrong time
	{
		doKillcam = false;

		self.pers["score"]--;
		self.score = self.pers["score"];
	}



	self notify("killed_player");

	level notify("log_kill", self, attacker,  sWeapon, iDamage, sMeansOfDeath, sHitLoc);

	// Wait before dead body is spawned to allow double kills (bullets may stop in this dead body)
	// Ignore this for shotgun, because it create a smoke effect on dead body (for good feeling)
	if (sWeapon != "shotgun_mp")
		waittillframeend;

	// Stop thread if map ended on this death
	if(level.mapended)
		return;

	body = undefined;
	if(!isdefined(self.switching_teams))
	{
		body = self cloneplayer(deathAnimDuration);
		self.respawnAt = getTime() + (level.respawndelay + 1.5) * 1000;
	}
	self.switching_teams = undefined;

	delay = 1.5;
	wait delay;

	// Handle respawn of player
	self thread respawn();

	// Do killcam - if enabled, wait here until killcam is done
	if(doKillcam && level.scr_killcam)
		self maps\mp\gametypes\_killcam::killcam(attackerNum, 4, 5, psOffsetTime, true);

	// Spawn from "dead" player session to spectator
	self.sessionstate = "spectator";
	self spawn(self.origin + (0, 0, 60), self.angles);
}


respawn()
{
	self endon("disconnect");

	self.WaitingOnTimer = true;

	if(level.respawndelay > 0)
	{
		// This thread is already running
		if(isDefined(self.respawntimer))
			return;

		self.respawntimer = newClientHudElem(self);
		self.respawntimer.x = 0;
		self.respawntimer.y = -50;
		self.respawntimer.alignX = "center";
		self.respawntimer.alignY = "middle";
		self.respawntimer.horzAlign = "center_safearea";
		self.respawntimer.vertAlign = "center_safearea";
		self.respawntimer.alpha = 1;
		self.respawntimer.archived = false;
		self.respawntimer.font = "default";
		self.respawntimer.fontscale = 2;
		self.respawntimer.label = (&"MP_TIME_TILL_SPAWN");
		self.respawntimer setTimer(level.respawndelay);


		self thread respawn_timer();
		self thread respawn_spawned();

		// Respawn is ended when time elapsed or player spawned other way
		self waittill("end_respawn");

		if(isdefined(self.respawntimer))
			self.respawntimer destroy();
	}

	self.WaitingOnTimer = undefined;

	if(isDefined(self.pers["weapon"]) && self.sessionstate != "playing")
		self thread spawnPlayer();
}

respawn_timer()
{
	self endon("disconnect");
	self endon("spawned");

	wait level.respawndelay;

	while(level.in_timeout)
		wait 1;

	self notify("end_respawn");
}

respawn_spawned()
{
	self endon("disconnect");

	self waittill("spawned");

	self notify("end_respawn");
}



spawnPlayer()
{
	// Resets the infinite loop check timer, to prevent an incorrect infinite loop error when a lot of script must be run
	resettimeout();

	if (game["state"] == "intermission")
		return;

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");


	self.sessionteam = self.pers["team"];
	self.sessionstate = "playing";
	self.statusicon = "";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.maxhealth = 100;
	self.health = self.maxhealth;


	// Spawn where player dies
	if (isDefined(self.spawnOrigin))
	{
		self spawn(self.spawnOrigin, self.spawnAngles);

		self.spawnOrigin = undefined;
		self.spawnAngles = undefined;
	}
	else
	{
		spawnpointname = "mp_tdm_spawn";
		spawnpoints = getentarray(spawnpointname, "classname");

		if (level.in_readyup || !level.matchstarted)
		{
			spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam(spawnpoints);
		}
		// First player of each team spawn on specific teamside
		else if(!level.hasspawned[self.sessionteam])
		{
			spawnpoint = NearestSpawnpoint(spawnpoints, level.teamside[self.sessionteam]);
			level.hasspawned[self.sessionteam] = true;
		}
		else
		{
			// Else use TDM spawnlogic
			spawnpoint = getSpawnpoint(spawnpoints);
		}

		if(isDefined(spawnpoint))
			self spawn(spawnpoint.origin, spawnpoint.angles);
		else
			maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
	}


	if(!isdefined(self.pers["savedmodel"]))
		maps\mp\gametypes\_teams::model();
	else
		maps\mp\_utility::loadModel(self.pers["savedmodel"]);



	// Give weapon
	self setWeaponSlotWeapon("primary", self.pers["weapon"]);
	self giveMaxAmmo(self.pers["weapon"]);
	self setSpawnWeapon(self.pers["weapon"]);

	if (level.in_readyup && !level.in_timeout)
	{
		maps\mp\gametypes\_weapons::giveSmokesFor(self.pers["weapon"], 0);
		maps\mp\gametypes\_weapons::giveGrenadesFor(self.pers["weapon"], 0); // grenades are handled in readyup now
	} else {
		maps\mp\gametypes\_weapons::giveSmokesFor(self.pers["weapon"]);
		maps\mp\gametypes\_weapons::giveGrenadesFor(self.pers["weapon"]);
	}
	maps\mp\gametypes\_weapons::givePistol();
	maps\mp\gametypes\_weapons::giveBinoculars();


	// Notify "spawned" notifications
	self notify("spawned");
	self notify("spawned_player");

}

spawnSpectator(origin, angles)
{
	// Resets the infinite loop check timer, to prevent an incorrect infinite loop error when a lot of script must be run
	resettimeout();

	// Stop shellshock and rumble
	self stopShellshock();
	self stoprumble("damage_heavy");

	self dropFlag();

	self.sessionstate = "spectator";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;

	if(self.pers["team"] == "spectator")
		self.statusicon = "";
	else if(self.pers["team"] == "streamer")
		self.statusicon = "compassping_enemyfiring"; // recording icon
	else if (self.pers["team"] == "allies" || self.pers["team"] == "axis") // dead team spectartor
		self.statusicon = "hud_status_dead";


	if(isdefined(origin) && isdefined(angles))
		self spawn(origin, angles);

	else if(self.pers["team"] == "streamer")
	{
		// Spawn is handled in streamer system
	}
	else
	{
 		spawnpointname = "mp_global_intermission";
		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

		if(isdefined(spawnpoint))
			self spawn(spawnpoint.origin, spawnpoint.angles);
		else
		{
			self spawn((0,0,0), (0,0,0));
			maps\mp\_utility::error("NO " + spawnpointname + " SPAWNPOINTS IN MAP");
		}
	}

	// Notify "spawned" notifications
	self notify("spawned");

	// If is real spectator (is in team spectator, not session state spectator)
	if (self.pers["team"] == "spectator")
	{
		self notify("spawned_spectator");
	}
	else if (self.pers["team"] == "streamer")
	{
		self notify("spawned_streamer");
	}
}



startGame()
{
	level.in_strattime = false;
	level.first_flag_spawn = false;

	pickSpawnpoint();
	InitFlags();

	// Show name of league + pam version
	thread maps\mp\gametypes\_pam::PAM_Header();

	// Do strat time if is enabled
	if (level.strat_time > 0)
	{
		level.in_strattime = true;

		// Disable players movement
		level thread stratTime_g_speed();

		// Show HUD stuff...
		thread HUD_StratTime(level.strat_time);

		// End strattime when time expires or timeout is called
		level thread strattime_end_timer(level.strat_time);
		level thread strattime_end_ontimeout();

		level waittill("strat_time_end");

		// Out of strat time
		level.in_strattime = false;
	}

	// Hide pam info hud
	if (!level.in_timeout)
		thread maps\mp\gametypes\_pam::PAM_Header_Delete();


	level.matchstarted = true;
	level.starttime = getTime();


	level thread checkScoreProgress();


	objective_icon(0, level.flag.compassflag);
	objective_icon(1, level.flag.compassflag);

	objective_team(0, "allies");
	objective_team(1, "axis");


	checkonhalftime();


	if(level.timelimit > 0)
	{
		level.clock = newHudElem2();
		level.clock.font = "default";
		level.clock.fontscale = 2;
		level.clock.horzAlign = "center_safearea";
		level.clock.vertAlign = "top";
		level.clock.alignX = "center";
		level.clock.alignY = "top";
		level.clock.color = (1, 1, 1);
		level.clock.x = 0;
		level.clock.y = 445;
		level.clock setTimer(level.timelimit * 60);

		// If strattime is enabled, show fade-in animation
		if (level.strat_time > 0 && !level.in_timeout)
		{
			level.clock.alpha = 0;

			level.clock FadeOverTime(0.5);
			level.clock.alpha = 1;

			level.clock.x = 40;
			level.clock moveovertime(0.5);
			level.clock.x = 0;
		}

		time_before_timeout = 0;
		for(;;)
		{
			// CheckTimeLimit
			timepassed = (getTime() - level.starttime) / 1000;	// elapsed time in seconds
			timepassed = timepassed - level.timeout_elapsedTime;	// exclude time of timeout

			//iprintln(timepassed);

			// Freeze time if in timeout
			if (level.in_timeout)
			{
				if (time_before_timeout == 0)
					time_before_timeout = level.timelimit * 60 - timepassed;

				level.clock setTimer(int(time_before_timeout) + 0.9);
				level.clock.color = (1, 0.6, 0.15);	// Orange
			}
			else if (time_before_timeout != 0)
			{
				time_before_timeout = 0;
				level.clock.color = (1, 1, 1);
			}

			// Time elapsed
			if (!level.in_timeout && timepassed >= level.timelimit * 60)
			{
				if(level.mapended) return;
				level.mapended = true;

				iprintln(&"MP_TIME_LIMIT_REACHED");

				if (level.halftime_enabled && !game["is_halftime"])
				{
					thread maps\mp\gametypes\_halftime::Do_Half_Time();
				}
				else
				{
					level thread endMap();
				}
			}


			wait .5;
		}
	}
}


checkScoreProgress()
{
	while (!level.mapended)
	{
		wait 1.00;

		if (level.in_timeout)
			continue;

		if(level.flag.team == "allies")
		{
			friends = "allies";
			enemies = "axis";
		}
		else
		{
			friends = "axis";
			enemies = "allies";
		}


		if(level.flag.stolen)
		{
			level.teamholdtime[friends]++;

			if (friends == "allies")
			{
				if (game["is_halftime"])
					game["half_2_allies_score"]++;
				else
					game["half_1_allies_score"]++;

				game["allies_score"]++;
			}
			else
			{
				if (game["is_halftime"])
					game["half_2_axis_score"]++;
				else
					game["half_1_axis_score"]++;

				game["axis_score"]++;
			}

			// Set Score
			setTeamScore("allies", game["allies_score"]);
			setTeamScore("axis", game["axis_score"]);


			// Update score
			level maps\mp\gametypes\_hud_teamscore::updateScore();

			checkScoreLimit();
		}
	}
}



checkFlag()
{
	self endon("disconnect");

	wasDead = false;
	oldorigin = undefined;

	while (1)
	{
		while (!isAlive(self) || self.sessionstate != "playing")
		{
			wasDead = true;
			wait .1;
		}

		while (!level.matchstarted)
			wait level.frame;


		while (level.in_timeout)
			wait 1;


		if (wasDead)
		{
			wasDead = false;

			self.flag = undefined;
			oldorigin = self.origin;
		}

		// What is my team?
		myteam = self.sessionteam;
		if(myteam == "allies")
			otherteam = "axis";
		else
			otherteam = "allies";

		// Does the flag exist and is not currently being stolen?
		if(!level.flag.stolen)
		{
			// Am I touching it and it is not currently being stolen?
			if(self isTouchingFlag() && !level.flag.stolen)
			{
				level.flag.stolen = true;
				level.flag.team = myteam;

				// Steal flag
				self pickupFlag(level.flag);

				oldorigin = self.origin;

				if(level.flag.lastteam != myteam)
				{
					if(myteam == "allies")
						iprintLn(&"HTF_PICKUPFLAGALLIES");
					else
						iprintLn(&"HTF_PICKUPFLAGAXIS");

					// Get personal score
					self.pers["score"] += 2;
					self.score = self.pers["score"];
				}
				else
				{
					if(myteam == "allies")
						iprintLn(&"HTF_RECLAIMEDFLAGALLIES");
					else
						iprintLn(&"HTF_RECLAIMEDFLAGAXIS");
				}

				level.flag.lastteam = level.flag.team;
			}
		}

		// Update objective on compass
		if(isdefined(self.flag))
		{
			wait 0.05;

			// Make sure flag still exist
			if(isdefined(self.flag))
			{
				// Update the other teams objective (lags 1 second behind)

				oldorigin = self.origin;

				if(level.scorelimit > 0 && level.teamholdtime[myteam] >= level.scorelimit)
				{
					friendlyAlias = "ctf_touchcapture";
					enemyAlias = "ctf_enemy_touchcapture";

					level.teamholdtime[myteam] = 0;
					level.teamholdtime[otherteam] = 0;

					level.flag.stolen = false;

					// Detach flag
					self detachFlag(level.flag);

					thread playSoundOnPlayers(friendlyAlias, myteam);
					thread playSoundOnPlayers(enemyAlias, otherteam, 1);

					// Clear flags
					self.flag = undefined;
				}

				updatehud();
			}
		}
		else
			wait 0.2;
	}
}


pickupFlag(flag)
{
	flag notify("end_autoreturn");

	// What is my team?
	myteam = self.sessionteam;
	if(myteam == "allies")
		otherteam = "axis";
	else
		otherteam = "allies";


	flag.origin = flag.origin + (0, 0, -10000);
	flag.flagmodel hide();
	flag.flagmodel setmodel("xmodel/prop_flag_" + game[myteam]);
	flag.access = false;
	flag.atbase = false;
	flag.team = self.sessionteam;
	flag.occupation = self.origin;
	flag deleteFlagWaypoint();
	self.flag = flag;
	self.dont_auto_balance = true;

	objective_delete(0);
	objective_delete(1);


	if(myteam == "allies")
	{
		flag.compassflag = level.compassflag_allies;
		flag.objpointflag = level.objpointflag_allies;
	}
	else
	{
		flag.compassflag = level.compassflag_axis;
		flag.objpointflag = level.objpointflag_axis;
	}

	// Make an identical objective but for the other team
	objective_add(0, "current", self.origin, flag.compassflag);
	objective_add(1, "current", self.origin, flag.compassflag);

	objective_icon(0, flag.compassflag);
	objective_icon(1, flag.compassflag);

	objective_onEntity(0, self);
	objective_onEntity(1, self);

	self attachFlag();

	friendlyAlias = "ctf_enemy_touchenemy";
	enemyAlias = "ctf_touchenemy";

	thread playSoundOnPlayers(friendlyAlias, myteam);
	thread playSoundOnPlayers(enemyAlias, otherteam, 1);
}

dropFlag()
{
	if(isdefined(self.flag))
	{
		start = self.origin + (0, 0, 10);
		end = start + (0, 0, -2000);
		trace = bulletTrace(start, end, false, undefined);

		level.flag.origin = trace["position"];
		level.flag.flagmodel.origin = level.flag.origin;
		level.flag.flagmodel show();
		level.flag.atbase = false;
		level.flag.stolen = false;
		level.flag.access = true;
		level.flag thread autoReturn();
		level.flag createFlagWaypoint();

		// set compass flag position on player
		objective_position(0, level.flag.origin);
		objective_position(1, level.flag.origin);


		//check if it's in a flag_returner
		for(i = 0; i < level.flag_returners.size; i++)
		{
			if(level.flag.flagmodel istouching(level.flag_returners[i]))
			{
				level.flag thread returnFlag();
				break;
			}
		}

		self detachFlag(level.flag);

		iprintln(&"HTF_DROPPEDFLAG");
		level thread playSoundOnPlayers("ctf_touchown");

		self.flag = undefined;
		self.dont_auto_balance = undefined;
	}
}

returnFlag()
{
	self notify("end_autoreturn");
	self.access = false;
	self.flagmodel hide();

	self deleteFlagWaypoint();

	objective_delete(0);
	objective_delete(1);

	if(!level.hasspawned["flag"])
	{
		self.origin = self.home_origin;
 		self.flagmodel.origin = self.home_origin;
	 	self.flagmodel.angles = self.home_angles;
		level.hasspawned["flag"] = true;
	}
	else
	{
		spawnpointname = "mp_tdm_spawn";
		spawnpoints = getentarray(spawnpointname, "classname");
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);
		self.origin = spawnpoint.origin;
		self.occupation = spawnpoint.origin;
 		self.flagmodel.origin = spawnpoint.origin;
	 	self.flagmodel.angles = spawnpoint.angles;
		self.basemodel.origin = spawnpoint.origin;
	 	self.basemodel.angles = spawnpoint.angles;
	}

	wait 1;

	// Do not spawn flag unless there are alive players in both teams
	while( !(alivePlayers("allies") && alivePlayers("axis")) )
		wait 0.05;

	// Do not spawn flag unless there are strattime / timeout
	while (level.in_timeout || level.in_strattime)
		wait 1;


	if(!level.first_flag_spawn)
	{
		level.first_flag_spawn = true;
		iprintln(&"HTF_FLAGRESPAWN", level.flagspawndelay);
	}

	// Wait a specific time and consider timeout and strat time pause
	time = 0;
	for(;;)
	{
		if (!level.in_timeout && !level.in_strattime)
			time += 1;
		if (time >= level.flagspawndelay)
			break;

		wait 1;
	}


	self.access = true;
	self.atbase = true;
	self.stolen = false;
	self.flagmodel show();
	self.compassflag = level.compassflag_none;
	self.lastteam = "none";
	self createFlagWaypoint();

	// set compass flag position on player
	objective_add(0, "current", self.origin, self.compassflag);
	objective_team(0, "allies");

	objective_add(1, "current", self.origin, self.compassflag);
	objective_team(1, "axis");

	level thread playSoundOnPlayers("explo_plant_no_tick");
}

autoReturn()
{
	if(level.flagautoreturn < 1)
		return;

	self endon("end_autoreturn");

	time = 0;
	for(;;)
	{
		wait 1;

		if (level.in_timeout)
			continue;

		time += 1;
		if (time >= level.flagautoreturn)
			break;
	}

	iprintln(&"HTF_FLAGAUTORETURN");

	wait 3;

	self thread returnFlag();
}

attachFlag()
{
	if (isdefined(self.flagAttached))
		return;

	//put icon on screen
	self.flagAttached = newClientHudElem(self);
	self.flagAttached.x = 30;
	self.flagAttached.y = 95;
	self.flagAttached.alignX = "center";
	self.flagAttached.alignY = "middle";
	self.flagAttached.horzAlign = "left";
	self.flagAttached.vertAlign = "top";

	iconSize = 40;

	if (self.pers["team"] == "allies")
	{
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";
		self.flagAttached setShader(level.hudflag_allies, iconSize, iconSize);
		self.statusicon = level.hudflag_allies;
	}
	else
	{
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
		self.flagAttached setShader(level.hudflag_axis, iconSize, iconSize);
		self.statusicon = level.hudflag_axis;
	}
	self attach(flagModel, "J_Spine4", true);
}

detachFlag(flag)
{
	if (!isdefined(self.flagAttached))
		return;

	if (flag.team == "allies")
		flagModel = "xmodel/prop_flag_" + game["allies"] + "_carry";
	else
		flagModel = "xmodel/prop_flag_" + game["axis"] + "_carry";
	self detach(flagModel, "J_Spine4");

	self.statusicon = "";
	flag.team = "none";

	self.flagAttached destroy();
}

createFlagWaypoint()
{
	if(!level.show_objective_points)
		return;

	self deleteFlagWaypoint();

	waypoint = newHudElem();
	waypoint.x = self.origin[0];
	waypoint.y = self.origin[1];
	waypoint.z = self.origin[2] + 100;
	waypoint.alpha = .61;
	waypoint.archived = true;
	waypoint setShader(self.objpointflag, 7, 7);

	waypoint setwaypoint(true);
	self.waypoint = waypoint;
}

deleteFlagWaypoint()
{
	if(!level.show_objective_points)
		return;

	if(isdefined(self.waypoint))
		self.waypoint destroy();
}


printOnTeam(text, team)
{
	//PAM
	text = self.name + text;

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		if((isdefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
			players[i] iprintln(text);
	}
}










alivePlayers(team)
{
	allplayers = getentarray("player", "classname");
	alive = [];
	for(i = 0; i < allplayers.size; i++)
	{
		if(allplayers[i].sessionstate == "playing" && allplayers[i].sessionteam == team)
			alive[alive.size] = allplayers[i];
	}
	return alive.size;
}


pickSpawnpoint()
{
	spawnpointname = "mp_tdm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");
	maxdist = 0;
	p1 = spawnpoints[0];
	p2 = spawnpoints[0];

	for (i = 0; i < spawnpoints.size; i++)
	{
		for (j = 0; j < spawnpoints.size; j++)
		{
			if(i == j) continue;
			dist = distance(spawnpoints[i].origin,spawnpoints[j].origin);

			if(dist > maxdist)
			{
				maxdist = dist;
				p1 = spawnpoints[i];
				p2 = spawnpoints[j];
			}
		}
	}

	// Save teamsides for intitial spawning
	if(randomInt(2))
	{
		level.teamside["axis"] = p1.origin;
		level.teamside["allies"] = p2.origin;
	}
	else
	{
		level.teamside["axis"] = p2.origin;
		level.teamside["allies"] = p1.origin;
	}
}


InitFlags()
{
	// Get map name
	mapname = getcvar("mapname");

	// Look for cvars
	x = getcvar("scr_htf_home_x_" + mapname);
	y = getcvar("scr_htf_home_y_" + mapname);
	z = getcvar("scr_htf_home_z_" + mapname);
	a = getcvar("scr_htf_home_a_" + mapname);

	if(x != "" && y != "" && z != "" && a != "")
	{
		position = (getCvarFloat("scr_htf_home_x_" + mapname), getCvarFloat("scr_htf_home_y_" + mapname), getCvarFloat("scr_htf_home_z_" + mapname));
		angles = (0,getCvarFloat("scr_htf_home_a_" + mapname),0);
	}
	else
	{
		// No cvars...
		flagpoint = getFlagPoint();
		position = flagpoint.origin;
		angles = flagpoint.angles;

		// Remove spawn on flag points?
		/*if(level.removeflagspawns)
		{
			spawnpointname = "mp_tdm_spawn";
			spawnpoints = getentarray(spawnpointname, "classname");
			for(i=0;i<spawnpoints.size;i++)
			{
				if(spawnpoints[i] == flagpoint)
					spawnpoints[i] delete();
			}
		}
			*/
	}

	origin = FindGround(position);

	// Spawn a script origin
	level.flag = spawn("script_origin", origin);
	level.flag.targetname = "htf_flaghome";
	level.flag.origin = origin;
	level.flag.angles = angles;
	level.flag.access = false;
	level.flag.home_origin = origin;
	level.flag.home_angles = angles;
	level.flag.occupation = undefined;

	// Spawn the flag
	level.flag.flagmodel = spawn("script_model", level.flag.home_origin);
	level.flag.flagmodel.angles = level.flag.home_angles;
	level.flag.flagmodel setmodel("xmodel/prop_flag_german");
	level.flag.flagmodel hide();

	// Spawn the flag base model
	level.flag.basemodel = spawn("script_model", level.flag.home_origin);
	level.flag.basemodel.angles = level.flag.home_angles;
	level.flag.basemodel setmodel("xmodel/prop_flag_base");

	// Set flag properties
	level.flag.team = "none";
	level.flag.atbase = false;
	level.flag.stolen = false;
	level.flag.lastteam = "none";
	level.flag.objective = 0;
	level.flag.compassflag = level.compassflag_none;
	level.flag.objpointflag = level.objpointflag_none;

	level.flag thread returnFlag();
}

getFlagPoint()
{
	p1 = level.teamside["axis"];
	p2 = level.teamside["allies"];

	// Find center
	x = p1[0] + (p2[0] - p1[0]) / 2;
	y = p1[1] + (p2[1] - p1[1]) / 2;
	z = p1[2] + (p2[2] - p1[2]) / 2;

	// Get nearest spawn
	spawnpointname = "mp_tdm_spawn";
	spawnpoints = getentarray(spawnpointname, "classname");
	flagpoint = NearestSpawnpoint(spawnpoints, (x,y,z));

	return flagpoint;
}

FindGround(position)
{
	trace = bulletTrace(position+(0, 0, 10), position+(0, 0, -1200), false, undefined);
	ground = trace["position"];
	return ground;
}


isTouchingFlag()
{
	if(distance(self.origin, level.flag.origin) < 65 && level.flag.access)
		return true;
	else
		return false;
}

updatehud()
{
	level.oldteamholdtime["allies"] = level.teamholdtime["allies"];
	level.oldteamholdtime["axis"] = level.teamholdtime["axis"];
}

checkonhalftime()
{
	if(game["is_halftime"])
	{
		level.teamholdtime["allies"] = game["allies_score"];
		level.teamholdtime["axis"] = game["axis_score"];
	}
}





// Hold the Flag spawnlogic
NearestSpawnpoint(aeSpawnpoints, vPosition)
{
	eNearestSpot = aeSpawnpoints[0];
	fNearestDist = distance(vPosition, aeSpawnpoints[0].origin);
	for(i = 1; i < aeSpawnpoints.size; i++)
	{
		fDist = distance(vPosition, aeSpawnpoints[i].origin);
		if(fDist < fNearestDist)
		{
			eNearestSpot = aeSpawnpoints[i];
			fNearestDist = fDist;
		}
	}

	return eNearestSpot;
}

getSpawnpoint(spawnpoints)
{
	// There are no valid spawnpoints in the map
	if(!isdefined(spawnpoints))
		return undefined;

	maps\mp\gametypes\_spawnlogic::Spawnlogic_Init();

	weights = maps\mp\gametypes\_spawnlogic::initWeights(spawnpoints);

	allies = maps\mp\gametypes\_spawnlogic::getAllAlliedPlayers();
	enemies = maps\mp\gametypes\_spawnlogic::getAllEnemyPlayers();
	numplayers = allies.size + enemies.size;

	if (numplayers > 0)
	{
		for (i = 0; i < spawnpoints.size; i++)
		{
			allyDistSum = 0;
			enemyDistSum = 0;
			for (j = 0; j < allies.size; j++)
			{
				dist = distance(spawnpoints[i].origin, allies[j].origin);
				allyDistSum += dist;
			}
			for (j = 0; j < enemies.size; j++)
			{
				dist = distance(spawnpoints[i].origin, enemies[j].origin);
				enemyDistSum += dist;
			}

			if(isDefined(level.flag.occupation) && spawnpoints[i].origin == level.flag.occupation)
			{
				weights[i] = -100000;
				continue;
			}

			weights[i] = (enemyDistSum - 2*allyDistSum) / numplayers; // high enemy distance is good, high ally distance is bad
		}
	}

	weights = maps\mp\gametypes\_spawnlogic::avoidSameSpawn(spawnpoints, weights);
	if (getcvar("g_gametype") != "tdm") { // retaining old logic for tdm to keep the fast pace
		weights = maps\mp\gametypes\_spawnlogic::avoidSpawnReuse(spawnpoints, weights, true);
		weights = maps\mp\gametypes\_spawnlogic::avoidDangerousSpawns(spawnpoints, weights, true);
	}

	return maps\mp\gametypes\_spawnlogic::getSpawnpoint_Final(spawnpoints, weights);
}






serverInfo()
{
	waittillframeend; // wait untill all other server change functions are processed

	title = "";
	value = "";


	if (level.timelimit > 0)
	{
		if (!level.halftime_enabled)	title +="Time limit:\n";
		else				title +="Time limit per half:\n";
		value += plural_s(level.timelimit, "minute") + "\n";
	}
	else
	{
		title +="Time limit\n";
		value += "-" + "\n";
	}


	// There is no halftime
	if (!level.halftime_enabled)
	{
		title +="Score limit:\n";
		if (level.scorelimit != 0)	value += level.scorelimit + " points\n";
		else				value += "-" + "\n";
	}
	else
	{
		title +="Score limit 1st half:\n";
		if (level.halfscore != 0) 	value += level.halfscore + " points\n";
		else				value += "-" + "\n";

		title +="Score limit 2nd half:\n";
		if (level.scorelimit != 0)	value += level.scorelimit + " points\n";
		else				value += "-" + "\n";
	}


	title += "Strat time:\n";
	value += plural_s(level.strat_time, "second") + "\n";

	title +="Respawn delay:\n";
	value += plural_s(level.respawndelay, "second") + "\n";



	level.serverinfo_left1 = title;
	level.serverinfo_left2 = value;
}
