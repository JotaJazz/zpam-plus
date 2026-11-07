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
	thread timingSelfTest();
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
