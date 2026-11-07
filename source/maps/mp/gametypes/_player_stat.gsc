#include maps\mp\gametypes\global\_global;

init()
{
    if (!isDefined(game["playerstats"]))
    {
      game["playerstats"] = [];
    }

    // Set all players unconnected
    resetConnectedStatus();

    addEventListener("onConnected",       ::onConnected);
    addEventListener("onDisconnect",      ::onDisconnect);
    addEventListener("onConnectedAll",    ::onConnectedAll);
    addEventListener("onJoinedTeam",    ::onJoinedTeam);

    // Minimal team size to count entry kills, 1vX clutches and aces (to ignore 1v1 matches)
    level.stat_round_min_team_size = 2;

    // Time window to trade a death of teammate (ms)
    level.stat_trade_time = 5000;

    // Weapon classes for kills_<class> stats
    level.stat_weapon_classes = getWeaponKillClasses();
}

resetConnectedStatus()
{
  for (i = 0; i < game["playerstats"].size; i++)
  {
    data = game["playerstats"][i];
    if (data["deleted"]) continue;
    game["playerstats"][i]["isConnected"] = false;
  }
}


onConnectedAll()
{
    level thread removeOld();
}

// Remove stats from disconnected players
removeOld()
{
  wait level.frame * 3; // wait untillplayers are fully proccesed on new round

  time = getTime();
  for (i = 0; i < game["playerstats"].size; i++)
  {
    data = game["playerstats"][i];



    if (data["deleted"] || data["isConnected"]) continue;

    // Once the match started, keep them until the map ends: a player restarting his router or PC
    // needs more than 2 minutes to come back
    if (!game["is_public_mode"] && isDefined(game["readyup_first_run"]) && !game["readyup_first_run"]) continue;

    timeout = 2; // wait 5min by default
    if (game["is_public_mode"])
    	timeout = 0.1; // 6sec in public mode
    else if (isDefined(level.in_readyup) && level.in_readyup)
    	timeout = 5;

    // Delete data after x mins
    if ((time - data["lastTime"]) > (timeout * 60 * 1000))
    {
      game["playerstats"][i]["deleted"] = true;

    }
  }
}

findData(name, entityId, ip)
{
  for (i = 0; i < game["playerstats"].size; i++)
  {
    data = game["playerstats"][i];
    if (data["deleted"]) continue;
    if (isDefined(ip) && data["ip"] != ip) continue;

    if (isDefined(entityId))
    {
      if (data["name"] == name && data["entityId"] == entityId)
        return i;
    }
    else
    {
      if (data["name"] == name)
        return i;
    }
  }
  return -1;
}

handleRename()
{
  if (isDefined(self.pers["lastName"]))
  {
    if (self.pers["lastName"] != self.name)
    {

      dataId = findData(self.pers["lastName"], self getEntityNumber(), self getip());
      if (dataId >= 0)
      {
        // A disconnected player owns the new name: keep our stats under the old name, so neither loses them
        dataId2 = findData(self.name);
        if (dataId2 >= 0 && game["playerstats"][dataId2]["isConnected"] == false)
          return;

        game["playerstats"][dataId]["name"] = self.name;
      }

      self.pers["lastName"] = self.name;
    }
  }
  else
    self.pers["lastName"] = self.name;
}


getStatId()
{
  handleRename();

  return findData(self.pers["lastName"], self getEntityNumber(), self getip());
}

onConnected()
{
	handleRename();

	id = self getEntityNumber();

	dataId = findData(self.pers["lastName"], id, self getip());
	if (dataId >= 0 && game["playerstats"][dataId]["isConnected"] == false) // note: isConnected is reseted every map_restart
	{
		game["playerstats"][dataId]["player"] = self;
		game["playerstats"][dataId]["isConnected"] = true;
		game["playerstats"][dataId]["team"] = self.sessionteam;
		game["playerstats"][dataId]["lastTime"] = getTime();

		self thread restoreScore(game["playerstats"][dataId]["kills"], game["playerstats"][dataId]["deaths"]);
	}
	else
	{
		// Player was not found via name and id, give other players connecting in same time time to identified them via name and id before this player will be found only by name.. (to avoid stat steal by duplicating name)
		waittillframeend;

		dataId = findData(self.pers["lastName"], undefined, self getip());
		// same name from another IP is another player; in the middle of a map, a row still connected
		// with the same name and IP is this player's old connection waiting for sv_timeout (999 ping)
		if (dataId >= 0 && (game["playerstats"][dataId]["isConnected"] == false || isDefined(level.allPlayersConnected)))
		{
			game["playerstats"][dataId]["player"] = self;
			game["playerstats"][dataId]["entityId"] = id;
			game["playerstats"][dataId]["isConnected"] = true;
			game["playerstats"][dataId]["team"] = self.sessionteam;
			game["playerstats"][dataId]["lastTime"] = getTime();

			self thread restoreScore(game["playerstats"][dataId]["kills"], game["playerstats"][dataId]["deaths"]);
		}
		else
		{
			// Create new entry
			newIndex = game["playerstats"].size;
			game["playerstats"][newIndex]["id"] = newIndex;
			game["playerstats"][newIndex]["player"] = self;
			game["playerstats"][newIndex]["deleted"] = false;
			game["playerstats"][newIndex]["entityId"] = id;
			game["playerstats"][newIndex]["ip"] = self getip();
			game["playerstats"][newIndex]["name"] = self.pers["lastName"];
			game["playerstats"][newIndex]["team"] = self.sessionteam;
			game["playerstats"][newIndex]["isConnected"] = true;
			game["playerstats"][newIndex]["lastTime"] = getTime();
			game["playerstats"][newIndex]["kills"] = 0;
			game["playerstats"][newIndex]["assists"] = 0;
			game["playerstats"][newIndex]["damage"] = 0;
			game["playerstats"][newIndex]["deaths"] = 0;
			game["playerstats"][newIndex]["score"] = 0.0;
			game["playerstats"][newIndex]["grenades"] = 0;
			game["playerstats"][newIndex]["plants"] = 0;
			game["playerstats"][newIndex]["defuses"] = 0;
			game["playerstats"][newIndex]["damage_dealt"] = 0;
			game["playerstats"][newIndex]["headshots"] = 0;
			game["playerstats"][newIndex]["entry_kills"] = 0;
			game["playerstats"][newIndex]["entry_deaths"] = 0;
			game["playerstats"][newIndex]["aces"] = 0;
			game["playerstats"][newIndex]["round_kills"] = 0;
			game["playerstats"][newIndex]["round_kills_team"] = "";
			game["playerstats"][newIndex]["clutches_max"] = 5;
			for (c = 1; c <= 5; c++)
			{
				game["playerstats"][newIndex]["clutches_won_1v" + c] = 0;
				game["playerstats"][newIndex]["clutches_attempts_1v" + c] = 0;
			}
			for (c = 2; c <= 5; c++)
				game["playerstats"][newIndex]["multi_kills_" + c] = 0;
			game["playerstats"][newIndex]["trade_kills"] = 0;
			game["playerstats"][newIndex]["traded_deaths"] = 0;
			game["playerstats"][newIndex]["round_trade_kills"] = 0;
			game["playerstats"][newIndex]["round_traded_deaths"] = 0;
			classes = level.stat_weapon_classes;
			for (c = 0; c < classes.size; c++)
			{
				game["playerstats"][newIndex]["kills_" + classes[c]] = 0;
				game["playerstats"][newIndex]["round_kills_" + classes[c]] = 0;
			}
		}
	}

}

onJoinedTeam(team)
{
	dataId = findData(self.pers["lastName"], self getEntityNumber(), self getip());
	if (dataId >= 0)
	{
		game["playerstats"][dataId]["team"] = team;
	}
}


onDisconnect()
{
  handleRename();

  dataId = findData(self.pers["lastName"], self getEntityNumber(), self getip());
  if (dataId >= 0)
  {
    game["playerstats"][dataId]["isConnected"] = false;
    game["playerstats"][dataId]["player"] = undefined;
    game["playerstats"][dataId]["lastTime"] = getTime();
  }
}


restoreScore(kills, deaths)
{
  self endon("disconnect");

  wait level.frame; // wait untill score if properly initialized

  if (self.score == 0 && self.deaths == 0)
  {
    self.pers["score"] = kills;
    self.score = kills;

    self.pers["deaths"] = deaths;
    self.deaths = deaths;
  }
}


AddScore(score)
{
    dataId = self getStatId();
    if (dataId >= 0)
    {
      game["playerstats"][dataId]["score"] += score;
    }
}

AddAssist()
{
    dataId = self getStatId();
    if (dataId >= 0)
    {
      game["playerstats"][dataId]["assists"] += 1;
    }
}

AddDamage(iDamage)
{
    dataId = self getStatId();
    if (dataId >= 0)
    {
      game["playerstats"][dataId]["damage"] += iDamage;
    }
}


AddKill()
{
    dataId = self getStatId();
    if (dataId >= 0)
    {
      game["playerstats"][dataId]["kills"] += 1;
    }
}

AddDeath()
{
    dataId = self getStatId();
    if (dataId >= 0)
    {
      game["playerstats"][dataId]["deaths"] += 1;
    }
}

AddGrenade()
{
    dataId = self getStatId();
    if (dataId >= 0)
    {
      game["playerstats"][dataId]["grenades"] += 1;
    }
}

AddPlant()
{
    dataId = self getStatId();
    if (dataId >= 0)
    {
      game["playerstats"][dataId]["plants"] += 1;
    }
}

AddDefuse()
{
    dataId = self getStatId();
    if (dataId >= 0)
    {
      game["playerstats"][dataId]["defuses"] += 1;
    }
}

// Real HP damage dealt to enemy, capped by the victim's remaining health so overkill is not counted
// Must be called before finishPlayerDamage is applied
AddDamageDealt(iDamage, victim)
{
    if (iDamage < 1)
      iDamage = 1;
    if (iDamage > victim.health)
      iDamage = victim.health;
    if (iDamage <= 0)
      return;

    dataId = self getStatId();
    if (dataId >= 0)
    {
      game["playerstats"][dataId]["damage_dealt"] += iDamage;
    }
}

AddHeadshot()
{
    dataId = self getStatId();
    if (dataId >= 0)
    {
      game["playerstats"][dataId]["headshots"] += 1;
    }
}

// Weapon classes for kills_<class> stats (saved in level.stat_weapon_classes)
getWeaponKillClasses()
{
    classes = [];
    classes[classes.size] = "smg";
    classes[classes.size] = "assault";
    classes[classes.size] = "rifle";
    classes[classes.size] = "scope";
    classes[classes.size] = "shotgun";
    classes[classes.size] = "secondary";
    classes[classes.size] = "grenade";
    classes[classes.size] = "knife";
    classes[classes.size] = "other";
    return classes;
}

// self is attacker
getWeaponKillClass(sWeapon, sMeansOfDeath)
{
    if (sMeansOfDeath == "MOD_MELEE")
      return "knife";

    // Same rule as grenades stat
    if (sMeansOfDeath == "MOD_GRENADE_SPLASH")
      return "grenade";

    // Mounted MG - game may report weapon in hands instead of the MG
    if (self isUsingTurret())
      return "other";

    if (maps\mp\gametypes\_weapons::isPistol(sWeapon))
      return "secondary";

    // FG42 is automatic rifle (in zPAM weapon classes it is smg)
    if (sWeapon == "fg42_mp")
      return "assault";

    if (maps\mp\gametypes\_weapons::isMainWeapon(sWeapon))
    {
      switch(level.weapons[sWeapon].classname)
      {
        case "smg":           return "smg";
        case "mg":            return "assault";
        case "boltaction":
        case "semiautomatic": return "rifle";
        case "sniper":        return "scope";
        case "shotgun":       return "shotgun";
      }
    }

    // Mounted MGs, unknown weapons
    return "other";
}

// self is attacker, called for every counted enemy kill
AddWeaponKill(sWeapon, sMeansOfDeath)
{
    dataId = self getStatId();
    if (dataId < 0)
      return;

    weaponClass = self getWeaponKillClass(sWeapon, sMeansOfDeath);

    // In round based gametypes kills are added to totals when round ends (round cut by map_restart is not counted)
    if (isRoundActive())
      game["playerstats"][dataId]["round_kills_" + weaponClass] += 1;
    else
      game["playerstats"][dataId]["kills_" + weaponClass] += 1;
}



/*
Round based stats (entry kills, aces, clutches, multi-kills, trades) - used in SD and RE
Flow:
  RoundStarted()          - when round goes live (after strat time)
  AddRoundKill(victim)    - for every enemy kill counted into stats
  UpdateClutch()          - every time alive players are recounted
  RoundEnded(roundwinner) - when round ends
*/

RoundStarted()
{
    level.stat_round_active = true;
    level.stat_round_entry_done = false;
    level.stat_round_clutch = [];
    level.stat_round_clutch_enemies = [];
    level.stat_round_team_size = [];
    level.stat_round_team_size["allies"] = 0;
    level.stat_round_team_size["axis"] = 0;
    level.stat_round_open_deaths = [];

    updateRoundTeamSize();

    classes = level.stat_weapon_classes;
    for (i = 0; i < game["playerstats"].size; i++)
    {
      game["playerstats"][i]["round_kills"] = 0;
      game["playerstats"][i]["round_kills_team"] = "";
      game["playerstats"][i]["round_trade_kills"] = 0;
      game["playerstats"][i]["round_traded_deaths"] = 0;
      for (c = 0; c < classes.size; c++)
        game["playerstats"][i]["round_kills_" + classes[c]] = 0;
    }
}

// Team size is the max count of alive players seen in round
// (with strat time 0 players may not be spawned yet when round starts, so its updated also on kills)
updateRoundTeamSize()
{
    alive["allies"] = 0;
    alive["axis"] = 0;

    players = getentarray("player", "classname");
    for(i = 0; i < players.size; i++)
    {
      player = players[i];
      if ((player.pers["team"] == "allies" || player.pers["team"] == "axis") && player.sessionstate == "playing")
        alive[player.pers["team"]]++;
    }

    if (alive["allies"] > level.stat_round_team_size["allies"])
      level.stat_round_team_size["allies"] = alive["allies"];
    if (alive["axis"] > level.stat_round_team_size["axis"])
      level.stat_round_team_size["axis"] = alive["axis"];
}

isRoundActive()
{
    return isDefined(level.stat_round_active) && level.stat_round_active;
}

// self is attacker
AddRoundKill(victim)
{
    if (!isRoundActive())
      return;

    // Victim is still counted as alive here
    updateRoundTeamSize();

    dataId = self getStatId();
    victimId = victim getStatId();
    if (dataId >= 0)
    {
      game["playerstats"][dataId]["round_kills"] += 1;
      game["playerstats"][dataId]["round_kills_team"] = victim.pers["team"];
    }

    addTrade(dataId, victimId);

    // First kill of the round
    if (!level.stat_round_entry_done &&
        level.stat_round_team_size["allies"] >= level.stat_round_min_team_size &&
        level.stat_round_team_size["axis"] >= level.stat_round_min_team_size)
    {
      level.stat_round_entry_done = true;

      if (dataId >= 0)
        game["playerstats"][dataId]["entry_kills"] += 1;

      if (victimId >= 0)
        game["playerstats"][victimId]["entry_deaths"] += 1;
    }
}

// Save 1vX situation when player becomes the last alive player of his team
UpdateClutch()
{
    if (!isRoundActive() || level.roundended)
      return;

    // Catch players spawned after round start (strat time 0) even if no kill was counted yet
    updateRoundTeamSize();

    alive["allies"] = [];
    alive["axis"] = [];
    players = getentarray("player", "classname");
    for(i = 0; i < players.size; i++)
    {
      player = players[i];
      if ((player.pers["team"] == "allies" || player.pers["team"] == "axis") && player.sessionstate == "playing")
        alive[player.pers["team"]][alive[player.pers["team"]].size] = player;
    }

    teams[0] = "allies";
    teams[1] = "axis";
    for (t = 0; t < teams.size; t++)
    {
      team = teams[t];
      enemy = "axis";
      if (team == "axis") enemy = "allies";

      if (isDefined(level.stat_round_clutch[team]))
        continue;
      if (level.stat_round_team_size[team] < level.stat_round_min_team_size)
        continue;
      if (alive[team].size != 1 || alive[enemy].size < 1)
        continue;

      dataId = alive[team][0] getStatId();
      if (dataId < 0)
        continue;

      level.stat_round_clutch[team] = dataId;
      level.stat_round_clutch_enemies[team] = alive[enemy].size;
    }
}

// Trade - kill of enemy who killed a teammate in last 5 seconds
// Each death can be traded only once, player cannot trade his own death (e.g. by grenade thrown before death)
addTrade(killerId, victimId)
{
    time = getTime();
    traded = false;

    openDeaths = [];
    for (i = 0; i < level.stat_round_open_deaths.size; i++)
    {
      death = level.stat_round_open_deaths[i];

      // Too old to be traded
      if ((time - death.time) > level.stat_trade_time)
        continue;

      // Victim of this kill killed a teammate of the killer
      if (victimId >= 0 && death.killerId == victimId)
      {
        // Killer avenged his own death - not a trade, death stays untraded
        if (death.victimId == killerId)
          continue;

        game["playerstats"][death.victimId]["round_traded_deaths"] += 1;
        traded = true;
        continue;
      }

      openDeaths[openDeaths.size] = death;
    }

    if (traded && killerId >= 0)
      game["playerstats"][killerId]["round_trade_kills"] += 1;

    // This death can be traded by victim's teammates
    if (killerId >= 0 && victimId >= 0)
    {
      death = spawnstruct();
      death.killerId = killerId;
      death.victimId = victimId;
      death.time = time;
      openDeaths[openDeaths.size] = death;
    }

    level.stat_round_open_deaths = openDeaths;
}

RoundEnded(roundwinner)
{
    if (!isRoundActive())
      return;
    level.stat_round_active = false;

    // Clutches - won only if player's team won the round
    teams[0] = "allies";
    teams[1] = "axis";
    for (t = 0; t < teams.size; t++)
    {
      team = teams[t];
      if (!isDefined(level.stat_round_clutch[team]))
        continue;

      enemies = level.stat_round_clutch_enemies[team];
      dataId = level.stat_round_clutch[team];

      // 1v1 - 1v5 are inited on connect, bigger situations (6v6 etc.) are created on demand
      if (!isDefined(game["playerstats"][dataId]["clutches_won_1v" + enemies]))
      {
        game["playerstats"][dataId]["clutches_won_1v" + enemies] = 0;
        game["playerstats"][dataId]["clutches_attempts_1v" + enemies] = 0;
        if (enemies > game["playerstats"][dataId]["clutches_max"])
          game["playerstats"][dataId]["clutches_max"] = enemies;
      }

      game["playerstats"][dataId]["clutches_attempts_1v" + enemies] += 1;
      if (roundwinner == team)
        game["playerstats"][dataId]["clutches_won_1v" + enemies] += 1;
    }

    // Aces - player killed every enemy that was alive at round start
    for (i = 0; i < game["playerstats"].size; i++)
    {
      data = game["playerstats"][i];
      if (data["deleted"] || data["round_kills_team"] == "")
        continue;

      enemyCount = level.stat_round_team_size[data["round_kills_team"]];
      if (enemyCount >= level.stat_round_min_team_size && data["round_kills"] >= enemyCount)
        game["playerstats"][i]["aces"] += 1;
    }

    // Multi-kills, trades and weapon kills of finished round are added to totals
    classes = level.stat_weapon_classes;
    for (i = 0; i < game["playerstats"].size; i++)
    {
      data = game["playerstats"][i];
      if (data["deleted"])
        continue;

      // One bucket per round - 2, 3, 4 or 5+ kills
      kills = data["round_kills"];
      if (kills > 5)
        kills = 5;
      if (kills >= 2)
        game["playerstats"][i]["multi_kills_" + kills] += 1;

      game["playerstats"][i]["trade_kills"] += data["round_trade_kills"];
      game["playerstats"][i]["traded_deaths"] += data["round_traded_deaths"];

      for (c = 0; c < classes.size; c++)
        game["playerstats"][i]["kills_" + classes[c]] += data["round_kills_" + classes[c]];
    }
}


// One "Stats;" line per player row in games_mp.log, with the match totals so far (read the last one)
// Format: Stats;<name>;<team>;key=value;...
logStats()
{
    keys = [];
    keys[keys.size] = "kills"; keys[keys.size] = "deaths"; keys[keys.size] = "assists";
    keys[keys.size] = "damage_dealt"; keys[keys.size] = "headshots"; keys[keys.size] = "grenades";
    keys[keys.size] = "plants"; keys[keys.size] = "defuses";
    keys[keys.size] = "entry_kills"; keys[keys.size] = "entry_deaths"; keys[keys.size] = "aces";
    keys[keys.size] = "trade_kills"; keys[keys.size] = "traded_deaths";
    for (c = 2; c <= 5; c++)
      keys[keys.size] = "multi_kills_" + c;
    for (c = 0; c < level.stat_weapon_classes.size; c++)
      keys[keys.size] = "kills_" + level.stat_weapon_classes[c];

    for (i = 0; i < game["playerstats"].size; i++)
    {
      data = game["playerstats"][i];
      if (data["deleted"])
        continue;

      line = "Stats;" + logSafe(data["name"]) + ";" + data["team"];
      for (k = 0; k < keys.size; k++)
        line += ";" + keys[k] + "=" + data[keys[k]];
      for (c = 1; c <= data["clutches_max"]; c++)
        if (isDefined(data["clutches_won_1v" + c]))
          line += ";clutches_1v" + c + "=" + data["clutches_won_1v" + c] + "/" + data["clutches_attempts_1v" + c];
      logPrint(line + "\n");
    }
}
