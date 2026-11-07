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
    // needs more than 2 minutes to come back (upstream 71c7c8d)
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
