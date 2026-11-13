#include maps\mp\gametypes\global\_global;

init()
{
	addEventListener("onCvarChanged", ::onCvarChanged);

	registerCvar("debug_shotgun", "BOOL", false);
	registerCvar("debug_spectator", "BOOL", false);
	registerCvar("debug_handhitbox", "BOOL", false);
	registerCvar("debug_torsohitbox", "BOOL", false);


	// This is called only if developer_script is set to 1
	/#
	maps\mp\gametypes\global\string::selfTest();
	maps\mp\gametypes\_teamname::teamnameSelfTest();
	maps\mp\gametypes\_ladder::ladderSelfTest();
	thread maps\mp\gametypes\_player_stat::statsSelfTest();
	thread timingSelfTest();
	thread devDuelLoop();
	addEventListener("onPlayerDamaged", ::devDuelOnDamaged);
	thread devBotsAutoReady();
	#/
}

// Runs only with developer_script 1. A wait of N lasts N real seconds.
timingSelfTest()
{
	// The first wait spans the end of the map load, so measure the second
	wait 1;
	t = getTime();
	wait 1;
	d = getTime() - t;
	if (d < 950 || d > 1050)
		assertMsg("timing selfTest: wait 1 lasted " + d + " ms");
}

// This function is called when cvar changes value.
// Is also called when cvar is registered
// Return true if cvar was handled here, otherwise false
onCvarChanged(cvar, value, isRegisterTime)
{
	switch(cvar)
	{
		case "debug_shotgun": 		level.debug_shotgun = value; return true;
		case "debug_spectator": 	level.debug_spectator = value; return true;
		case "debug_handhitbox": 	level.debug_handhitbox = value; return true;
		case "debug_torsohitbox": 	level.debug_torsohitbox = value; return true;

	}
	return false;
}


showWaypoint(player, size)
{
	origin = self.origin;
	if (isPlayer(self))
		origin = self getOrigin();

	if (!isDefined(size))
		size = 2;

	waypoint = undefined;
	if (isDefined(player))
		waypoint = newClientHudElem2(player);
	else
		waypoint = newHudElem2();

	self.waypoint = waypoint;
	self.waypoint.name = "A";
	self.waypoint.x = origin[0];
	self.waypoint.y = origin[1];
	self.waypoint.z = origin[2];
	self.waypoint.alpha = 1;
	self.waypoint.archived = false;
	if (isDefined(self.waypoint_color)) self.waypoint.color = self.waypoint_color;
	self.waypoint setShader("objpoint_default", size, size);
	self.waypoint setwaypoint(true);
	self.waypoint.scale = size;

	for (;;)
	{
		wait 0.0000001; // wait a frame
		waittillframeend;
		waittillframeend;
		waittillframeend;
		waittillframeend;

		if (!isDefined(self))
			break;

		origin = self.origin;
		if (isPlayer(self))
			origin = self getOrigin();

		if (!isDefined(self.waypoint))
			return;

		self.waypoint.x = origin[0];
		self.waypoint.y = origin[1];
		self.waypoint.z = origin[2];

		if (size != self.waypoint.scale)
		{
			size = self.waypoint.scale;
			self.waypoint setShader("objpoint_default", size, size);
		}
	}

	waypoint destroy2();
}

// developer_script 1: "rcon dev_duel <weapon> <distance> <head|torso|neck>" places a live bot in front of
// a live enemy bot at that distance, with a clear line, gives it the weapon and fires one shot.
// Weapon "mg" mounts a turret of the map instead and fires one bullet.
// Prints "DUEL done ..." with the target's health; tools/test_server.py --duel reads it.
devDuelLoop()
{
	// A command sent during a map_restart is kept and runs on the next map
	for (;;)
	{
		wait 0.25;
		cmd = getCvar("dev_duel");
		if (cmd == "")
			continue;
		setCvar("dev_duel", "");

		args = maps\mp\gametypes\global\string::splitString(cmd, " ");
		if (args.size < 3)
			println("DUEL error: usage dev_duel <weapon> <distance> <head|torso|neck>");
		else
			devDuel(args[0], int(args[1]), args[2]);
	}
}

devDuel(weapon, dist, aim)
{
	// Damage only counts in a live round (sd restarts the map when both teams first have players)
	if ((isDefined(level.roundstarted) && (!level.roundstarted || level.roundended)) ||
		(isDefined(level.in_readyup) && level.in_readyup) || (isDefined(level.in_strattime) && level.in_strattime))
	{
		println("DUEL error: round not live");
		return;
	}

	shooter = undefined;
	target = undefined;
	players = getentarray("player", "classname");
	for (i = 0; i < players.size; i++)
	{
		p = players[i];
		if (!p.pers["isBot"] || p.sessionstate != "playing")
			continue;
		if (!isDefined(shooter))
			shooter = p;
		else if (p.pers["team"] != shooter.pers["team"])
		{
			target = p;
			break;
		}
	}
	if (!isDefined(target))
	{
		println("DUEL error: needs two live bots on opposite teams");
		return;
	}

	// "mg": the shooter mounts a turret of the map and the target stands in front of it
	yaws = [];
	turret = undefined;
	if (weapon == "mg")
	{
		turrets = getentarray("misc_turret", "classname");
		mg42s = getentarray("misc_mg42", "classname"); // mp_toujane has only these
		for (i = 0; i < mg42s.size; i++)
			turrets[turrets.size] = mg42s[i];
		for (i = 0; i < turrets.size && !isDefined(turret); i++)
		{
			f = anglesToForward((0, turrets[i].angles[1], 0));
			behind = turrets[i].origin - (f[0] * 30, f[1] * 30, 0); // useTurret needs the player behind it
			shooter setOrigin(bulletTrace(behind, behind + (0, 0, -100), false, undefined)["position"]);
			shooter setPlayerAngles((0, turrets[i].angles[1], 0));
			wait level.frame; // on the ground before mounting
			if (shooter useTurret(turrets[i]))
				turret = turrets[i];
		}
		if (!isDefined(turret))
		{
			println("DUEL error: no turret the shooter can mount");
			return;
		}
		start = turret.origin + (0, 0, -60); // lines are traced at start + 60
		for (y = 0; y <= 30; y += 10)
		{
			yaws[yaws.size] = turret.angles[1] + y;
			yaws[yaws.size] = turret.angles[1] - y;
		}
	}
	else
	{
		start = shooter.origin;
		for (y = 0; y < 360; y += 30)
			yaws[yaws.size] = y;
	}

	// A direction from the shooter with nothing in the way at eye height, and the floor there
	yaw = undefined;
	for (i = 0; i < yaws.size && !isDefined(yaw); i++)
	{
		f = anglesToForward((0, yaws[i], 0));
		end = start + (f[0] * dist, f[1] * dist, 0);
		if (bulletTrace(start + (0, 0, 60), end + (0, 0, 60), false, undefined)["fraction"] == 1)
			yaw = yaws[i];
	}
	if (!isDefined(yaw))
	{
		println("DUEL error: no clear line of " + dist + " units around the shooter");
		if (weapon == "mg")
			shooter stopUseTurret();
		return;
	}
	f = anglesToForward((0, yaw, 0));
	end = start + (f[0] * dist, f[1] * dist, 0);
	floor = bulletTrace(end + (0, 0, 60), end + (0, 0, -200), false, undefined)["position"];

	target setOrigin(floor);
	target setPlayerAngles((0, yaw + 180, 0));
	target.health = target.maxhealth;
	target.devDuelHitLoc = "none";

	if (weapon != "mg")
	{
		shooter setWeaponSlotWeapon("primary", weapon);
		shooter giveMaxAmmo(weapon);
		shooter setWeaponSlotClipAmmo("primary", 999); // a new slot weapon may come with an empty clip; the game caps it
		shooter setSpawnWeapon(weapon); // a bot fires its ps->weapon; switchToWeapon does not change it
		shooter adsaim(1);
	}
	wait 1.5; // weapon raise and zoom

	if (aim == "head")
		point = target.headTag getOrigin();
	else if (aim == "neck")
	{
		tag = spawn("script_origin", (0, 0, 0));
		tag linkto(target, "J_Neck", (0, 0, 0), (0, 0, 0));
		wait level.frame;
		point = tag getOrigin() - (0, 0, 2);
		tag delete();
	}
	else
		point = target.pelvisTag getOrigin() + (0, 0, 12);
	eye = shooter getViewOrigin();
	if (weapon == "mg")
		eye = (turret.origin[0], turret.origin[1], eye[2]); // the barrel turns there, about 50 units ahead of the eye, at eye height
	angles = vectorToAngles(point - eye);
	pitch = angles[0];
	if (pitch > 180)
		pitch -= 360;
	shooter setPlayerAngles((pitch, angles[1], 0));
	wait level.frame;

	clip = shooter getWeaponSlotClipAmmo("primary");
	shooter fireweapon(1);
	if (weapon == "mg")
		wait level.frame; // one bullet
	else
		wait 0.1;
	shooter fireweapon(0);
	shooter adsaim(0);
	wait 0.5;
	if (weapon == "mg")
		shooter stopUseTurret();

	println("DUEL done weapon=" + weapon + " dist=" + int(distance(shooter getViewOrigin(), point)) + " aim=" + aim + " hitloc=" + target.devDuelHitLoc + " health=" + target.health + " alive=" + isAlive(target) + " held=" + shooter getCurrentWeapon() + " shots=" + (clip - shooter getWeaponSlotClipAmmo("primary")));
}

// The hit location the damage code ended with (a neck hit counts as head with scr_hitbox_neck_kill)
devDuelOnDamaged(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset)
{
	if (isDefined(self.devDuelHitLoc) && self.devDuelHitLoc == "none")
		self.devDuelHitLoc = sHitLoc;
}

// developer_script 1: "rcon set dev_bots_autoready 1" makes bots ready up in every ready-up,
// by pressing use as a player does
devBotsAutoReady()
{
	for (;;)
	{
		wait 1;
		if (!getCvarInt("dev_bots_autoready") || !isDefined(level.in_readyup) || !level.in_readyup)
			continue;
		players = getentarray("player", "classname");
		for (i = 0; i < players.size; i++)
		{
			p = players[i];
			if (p.pers["isBot"] && isDefined(p.isReady) && !p.isReady && p.sessionstate == "playing")
				p thread devPressUse();
		}
	}
}

devPressUse()
{
	self usebutton(1);
	wait 0.2;
	self usebutton(0);
}
