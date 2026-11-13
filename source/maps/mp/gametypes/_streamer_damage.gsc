#include maps\mp\gametypes\global\_global;

init()
{
	if(game["firstInit"])
	{
		precacheString2("STRING_STREAMERSYSTEM_HIT_HP", 		&"ZPAM_HIT_HP");

		precacheString2("STRING_STREAMERSYSTEM_HIT_HEAD", 		&"ZPAM_HIT_HEAD");
		precacheString2("STRING_STREAMERSYSTEM_HIT_NECK", 		&"ZPAM_HIT_NECK");
		precacheString2("STRING_STREAMERSYSTEM_HIT_BODY", 		&"ZPAM_HIT_BODY");
		precacheString2("STRING_STREAMERSYSTEM_HIT_BODY_UPPER", 	&"ZPAM_HIT_BODY_UPPER");
		precacheString2("STRING_STREAMERSYSTEM_HIT_BODY_LOWER", 	&"ZPAM_HIT_BODY_LOWER");
		precacheString2("STRING_STREAMERSYSTEM_HIT_SHOULDER", 		&"ZPAM_HIT_SHOULDER");
		precacheString2("STRING_STREAMERSYSTEM_HIT_ARM", 		&"ZPAM_HIT_ARM");
		precacheString2("STRING_STREAMERSYSTEM_HIT_HAND", 		&"ZPAM_HIT_HAND");
		precacheString2("STRING_STREAMERSYSTEM_HIT_LEG", 		&"ZPAM_HIT_LEG");
		precacheString2("STRING_STREAMERSYSTEM_HIT_LEG_UPPEER", 	&"ZPAM_HIT_LEG_UPPER");
		precacheString2("STRING_STREAMERSYSTEM_HIT_LEG_LOWER", 		&"ZPAM_HIT_LEG_LOWER");
		precacheString2("STRING_STREAMERSYSTEM_HIT_FOOT", 		&"ZPAM_HIT_FOOT");
		precacheString2("STRING_STREAMERSYSTEM_HIT_GRENADE", 		&"ZPAM_HIT_GRENADE");

		precacheString2("STRING_STREAMERSYSTEM_HIT_SHOTGUN_1p", 	&"ZPAM_HIT_PELLETS_1");
		precacheString2("STRING_STREAMERSYSTEM_HIT_SHOTGUN_2p", 	&"ZPAM_HIT_PELLETS_2");
		precacheString2("STRING_STREAMERSYSTEM_HIT_SHOTGUN_3p", 	&"ZPAM_HIT_PELLETS_3");
		precacheString2("STRING_STREAMERSYSTEM_HIT_SHOTGUN_4p", 	&"ZPAM_HIT_PELLETS_4");
		precacheString2("STRING_STREAMERSYSTEM_HIT_SHOTGUN_5p", 	&"ZPAM_HIT_PELLETS_5");
		precacheString2("STRING_STREAMERSYSTEM_HIT_SHOTGUN_6p", 	&"ZPAM_HIT_PELLETS_6");
		precacheString2("STRING_STREAMERSYSTEM_HIT_SHOTGUN_7p", 	&"ZPAM_HIT_PELLETS_7");
		precacheString2("STRING_STREAMERSYSTEM_HIT_SHOTGUN_8p", 	&"ZPAM_HIT_PELLETS_8");

		precacheString2("STRING_STREAMERSYSTEM_HIT_INFO_SHOTGUN_1_KILL", 	&"ZPAM_HIT_SHOTGUN_RANGE_1_KILL");
		precacheString2("STRING_STREAMERSYSTEM_HIT_INFO_SHOTGUN_1_HIT", 	&"ZPAM_HIT_SHOTGUN_RANGE_1_HIT");
		precacheString2("STRING_STREAMERSYSTEM_HIT_INFO_SHOTGUN_2", 		&"ZPAM_HIT_SHOTGUN_RANGE_2");
		precacheString2("STRING_STREAMERSYSTEM_HIT_INFO_SHOTGUN_3", 		&"ZPAM_HIT_SHOTGUN_RANGE_3");
		precacheString2("STRING_STREAMERSYSTEM_HIT_INFO_SHOTGUN_4", 		&"ZPAM_HIT_SHOTGUN_RANGE_4");
		precacheString2("STRING_STREAMERSYSTEM_HIT_INFO_TORSO_HITBOX_FIX", 	&"ZPAM_HIT_TORSO_FIX");
		precacheString2("STRING_STREAMERSYSTEM_HIT_INFO_HAND_HITBOX_FIX", 	&"ZPAM_HIT_HAND_FIX");

		precacheShader("headicon_dead");

		//game["STRING_STREAMERSYSTEM_DAMAGEINFO_ON"] = 		"Hit info ^2On";
		//game["STRING_STREAMERSYSTEM_DAMAGEINFO_OFF"] = 		"Hit info ^1Off";
	}

	addEventListener("onPlayerDamaged", 	::onPlayerDamaged); // In readyup show damage info for regular players

	if (!level.streamerSystem)
		return;

	addEventListener("onPlayerKilled", 	::onPlayerKilled);
	addEventListener("onConnected",  ::onConnected);
}

onConnected()
{
	if (!isDefined(self.pers["streamerSystem_damageInfo"]))
		self.pers["streamerSystem_damageInfo"] = true;
}


toggle()
{
	self.pers["streamerSystem_damageInfo"] = !self.pers["streamerSystem_damageInfo"];

	/*if (self.pers["streamerSystem_damageInfo"])
		self iprintln(game["STRING_STREAMERSYSTEM_DAMAGEINFO_ON"]);
	else
		self iprintln(game["STRING_STREAMERSYSTEM_DAMAGEINFO_OFF"]);*/

	self thread maps\mp\gametypes\_streamer_hud::settingsChangedForPlayer("damage");
}

/*
Called when player has taken damage.
self is the player that took damage.
*/
// Is called even if streamer system is disabled!
onPlayerDamaged(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	waittillframeend; // wait untill all hits are processed

	if (isDefined(eAttacker) && isPlayer(eAttacker) && self != eAttacker)
	{
		// Damage info can be showed in 2 modes:
		//   - in readyup for regular players
		//   - for spectators - show info for spectated player
		forPlayer = level.in_readyup;
		forSpectators = level.streamerSystem && isDefined(level.streamerSystem_player) && eAttacker == level.streamerSystem_player;

		if (forPlayer || forSpectators)
		{
			self_num = self getEntityNumber();
			isShotgun = sWeapon == "shotgun_mp" && sMeansOfDeath == "MOD_PISTOL_BULLET";

			pellets = 0;
			if (isShotgun)
				pellets = eAttacker.hitData[self_num].id;

			adjustedBy = eAttacker.hitData[self_num].adjustedBy;

			// In readyup show for regular players
			if (forPlayer)
			{
				// For shotgun show accumulated damage
				if (isShotgun) 	damage = eAttacker.hitData[self_num].damage_comulated;
				else		damage = eAttacker.hitData[self_num].damage;

				eAttacker thread showDamageInfoReadyup(damage, sHitLoc, sMeansOfDeath, pellets, adjustedBy);
			}

			// Show to all spectators
			if (forSpectators)
			{
				damage = eAttacker.hitData[self_num].damage_comulated;

				players = getentarray("player", "classname");
				for(i = 0; i < players.size; i++)
				{
					player = players[i];
					if (player.pers["team"] == "streamer" && player.streamerSystem_turnedOn && player.pers["streamerSystem_damageInfo"] && !isDefined(player.killcam))
					{
						// Damage info overlaps with killcam proposal - dont show
						if (player.streamerSystem_killcam_proposingVisible) return;

						player thread showDamageInfo(damage, sHitLoc, sMeansOfDeath, pellets, adjustedBy);
					}
				}
			}
		}
	}

	// Show taken damage
	if (level.streamerSystem && isDefined(level.streamerSystem_player) && self == level.streamerSystem_player && !level.in_readyup)
	{
		damage = iDamage;
		if (isDefined(eAttacker) && isPlayer(eAttacker))
		{
			self_num = self getEntityNumber();
			damage = eAttacker.hitData[self_num].damage_comulated;
		}

		// Show to all spectators
		players = getentarray("player", "classname");
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if (player.pers["team"] == "streamer" && player.streamerSystem_turnedOn && player.pers["streamerSystem_damageInfo"] && !isDefined(player.killcam))
			{
				// Damage info overlaps with killcam proposal - dont show
				if (player.streamerSystem_killcam_proposingVisible) return;

				player thread showTakenDamageInfo(damage, sHitLoc, sMeansOfDeath);
			}
		}
	}
}

/*
Called when player is killed
self is the player that was killed.
*/
onPlayerKilled(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	if (isDefined(eAttacker) && isPlayer(eAttacker) && self != eAttacker && isDefined(level.streamerSystem_player) && eAttacker == level.streamerSystem_player && !level.in_readyup)
	{
		// Show to all spectators
		players = getentarray("player", "classname");
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if (player.pers["team"] == "streamer" && player.streamerSystem_turnedOn && player.pers["streamerSystem_damageInfo"] && !isDefined(player.killcam))
			{
				// Damage info overlaps with killcam proposal - dont show
				if (player.streamerSystem_killcam_proposingVisible) return;

				player thread showKillInfo();
			}
		}
	}
}

showDamageInfo(damage, sHitLoc, sMeansOfDeath, pellets, adjustedBy)
{
	hitLocTexts["head"] = 			game["STRING_STREAMERSYSTEM_HIT_HEAD"];
	hitLocTexts["neck"] = 			game["STRING_STREAMERSYSTEM_HIT_NECK"];
	hitLocTexts["torso_upper"] = 		game["STRING_STREAMERSYSTEM_HIT_BODY"];
	hitLocTexts["torso_lower"] = 		game["STRING_STREAMERSYSTEM_HIT_BODY"];
	hitLocTexts["left_arm_upper"] = 	game["STRING_STREAMERSYSTEM_HIT_SHOULDER"];
	hitLocTexts["left_arm_lower"] = 	game["STRING_STREAMERSYSTEM_HIT_ARM"];
	hitLocTexts["left_hand"] = 		game["STRING_STREAMERSYSTEM_HIT_HAND"];
	hitLocTexts["right_arm_upper"] = 	game["STRING_STREAMERSYSTEM_HIT_SHOULDER"];
	hitLocTexts["right_arm_lower"] = 	game["STRING_STREAMERSYSTEM_HIT_ARM"];
	hitLocTexts["right_hand"] = 		game["STRING_STREAMERSYSTEM_HIT_HAND"];
	hitLocTexts["left_leg_upper"] = 	game["STRING_STREAMERSYSTEM_HIT_LEG"];
	hitLocTexts["left_leg_lower"] = 	game["STRING_STREAMERSYSTEM_HIT_LEG"];
	hitLocTexts["right_leg_upper"] = 	game["STRING_STREAMERSYSTEM_HIT_LEG"];
	hitLocTexts["right_leg_lower"] = 	game["STRING_STREAMERSYSTEM_HIT_LEG"];
	hitLocTexts["left_foot"] = 		game["STRING_STREAMERSYSTEM_HIT_FOOT"];
	hitLocTexts["right_foot"] = 		game["STRING_STREAMERSYSTEM_HIT_FOOT"];


	self endon("disconnect");

	if (isDefined(self.killcam))
		return;

	self notify("autoSpectating_showDamageInfo_end");
	self endon("autoSpectating_showDamageInfo_end");

	if (!isDefined(self.hud_damageinfo))
	{
		self.hud_damageinfo = newClientHudElem2(self);
		self.hud_damageinfo.horzAlign = "center";
		self.hud_damageinfo.vertAlign = "middle";
		self.hud_damageinfo.alignX = "right";
		self.hud_damageinfo.label = game["STRING_STREAMERSYSTEM_HIT_HP"];
		self.hud_damageinfo.x = -10;
		self.hud_damageinfo.fontscale = 1.1;
		self.hud_damageinfo.archived = false;
	}

	if (!isDefined(self.hud_damageinfo_loc))
	{
		self.hud_damageinfo_loc = newClientHudElem2(self);
		self.hud_damageinfo_loc.horzAlign = "center";
		self.hud_damageinfo_loc.vertAlign = "middle";
		self.hud_damageinfo_loc.alignX = "left";
		self.hud_damageinfo_loc.x = 2;
		self.hud_damageinfo_loc.fontscale = 1.1;
		self.hud_damageinfo_loc.archived = false;
	}

	if (damage > 100)
		damage = 100;

	self.hud_damageinfo setValue(damage);

	if (sMeansOfDeath == "MOD_GRENADE_SPLASH")
		self.hud_damageinfo_loc setText(game["STRING_STREAMERSYSTEM_HIT_GRENADE"]);
	else if (pellets >= 1 && pellets <= 8) // shotgun
		self.hud_damageinfo_loc setText(game["STRING_STREAMERSYSTEM_HIT_SHOTGUN_" + pellets + "p"]);
	else if (isDefined(hitLocTexts[sHitLoc]))
		self.hud_damageinfo_loc setText(hitLocTexts[sHitLoc]);

	r = 1;
	g = 1 - ((damage - 50) / 50); 	if (g < 0) g = 0; if (g > 1) g = 1;
	b = 1 - (damage / 50); 	if (b < 0) b = 0; if (b > 1) b = 1;

	// red to orange to yellow -> add green
	// yellow to white -> add blue

	self.hud_damageinfo.color = (r, g, b);
	self.hud_damageinfo_loc.color = (1, 1, 1);

	self.hud_damageinfo.y = 180;
	self.hud_damageinfo.alpha = 1;
	self.hud_damageinfo_loc.y = 180;
	self.hud_damageinfo_loc.alpha = 1;

	// Move up slowly
	self.hud_damageinfo moveovertime(5);
	self.hud_damageinfo.y = 170;
	self.hud_damageinfo_loc moveovertime(5);
	self.hud_damageinfo_loc.y = 170;

	wait 3;

	self.hud_damageinfo FadeOverTime(2);
	self.hud_damageinfo.alpha = 0;
	self.hud_damageinfo_loc FadeOverTime(2);
	self.hud_damageinfo_loc.alpha = 0;

	wait 2;

	self.hud_damageinfo destroy2();
	self.hud_damageinfo_loc destroy2();
}



showDamageInfoReadyup(damage, sHitLoc, sMeansOfDeath, pellets, adjustedBy)
{
	hitLocTexts["head"] = 			game["STRING_STREAMERSYSTEM_HIT_HEAD"];
	hitLocTexts["neck"] = 			game["STRING_STREAMERSYSTEM_HIT_NECK"];
	hitLocTexts["torso_upper"] = 		game["STRING_STREAMERSYSTEM_HIT_BODY_UPPER"];
	hitLocTexts["torso_lower"] = 		game["STRING_STREAMERSYSTEM_HIT_BODY_LOWER"];
	hitLocTexts["left_arm_upper"] = 	game["STRING_STREAMERSYSTEM_HIT_SHOULDER"];
	hitLocTexts["left_arm_lower"] = 	game["STRING_STREAMERSYSTEM_HIT_ARM"];
	hitLocTexts["left_hand"] = 		game["STRING_STREAMERSYSTEM_HIT_HAND"];
	hitLocTexts["right_arm_upper"] = 	game["STRING_STREAMERSYSTEM_HIT_SHOULDER"];
	hitLocTexts["right_arm_lower"] = 	game["STRING_STREAMERSYSTEM_HIT_ARM"];
	hitLocTexts["right_hand"] = 		game["STRING_STREAMERSYSTEM_HIT_HAND"];
	hitLocTexts["left_leg_upper"] = 	game["STRING_STREAMERSYSTEM_HIT_LEG_UPPEER"];
	hitLocTexts["left_leg_lower"] = 	game["STRING_STREAMERSYSTEM_HIT_LEG_LOWER"];
	hitLocTexts["right_leg_upper"] = 	game["STRING_STREAMERSYSTEM_HIT_LEG_UPPEER"];
	hitLocTexts["right_leg_lower"] = 	game["STRING_STREAMERSYSTEM_HIT_LEG_LOWER"];
	hitLocTexts["left_foot"] = 		game["STRING_STREAMERSYSTEM_HIT_FOOT"];
	hitLocTexts["right_foot"] = 		game["STRING_STREAMERSYSTEM_HIT_FOOT"];

	adjuestedByTexts["consistent_shotgun_1_kill"] = 	game["STRING_STREAMERSYSTEM_HIT_INFO_SHOTGUN_1_KILL"];
	adjuestedByTexts["consistent_shotgun_1_hit"] = 		game["STRING_STREAMERSYSTEM_HIT_INFO_SHOTGUN_1_HIT"];
	adjuestedByTexts["consistent_shotgun_2"] = 		game["STRING_STREAMERSYSTEM_HIT_INFO_SHOTGUN_2"];
	adjuestedByTexts["consistent_shotgun_3"] = 		game["STRING_STREAMERSYSTEM_HIT_INFO_SHOTGUN_3"];
	adjuestedByTexts["consistent_shotgun_4"] = 		game["STRING_STREAMERSYSTEM_HIT_INFO_SHOTGUN_4"];
	adjuestedByTexts["torso_hitbox_fix"] = 			game["STRING_STREAMERSYSTEM_HIT_INFO_TORSO_HITBOX_FIX"];
	adjuestedByTexts["hand_hitbox_fix"] = 			game["STRING_STREAMERSYSTEM_HIT_INFO_HAND_HITBOX_FIX"];


	self endon("disconnect");

	if (isDefined(self.killcam))
		return;

	self notify("autoSpectating_showDamageInfo_end");
	self endon("autoSpectating_showDamageInfo_end");

	if (!isDefined(self.hud_damageinfo))
	{
		self.hud_damageinfo = newClientHudElem2(self);
		self.hud_damageinfo.horzAlign = "center";
		self.hud_damageinfo.vertAlign = "middle";
		self.hud_damageinfo.alignX = "left";
		self.hud_damageinfo.label = game["STRING_STREAMERSYSTEM_HIT_HP"];
		self.hud_damageinfo.x = -44;
		self.hud_damageinfo.fontscale = 1.1;
		self.hud_damageinfo.archived = false;
	}

	if (!isDefined(self.hud_damageinfo_loc))
	{
		self.hud_damageinfo_loc = newClientHudElem2(self);
		self.hud_damageinfo_loc.horzAlign = "center";
		self.hud_damageinfo_loc.vertAlign = "middle";
		self.hud_damageinfo_loc.alignX = "right";
		self.hud_damageinfo_loc.x = 42;
		self.hud_damageinfo_loc.fontscale = 1.1;
		self.hud_damageinfo_loc.archived = false;
	}

	if (!isDefined(self.hud_damageinfo_adjustedBy))
	{
		self.hud_damageinfo_adjustedBy = newClientHudElem2(self);
		self.hud_damageinfo_adjustedBy.horzAlign = "center";
		self.hud_damageinfo_adjustedBy.vertAlign = "middle";
		self.hud_damageinfo_adjustedBy.alignX = "center";
		self.hud_damageinfo_adjustedBy.x = 0;
		self.hud_damageinfo_adjustedBy.fontscale = 0.7;
		self.hud_damageinfo_adjustedBy.archived = false;
	}

	self.hud_damageinfo setValue(damage);

	if (sMeansOfDeath == "MOD_GRENADE_SPLASH")
		self.hud_damageinfo_loc setText(game["STRING_STREAMERSYSTEM_HIT_GRENADE"]);
	else if (pellets >= 1 && pellets <= 8) // shotgun
		self.hud_damageinfo_loc setText(game["STRING_STREAMERSYSTEM_HIT_SHOTGUN_" + pellets + "p"]);
	else if (isDefined(hitLocTexts[sHitLoc]))
		self.hud_damageinfo_loc setText(hitLocTexts[sHitLoc]);

	if (isDefined(adjuestedByTexts[adjustedBy]))
	{
		self.hud_damageinfo_adjustedBy setText(adjuestedByTexts[adjustedBy]);
		self.hud_damageinfo_adjustedBy.alpha = 1;
	}
	else
		self.hud_damageinfo_adjustedBy.alpha = 0;

	r = 1;
	g = 1 - ((damage - 50) / 50); 	if (g < 0) g = 0; if (g > 1) g = 1;
	b = 1 - (damage / 50); 		if (b < 0) b = 0; if (b > 1) b = 1;

	// red to orange to yellow -> add green
	// yellow to white -> add blue

	self.hud_damageinfo.color = (r, g, b);
	self.hud_damageinfo_loc.color = (1, 1, 1);
	self.hud_damageinfo_adjustedBy.color = (1, 1, 1);

	self.hud_damageinfo.y = 120;
	self.hud_damageinfo.alpha = 1;
	self.hud_damageinfo_loc.y = 120;
	self.hud_damageinfo_loc.alpha = 1;
	self.hud_damageinfo_adjustedBy.y = 110;
	//self.hud_damageinfo_adjustedBy.alpha = 1;

	wait 3;

	self.hud_damageinfo FadeOverTime(1);
	self.hud_damageinfo.alpha = 0;
	self.hud_damageinfo_loc FadeOverTime(1);
	self.hud_damageinfo_loc.alpha = 0;
	self.hud_damageinfo_adjustedBy FadeOverTime(1);
	self.hud_damageinfo_adjustedBy.alpha = 0;

	wait 1;

	self.hud_damageinfo destroy2();
	self.hud_damageinfo_loc destroy2();
	self.hud_damageinfo_adjustedBy destroy2();
}



showTakenDamageInfo(iDamage, sHitLoc, sMeansOfDeath)
{
	hitLocTexts["head"] = 			game["STRING_STREAMERSYSTEM_HIT_HEAD"];
	hitLocTexts["neck"] = 			game["STRING_STREAMERSYSTEM_HIT_NECK"];
	hitLocTexts["torso_upper"] = 		game["STRING_STREAMERSYSTEM_HIT_BODY"];
	hitLocTexts["torso_lower"] = 		game["STRING_STREAMERSYSTEM_HIT_BODY"];
	hitLocTexts["left_arm_upper"] = 	game["STRING_STREAMERSYSTEM_HIT_SHOULDER"];
	hitLocTexts["left_arm_lower"] = 	game["STRING_STREAMERSYSTEM_HIT_ARM"];
	hitLocTexts["left_hand"] = 		game["STRING_STREAMERSYSTEM_HIT_HAND"];
	hitLocTexts["right_arm_upper"] = 	game["STRING_STREAMERSYSTEM_HIT_SHOULDER"];
	hitLocTexts["right_arm_lower"] = 	game["STRING_STREAMERSYSTEM_HIT_ARM"];
	hitLocTexts["right_hand"] = 		game["STRING_STREAMERSYSTEM_HIT_HAND"];
	hitLocTexts["left_leg_upper"] = 	game["STRING_STREAMERSYSTEM_HIT_LEG"];
	hitLocTexts["left_leg_lower"] = 	game["STRING_STREAMERSYSTEM_HIT_LEG"];
	hitLocTexts["left_foot"] = 		game["STRING_STREAMERSYSTEM_HIT_FOOT"];
	hitLocTexts["right_leg_upper"] = 	game["STRING_STREAMERSYSTEM_HIT_LEG"];
	hitLocTexts["right_leg_lower"] = 	game["STRING_STREAMERSYSTEM_HIT_LEG"];
	hitLocTexts["right_foot"] = 		game["STRING_STREAMERSYSTEM_HIT_FOOT"];

	self endon("disconnect");

	if (isDefined(self.killcam))
		return;

	self notify("autoSpectating_showTakenDamageInfo_end");
	self endon("autoSpectating_showTakenDamageInfo_end");

	if (!isDefined(self.hud_takendamageinfo))
	{
		self.hud_takendamageinfo = newClientHudElem2(self);
		self.hud_takendamageinfo.horzAlign = "center";
		self.hud_takendamageinfo.vertAlign = "middle";
		self.hud_takendamageinfo.alignX = "right";
		self.hud_takendamageinfo.label = game["STRING_STREAMERSYSTEM_HIT_HP"];
		self.hud_takendamageinfo.x = -10;
		self.hud_takendamageinfo.fontscale = 1.1;
		self.hud_takendamageinfo.archived = false;
	}

	if (!isDefined(self.hud_takendamageinfo_loc))
	{
		self.hud_takendamageinfo_loc = newClientHudElem2(self);
		self.hud_takendamageinfo_loc.horzAlign = "center";
		self.hud_takendamageinfo_loc.vertAlign = "middle";
		self.hud_takendamageinfo_loc.alignX = "left";
		self.hud_takendamageinfo_loc.x = 2;
		self.hud_takendamageinfo_loc.fontscale = 1.1;
		self.hud_takendamageinfo_loc.archived = false;
	}

	if (iDamage > 100)
		iDamage = 100;

	self.hud_takendamageinfo setValue(iDamage*-1);

	if (sMeansOfDeath == "MOD_GRENADE_SPLASH")
		self.hud_takendamageinfo_loc setText(game["STRING_STREAMERSYSTEM_HIT_GRENADE"]);
	else if (isDefined(hitLocTexts[sHitLoc]))
		self.hud_takendamageinfo_loc setText(hitLocTexts[sHitLoc]);

	r = 1;
	g = 1 - ((iDamage - 50) / 50); 	if (g < 0) g = 0; if (g > 1) g = 1;
	b = 1 - (iDamage / 50); 	if (b < 0) b = 0; if (b > 1) b = 1;

	// red to orange to yellow -> add green
	// yellow to white -> add blue

	self.hud_takendamageinfo.color = (r, g, b);
	self.hud_takendamageinfo_loc.color = (1, 1, 1);

	self.hud_takendamageinfo.y = 185;
	self.hud_takendamageinfo.alpha = 1;
	self.hud_takendamageinfo_loc.y = 185;
	self.hud_takendamageinfo_loc.alpha = 1;

	// Move down slowly
	self.hud_takendamageinfo moveovertime(5);
	self.hud_takendamageinfo.y = 195;
	self.hud_takendamageinfo_loc moveovertime(5);
	self.hud_takendamageinfo_loc.y = 195;

	wait 3;

	self.hud_takendamageinfo FadeOverTime(2);
	self.hud_takendamageinfo.alpha = 0;
	self.hud_takendamageinfo_loc FadeOverTime(2);
	self.hud_takendamageinfo_loc.alpha = 0;

	wait 2;

	self.hud_takendamageinfo destroy2();
	self.hud_takendamageinfo_loc destroy2();
}





showKillInfo()
{
	self endon("disconnect");

	if (isDefined(self.killcam))
		return;

	self notify("autoSpectating_showKillInfo_end");
	self endon("autoSpectating_showKillInfo_end");

	if (!isDefined(self.hud_damageinfo_kill))
	{
		self.hud_damageinfo_kill = newClientHudElem2(self);
		self.hud_damageinfo_kill.horzAlign = "center";
		self.hud_damageinfo_kill.vertAlign = "middle";
		self.hud_damageinfo_kill.x = -65;
		self.hud_damageinfo_kill.archived = false;
		self.hud_damageinfo_kill setShader("headicon_dead", 23, 23);
	}

	self.hud_damageinfo_kill.y = 180 - 2;
	self.hud_damageinfo_kill.alpha = 1;

	// Move up slowly
	self.hud_damageinfo_kill moveovertime(5);
	self.hud_damageinfo_kill.y = 170 - 2;

	wait 3;

	self.hud_damageinfo_kill FadeOverTime(2);
	self.hud_damageinfo_kill.alpha = 0;

	wait 2;

	self.hud_damageinfo_kill destroy2();
}
