#include maps\mp\gametypes\global\_global;

Init()
{
	addEventListener("onStartGameType", ::onStartGameType);
	addEventListener("onConnected",     ::onConnected);
        addEventListener("onDisconnect",    ::onDisconnect);
	addEventListener("onSpawned",    ::onSpawned);

	level.aimTargets = [];
	level.aimTargetsSupported = false;
}

onStartGameType()
{
	// Load targets and activators
	targets = 		getentarray("trainer_target", "targetname");
	targets_damage = 	getentarray("trainer_trigger", "targetname");
	activators = 		getentarray("trainer_activator", "targetname");
	activators_damage = 	getentarray("trainer_activator_damage", "targetname");
	activators_hint = 	getentarray("trainer_activator_hint", "targetname");

	if (targets.size == 0 || activators.size == 0)
		return;
	if (targets.size != targets_damage.size)
	{
		println("aim_trainer: invalid number of 'trainer_target' vs 'trainer_trigger'");
		return;
	}
	if (activators.size != activators_damage.size || activators.size != activators_hint.size)
	{
		println("aim_trainer: invalid number of 'activators' vs 'targets_damage' vs 'activators_hint'");
		return;
	}

	level.aimTargetsSupported = true;


	// Not allowed -> delete
	if (!level.in_readyup)
	{
		for (i = 0; i < targets.size; i++)
		{
			targets[i] delete();
			targets_damage[i] delete();
		}
		for (i = 0; i < activators.size; i++)
		{
			activators[i] delete();
			activators_damage[i] delete();
			activators_hint[i] delete();
		}
		return;
	}



	level._effect["aimTargetExplosion"] = loadfx("fx/impacts/large_metalhit.efx");

	for (i = 0; i < targets.size; i++)
	{
		targets[i] notsolid();
		targets[i].trigger_damage = targets_damage[i];
		targets[i].origin_original = targets[i].origin;

		targets_damage[i] enablelinkto();
		targets_damage[i] linkTo(targets[i]);
		targets_damage[i].parent = targets[i];
	}


	for (i = 0; i < activators_damage.size; i++)
	{
		activators_damage[i] thread handleActivation();

		activators_hint[i] setcursorhint("HINT_NONE");



	}


	level.aimTargets = targets;

}

onConnected()
{
	self.aimTrainerMode = 0;
	self.aimTrainer_startAngles = (0, 0, 0);
	self.aimTrainerActivatorDelay = 0;
}


onDisconnect()
{
	self turnOff();
}

onSpawned()
{
	self turnOff();
}



reserveTargetBy(player)
{
	for (i = 0; i < level.aimTargets.size; i++)
	{
		target = level.aimTargets[i];

		if (!isDefined(target.reservedBy))
		{
			target.reservedBy = player;


			return target;
		}
	}
	return undefined;
}

releaseTarget()
{
	target = self;

	target hide();
	target.reservedBy = undefined;
	target.origin = target.origin_original;

	target notify("aim_trainer_target_released");
}

rotateTowards(player)
{
	target = self;

	target endon("aim_trainer_target_released");

	for (;;)
	{
		if (!isDefined(target) || !isDefined(player))
			return;

		angles = vectortoangles(player.origin - target.origin);

		target.angles = (0, angles[1] + 180, 0);

		wait level.frame;
		waittillframeend;
	}
}



handleDamageForPlayer(player)
{
	target = self;

	target endon("aim_trainer_target_released");

	for(;;)
	{
		target.trigger_damage waittill("damage", dmg, attacker);

		// Ignore damages for other players
		if (attacker != player)
			continue;

		player thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback(undefined);

		player thread generateMeNewTargetPosition("kill");
	}
}

handleActivation()
{
	activator_damage = self;

	for(;;)
	{
		activator_damage waittill("damage", dmg, player);

		// Trainer is enabled, ignore hits
		if (player.aimTrainerMode != 0)
			continue;

		player thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback(undefined);

		// Printed just a few seconds ago
		if (player.aimTrainerActivatorDelay > gettime())
			continue;

		player iprintlnbold(&"ZPAM_AIM_CONTROL");
		player iprintlnbold(&"ZPAM_AIM_HOLD");
		player iprintlnbold(&"ZPAM_AIM_DOUBLE");
		player iprintlnbold(" ");
		player iprintlnbold(" ");

		player.aimTrainerActivatorDelay = gettime() + 5000;
	}
}


setKillTimeout(seconds, target)
{
	self endon("disconnect");

	target endon("aim_trainer_target_released");
	target endon("aim_trainer_target_updated");

	target notify("aim_trainer_kill_timeout");
	target endon("aim_trainer_kill_timeout");

	wait seconds;

	self thread generateMeNewTargetPosition("timeout");
}







getTargetPos(randomize)
{
	eye = self maps\mp\gametypes\global\player::getEyeOrigin();
	angles = self getPlayerAngles();
	weapon = self getcurrentweapon();
	isSniper = maps\mp\gametypes\_weapons::isSniper(weapon);
	isShotgun = maps\mp\gametypes\_weapons::isShotgun(weapon);
	zoom = self playerAds();
	fov = self getFOV() / 80;



	// Make sure the target is always visible on screen
	angles_new = angles;
	if (randomize)
	{
		angleDiff = angles[1] - self.aimTrainer_startAngles[1];
		if (angleDiff > 180)		angleDiff -= 360;
		else if (angleDiff < -180)	angleDiff += 360;

		// Player is not looking to startAngles direction, save new
		if (angleDiff < -45 || angleDiff > 45)
			self.aimTrainer_startAngles = angles;

		// left +, right -, max 40
		left_right = randomint(40) - 20; // -20 <-> 19
		left_right *= fov;
		left_right += self.aimTrainer_startAngles[1];

		// up -, down +
		up_down = randomint(14) - 8; // -8 <-> 5
		up_down *= fov;


		// For snipers align it according to up down angles
		if (zoom > 0 && isSniper)
		{
			up_down += angles[0];
		}


		// Avoid spawning targets below the weapon model
		if (up_down > angles[0] && zoom > 0 && isSniper == false)
		{
			left_right_diff = (angles[1] - left_right);
			if (left_right_diff > -10 && left_right_diff <= 0)
			{
				left_right += 10;

			}
			else if (left_right_diff < 10 && left_right_diff > 0)
			{
				left_right -= 10;
			}
		}


		angles_new = (up_down, left_right, 0);
	}


	distance = 200;
	if (isSniper && zoom > 0)
	{
		distance = 1700;
	}
	else if (isShotgun)
	{
		distance = 150;
		if (self.isMoving)
			distance = 200;
	}
	else if (fov < 1)
		distance = 400;

	forward = anglesToForward(angles_new);
	forwardMultiplier = distance;

	forwardOrigin = eye + (forward[0] * forwardMultiplier, forward[1] * forwardMultiplier, forward[2] * forwardMultiplier);


	forwardTrace = Bullettrace(eye, forwardOrigin, false, self); // BulletTrace( <start>, <end>, <hit characters>, <ignore entity> )
	forwardTracedOrigin = forwardTrace["position"];


	vector = (forwardTracedOrigin - eye);

	vectorNorm = VectorNormalize(vector);
	vectorLen = length(vector);

	multiplier = vectorLen * 0.8;

	newPos = eye + (vectorNorm[0] * multiplier, vectorNorm[1] * multiplier, vectorNorm[2] * multiplier);

	return newPos;
}

moving(speed)
{
	target = self;

	target endon("aim_trainer_target_released");
	target endon("aim_trainer_target_updated");

	// Wait till properly rotated and spawned
	waittillframeend;

	// Generate moving direction
	right = anglesToRight(target.angles);
	distance = 100; // to both sides

	origin_original = target.origin;
	origin_right = target.origin + (right[0] * distance, right[1] * distance, right[2] * distance);
	origin_left = target.origin + (right[0] * distance * -1, right[1] * distance * -1, right[2] * distance * -1);

	rightTrace = Bullettrace(origin_original, origin_right, false, target); // BulletTrace( <start>, <end>, <hit characters>, <ignore entity> )
	leftTrace = Bullettrace(origin_original, origin_left, false, target); // BulletTrace( <start>, <end>, <hit characters>, <ignore entity> )

	new_distance_right = distance(origin_original, rightTrace["position"]) * 0.8;
	new_distance_left = distance(origin_original, leftTrace["position"]) * 0.8;

	origin[0] = origin_original + (right[0] * new_distance_right, right[1] * new_distance_right, right[2] * new_distance_right);
	origin[1] = origin_original + (right[0] * new_distance_left * -1, right[1] * new_distance_left * -1, right[2] * new_distance_left * -1);

	total_distance = distance(origin[0], origin[1]);

	speed = speed * (total_distance / (distance*2));
	time[0] = speed * (new_distance_right / (distance*2));
	time[1] = speed * (new_distance_left / (distance*2));






	index_1 = 0;
	index_2 = 1;
	rand = randomint(2); // 0 - 1
	if (rand)
	{
		index_1 = 1;
		index_2 = 0;
	}

	firstMove = true;
	for(;;)
	{
		accel = 0.1;
		time1 = speed;
		time2 = speed;
		accel1 = time1*accel;
		if (firstMove)
		{
			time1 = time[index_1]; // first move is faster with no accell
			accel1 = 0;
			firstMove = false;
		}

		target moveto(origin[index_1], time1, accel1, time1*accel); // moveto( <point>, <time>, <acceleration time>, <deceleration time> )

		target waittill("movedone");

		target moveto(origin[index_2], time2, time2*accel, time2*accel); // moveto( <point>, <time>, <acceleration time>, <deceleration time> )

		target waittill("movedone");
	}
}






toggle()
{
	if (level.aimTargets.size == 0)
	{
		self iprintln(&"ZPAM_AIM_NOT_SUPPORTED");
		return;
	}


	wasDisabled = self.aimTrainerMode == 0;

	for (i = 0; i < 2; i++)
		self iprintlnbold(" ");

	if (self.aimTrainerMode == 0)
	{
		self.aimTrainerMode = 1;

		self thread player_loop();

		// No available targets
		if (self.aimTrainerMode == 0)
			return;

		self iprintln(&"ZPAM_AIM_ENABLED");
		self iprintlnbold(&"ZPAM_AIM_ENABLED");
	}


	if (wasDisabled || self.aimTrainerMode == 4)
	{
		self.aimTrainerMode = 1;
		self iprintlnbold(&"ZPAM_AIM_MODE_1");
	}
	else if (self.aimTrainerMode == 1)
	{
		self.aimTrainerMode = 2;
		self iprintlnbold(&"ZPAM_AIM_MODE_2");
	}
	else if (self.aimTrainerMode == 2)
	{
		self.aimTrainerMode = 3;
		self iprintlnbold(&"ZPAM_AIM_MODE_3");
	}
	else if (self.aimTrainerMode == 3)
	{
		self.aimTrainerMode = 4;
		self iprintlnbold(&"ZPAM_AIM_MODE_4");
	}

	self thread generateMeNewTargetPosition("mode");

	for (i = 0; i < 2; i++)
		self iprintlnbold(" ");
}

turnOff()
{
	if (isDefined(self.aimTrainerMode) && self.aimTrainerMode != 0)
	{
		self notify("aim_trainer_turnedOff");

		self.aimTarget1 releaseTarget();

		self iprintln(&"ZPAM_AIM_DISABLED");
		self iprintlnbold(&"ZPAM_AIM_DISABLED");

		self.aimTrainerMode = 0;
	}
}


player_loop()
{
	self endon("disconnect");
	self endon("aim_trainer_turnedOff");

	self.aimTarget1 = reserveTargetBy(self);

	// No available targets
	if (!isDefined(self.aimTarget1))
	{
		self iprintln(&"ZPAM_AIM_NO_TARGETS");
		self iprintlnbold(&"ZPAM_AIM_NO_TARGETS");
		self.aimTrainerMode = 0;
		return;
	}

	self.aimTarget1.generateTime = undefined;
	self.aimTarget1.kills_score = 0;
	self.aimTarget1.kills_score_record = 0;
	self.aimTarget1.kills = 0;
	self.aimTarget1.misses = 0;
	self.aimTarget1.timeouts = 0;

	self.aimTarget1 thread rotateTowards(self);
	self.aimTarget1 thread handleDamageForPlayer(self);


	self.aimTrainer_startAngles = self.angles;
	last_current = "none";
	last_clipAmmo = 0;
	last_kills = 0;
	last_mode = self.aimTrainerMode;
	last_weapon1 = "";
	last_weapon2 = "";
	weapon1_maxClipAmmo = 1;
	weapon2_maxClipAmmo = 1;
	pauseGivingMaxAmmo = 0;
	firstRun = true;
	while(1)
	{
		wait level.frame;

		if (pauseGivingMaxAmmo > 0) pauseGivingMaxAmmo--;

		if (!isAlive(self))
		{
			continue;
		}

		weapon1 = self getweaponslotweapon("primary");
		weapon2 = self getweaponslotweapon("primaryb");

		if (firstRun)
		{
			self givemaxammo(weapon1);
			self givemaxammo(weapon2);
			self setweaponclipammo(weapon1, 999);
			self setweaponclipammo(weapon2, 999);
			firstRun = false;
		}

		weapon1_clipAmmo = self getweaponslotclipammo("primary");
		weapon2_clipAmmo = self getweaponslotclipammo("primaryb");


		// If weapons changed in slots, save the maximum ammo in slot
		if (weapon1 != last_weapon1)
		{
			weapon1_maxClipAmmo = weapon1_clipAmmo;
		}
		if (weapon2 != last_weapon2)
		{
			weapon2_maxClipAmmo = weapon2_clipAmmo;
		}
		last_weapon1 = weapon1;
		last_weapon2 = weapon2;


		current = self getcurrentweapon();

		// For example player is on ladder
		if(current == "none")
			continue;

		current_clipAmmo = -1;
		if(current == weapon1) current_clipAmmo = weapon1_clipAmmo;
		if(current == weapon2) current_clipAmmo = weapon2_clipAmmo;


		// Bullet fired
		if (last_current == current && current_clipAmmo < last_clipAmmo && current_clipAmmo >= 0)
		{
			// This bullet was not into target
			if (self.aimTarget1.kills == last_kills && self.aimTrainerMode == last_mode)
			{

				self thread generateMeNewTargetPosition("missed");

				self.aimTarget1.misses++;
				if (self.aimTarget1.misses == 32)
				{
					self iprintlnbold(&"ZPAM_AIM_TOO_MANY_MISSES");
					self thread turnOff();
				}
			}
			else
			{

				self.aimTarget1.misses = 0;
			}

			pauseGivingMaxAmmo = int(level.sv_fps / 1); // how many frames to wait
		}


		// Imidietly after firing give player -1 less ammo to allow reloading animation
		new_clipAmmo = current_clipAmmo;
		if(current == weapon1) new_clipAmmo = weapon1_maxClipAmmo;
		if(current == weapon2) new_clipAmmo = weapon2_maxClipAmmo;
		if (pauseGivingMaxAmmo != 0 && new_clipAmmo > 0)
			new_clipAmmo--;

		if (current_clipAmmo == last_clipAmmo && current_clipAmmo != new_clipAmmo)
		{
			self setweaponclipammo(current, new_clipAmmo);

			current_clipAmmo = new_clipAmmo;
		}

		last_current = current;
		last_clipAmmo = current_clipAmmo;
		last_kills = self.aimTarget1.kills;
		last_mode = self.aimTrainerMode;
	}
}



handleKillScore()
{
	wait 0.3;

	if (self.aimTrainerMode != 4 && self.aimTarget1.kills_score >= 1)
	{
		if (self.aimTarget1.kills_score == 1) 		self playlocalsound("aim_trainer_piano_1");
		else if (self.aimTarget1.kills_score == 2) 	self playlocalsound("aim_trainer_piano_2");
		else if (self.aimTarget1.kills_score == 3) 	self playlocalsound("aim_trainer_piano_3");
		else if (self.aimTarget1.kills_score == 4) 	self playlocalsound("aim_trainer_piano_4");
		else if (self.aimTarget1.kills_score == 5) 	self playlocalsound("aim_trainer_piano_5");
		else if (self.aimTarget1.kills_score == 6) 	self playlocalsound("aim_trainer_piano_6");
		else if (self.aimTarget1.kills_score == 7) 	self playlocalsound("aim_trainer_piano_7");
		else if (self.aimTarget1.kills_score == 8) 	self playlocalsound("aim_trainer_piano_8");
		else if (self.aimTarget1.kills_score == 9) 	self playlocalsound("aim_trainer_piano_9");

		else if (self.aimTarget1.kills_score < 15) 	self playlocalsound("aim_trainer_piano_10");
		else if (self.aimTarget1.kills_score < 20) 	self playlocalsound("aim_trainer_horn");
		else 						self playlocalsound("aim_trainer_horse");

		text = &"ZPAM_AIM_SCORE";
		if (self.aimTarget1.kills_score > self.aimTarget1.kills_score_record)
		{
			if (self.aimTarget1.kills_score_record != 0)
				text = &"ZPAM_AIM_SCORE_RECORD";
			self.aimTarget1.kills_score_record = self.aimTarget1.kills_score;
		}

		self iprintlnbold(text, self.aimTarget1.kills_score);

		self.aimTarget1.kills_score = 0;
	}
}



generateMeNewTargetPosition(reason)
{
	self endon("disconnect");
	self endon("aim_trainer_turnedOff");

	if (!isDefined(self.aimTarget1))
		return;

	// Lock thread
	self.aimTarget1 notify("aim_trainer_target_updated");
	self.aimTarget1 endon("aim_trainer_target_updated");

	// Mode
	weapons["m1carbine_mp"] = 		2;
	weapons["m1garand_mp"] = 		2;
	weapons["thompson_mp"] = 		2;
	weapons["bar_mp"] = 			2;
	weapons["springfield_mp"] = 		  1;
	weapons["greasegun_mp"] = 		2;
	weapons["shotgun_mp"] = 		  1;
	weapons["enfield_mp"] = 		  1;
	weapons["sten_mp"] = 			2;
	weapons["bren_mp"] = 			2;
	weapons["enfield_scope_mp"] = 		  1;
	weapons["mosin_nagant_mp"] = 		  1;
	weapons["SVT40_mp"] = 			2;
	weapons["PPS42_mp"] = 			2;
	weapons["ppsh_stick30_mp"] = 			2;
	weapons["mosin_nagant_sniper_mp"] = 	  1;
	weapons["kar98k_mp"] = 			  1;
	weapons["g43_mp"] = 			2;
	weapons["mp40_mp"] = 			2;
	weapons["mp44_mp"] = 			2;
	weapons["kar98k_sniper_mp"] = 		  1;
	weapons["colt_mp"] = 			2;
	weapons["luger_mp"] = 			2;
	weapons["tt30_mp"] = 			2;
	weapons["webley_mp"] = 			2;
	weapons["mg_mp"] = 			2;

	// "", "missed", "kill"
	if (!isDefined(reason))
		reason = "";

	playSpawnSound = false;

	if (reason == "test")
	{
		if (!isDefined(self.aimTarget1.generateTime))
		{
			self.aimTarget1.origin = self getTargetPos(false);
			self.aimTarget1.generateTime = gettime();
			self.aimTarget1 show();
		}
		self.aimTarget1.kills++;
		return;
	}

	// Mode changed or initialized
	else if (reason == "mode")
	{
		self.aimTarget1 hide();
		self.aimTarget1.origin = (-99999, -99999, -99999);

		self thread handleKillScore();

		wait 1.5;

		self.aimTrainer_startAngles = self.angles;

		playSpawnSound = true;
	}

	if (reason == "missed")
	{
		// Mode 4: Reaction time"
		if (self.aimTrainerMode == 4 && self.aimTarget1.origin == (-99999, -99999, -99999))
		{
			self iprintlnbold(&"ZPAM_AIM_TOO_SOON");
		}

		self.aimTarget1 hide();
		self.aimTarget1.origin = (-99999, -99999, -99999);

		self thread handleKillScore();

		wait 0.1;

		self playlocalsound("aim_trainer_missed_shot");

		wait 0.9;

		self.aimTrainer_startAngles = self.angles;

		playSpawnSound = true;
	}


	if (reason == "timeout")
	{
		self.aimTarget1 hide();
		self.aimTarget1.origin = (-99999, -99999, -99999);
		self.aimTarget1.timeouts++;

		self thread handleKillScore();

		limit = 4;
		if (self.aimTrainerMode == 4) // Mode 4: Reaction time"
			limit = 1;

		if (self.aimTarget1.timeouts >= limit)
		{
			self iprintlnbold(&"ZPAM_AIM_TIME_UP");

			self thread turnOff();
		}


		wait 1;

		self.aimTrainer_startAngles = self.angles;

		playSpawnSound = true;
	}
	else
		self.aimTarget1.timeouts = 0;




	if (reason == "kill")
	{
		react_time = -1;
		if (isDefined(self.aimTarget1.generateTime))
		{
			react_time = (gettime() - self.aimTarget1.generateTime);
			// Because it will be always increment of sv_fps and the ping, add some number to make it dynamic
			react_time += randomint(level.sv_fps);
			// Remove 30 ms ping
			if (react_time > 50) react_time -= 30;

			// Mode 4: Reaction time"
			if (self.aimTrainerMode == 4)
			{
				self iprintlnbold(&"ZPAM_AIM_REACTION", react_time);
			}
			else
			{
				self.aimTarget1.kills_score++;
				self iprintln(&"ZPAM_AIM_REACTION_SCORE", react_time, self.aimTarget1.kills_score);
			}


			if (react_time > 5000)
				self.aimTrainer_startAngles = self.angles;

		}

		playfx(level._effect["aimTargetExplosion"], self.aimTarget1.origin);
		self playlocalsound("aim_trainer_hit");

		self.aimTarget1 hide();
		self.aimTarget1.origin = (-99999, -99999, -99999);
		self.aimTarget1.kills++;
	}
	else
		self.aimTarget1.kills_score = 0;

	wait level.frame;


	weapon = self getcurrentweapon(); // can be none
	if (self isUsingTurret())
		weapon = "mg_mp";

	mode = 1;
	if (isDefined(weapons[weapon]))
		mode = weapons[weapon];

	// Single shot
	if (mode == 1)
	{
		wait 1.6;

		playSpawnSound = true;

		self.aimTrainer_startAngles = self.angles;
	}

	// Automatic
	if (mode == 2)
	{

	}


	randomPosition = true;
	if (self.aimTrainerMode == 4) // Mode 4: Reaction time"
	{
		wait 1;
		wait (randomint(30) / 10);  // 0.0 - 2.9
		self.aimTrainer_startAngles = self.angles;
		randomPosition = false;
	}

	new_target_origin = self.origin;
	warningPrinted = false;
	while(1)
	{
		new_target_origin = self getTargetPos(randomPosition);

		distance = distance(self maps\mp\gametypes\global\player::getEyeOrigin(), new_target_origin);

		// Distance is ok => exit
		if (distance > 80)
			break;

		if (warningPrinted == false)
		{
			self iprintlnbold(&"ZPAM_AIM_STEP_BACK");
			warningPrinted = true;
		}

		wait 0.5;
	}



	timeout = 0.7;
	if (self.aimTrainerMode == 1)
	{
		// Mode 1: Static targets
		self.aimTarget1.origin = new_target_origin;
	}
	else if (self.aimTrainerMode == 2)
	{
		// Mode 2: Moving targets
		self.aimTarget1.origin = new_target_origin;
		self.aimTarget1 thread moving(5);
	}
	else if (self.aimTrainerMode == 3)
	{
		// Mode 3: Moving targets fast
		self.aimTarget1.origin = new_target_origin;
		self.aimTarget1 thread moving(2.5);
	}
	else if (self.aimTrainerMode == 4)
	{
		// Mode 4: Reaction time"
		self.aimTarget1.origin = new_target_origin;
		playSpawnSound = true;
		timeout = 5;
	}


	self.aimTarget1 show();
	self.aimTarget1.generateTime = gettime();

	self thread setKillTimeout(timeout, self.aimTarget1);

	if (playSpawnSound)
		self playlocalsound("aim_trainer_spawn");
}
