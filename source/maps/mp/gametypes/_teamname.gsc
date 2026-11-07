#include maps\mp\gametypes\global\_global;


Init()
{
	// Team names
	level.teamname_allies = "";
	level.teamname_axis = "";

	level.teamname["allies"] = "";
	level.teamname["axis"] = "";

	// Team names are updated only if its needed for other functions (matchinfo, recording, ...)
}


// Generate team names for specified team
// Called from multiple places
refreshTeamName(team)
{
  if (team == "allies")
  {
    level.teamname_allies = getTeamName(team);
    level.teamname["allies"] = level.teamname_allies;
    return level.teamname_allies;
  }
  else if (team == "axis")
  {
    level.teamname_axis = getTeamName(team);
    level.teamname["axis"] = level.teamname_axis;
    return level.teamname_axis;
  }
  return "";
}


getTeamName(team)
{
	// A ladder match brings its own team names
	ladderName = maps\mp\gametypes\_ladder::teamName(team);
	if (ladderName != "")
		return ladderName;

	names = [];

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		// If team is not set, generate team name from all players
		if (isDefined(player.pers["team"]) && (player.pers["team"] == team || team == ""))
		{
			name_clean = removeColorsFromString(player.name);
			names[names.size] = name_clean;
		}
	}

	return getBestNameFromArray(names);
}

getBestNameFromArray(names)
{
    if (names.size == 0)
    {
        return ""; // EMPTYTEAM
    }
    else if (names.size == 1)
    {
        return names[0];
    }

	perc = 0.9;

	// Save length of the longest name
	maxLength = 0;
	for (i = 0; i < names.size; i++)
	{
		if (names[i].size > maxLength)
			maxLength = names[i].size;
	}


	// Create arrays of substrings from name
	separes = [];
	for(i = 0; i < names.size; i++)
	{
		name = names[i];
		separes[i] = [];

		for (j = 0; j < name.size; j++)
		{
			index = name.size - 1 - j;
			separes[i][index] = [];

			for (k = 0; k < j+1; k++)
			{
				substring = getsubstr(name, k, name.size - j + k);
				separes[i][index][k] = substring;
			}
		}
	}

	// Marge name separes
	separes_marged = [];
	separes_marged_count = [];
	for(i = 0; i < maxLength; i++)
	{
		separes_marged[i] = [];
		separes_marged_count[i] = [];
		marged_index = []; // "_" + ToLower(word) -> its index in separes_marged[i]

		for (j = 0; j < separes.size; j++)
		{
			// If there is no more substrings for this player-name, break
			if (!isDefined(separes[j]) || !isDefined(separes[j][i]))
				continue;

			// Remove already defined items
			separes_clean = removeSameItems(separes[j][i]);

			for (k = 0; k < separes_clean.size; k++)
			{
				key = "_" + ToLower(separes_clean[k]);
				if (isDefined(marged_index[key]))
				{
					// We found word already in "separes_marged[i]" array - so count up
					separes_marged_count[i][marged_index[key]]++;
				}
				else
				{
					// If this word does not exist in array, add it
					marged_index[key] = separes_marged[i].size;
					separes_marged[i][separes_marged[i].size] = separes_clean[k];
					separes_marged_count[i][separes_marged_count[i].size] = 1;
				}
			}
		}
	}


	// Find the most used word in marged separes and save it
	most_used_word = [];
	most_used_count = [];
	for (i = 0; i < separes_marged.size; i++)
	{
		last_word = "";
		last_count = 0;
		for(j = 0; j < separes_marged[i].size; j++)
		{
			if (separes_marged_count[i][j] > last_count)
			{
				last_count = separes_marged_count[i][j];
				last_word = separes_marged[i][j];
			}
		}

		most_used_word[i] = last_word;
		most_used_count[i] = last_count;
	}

	table_array = [];
	final_word = "";
	for (i = names.size-1;   i >= 0 && final_word == "";   i--)
	{
		// Find words with exact usage as there is players
		for (j = most_used_count.size-1; j >= 0; j--)
		{
			if (most_used_count[j] == i+1)
			{
				value = most_used_count[j] * most_used_word[j].size;

				for (k = 0; k < value; k++)
				{
					table_array[table_array.size] = most_used_word[j];
				}
				break;
			}
		}
	}

	if (table_array.size == 0)
	{
		table_array[0] = "";
	}

	// Find the final most used word by percentage
	index = int(table_array.size * 0.3);
	final_word = table_array[index];

	// Remove unallowed chars
	final_word = getSecureString(final_word);
	final_word = removeEndSymbols(final_word);

    return final_word;
}

getSecureString(string)
{
	// Remove chars that cannot be used in team name
	string_secure = "";
	allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789=-+_#!.|?<>()[]{}:/\\";

	for (j = 0; j < string.size; j++)
	{
		saveChar = false;
		for (i = 0; i < allowedChars.size; i++)
		{
			if (allowedChars[i] == string[j])
				saveChar = true;
		}

		if (saveChar)
			string_secure += string[j];
	}

	return string_secure;
}

removeEndSymbols(string)
{
	// Remove chars that cannot be used in team name
	alfanumericChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

	if (string.size <= 2) return string;

	charLast = string[string.size - 1];
	charLast2 = string[string.size - 2];

	charLast_alfanumeric = false;
	for (i = 0; i < alfanumericChars.size; i++)
	{
		if (alfanumericChars[i] == charLast)
		{
			charLast_alfanumeric = true;
			break;
		}
	}

	charLast2_alfanumeric = false;
	for (i = 0; i < alfanumericChars.size; i++)
	{
		if (alfanumericChars[i] == charLast2)
		{
			charLast2_alfanumeric = true;
			break;
		}
	}

	// Remove last non-alfanumeric char
	if (charLast_alfanumeric == false && charLast2_alfanumeric)
	{
		return getsubstr(string, 0, string.size - 1);
	}

	return string;
}

removeSameItems(array)
{
    array_to_return = [];
    seen = []; // "_" + item, so numeric items never collide with integer indices

    for (i = 0; i < array.size; i++)
    {
        key = "_" + array[i];
        if (isDefined(seen[key]))
            continue;

        seen[key] = true;
        array_to_return[array_to_return.size] = array[i];
    }

    return array_to_return;
}

// Runs only with developer_script 1. Expected values were recorded from the
// quadratic version this replaced.
teamnameSelfTest()
{
	c = []; c[0] = "TLS|abc"; c[1] = "TLS|def"; c[2] = "TLS|ghi";
	if (getBestNameFromArray(c) != "TLS") assertMsg("teamname selfTest: TLS|abc,TLS|def,TLS|ghi");
	c = []; c[0] = "ABC|x"; c[1] = "abc|y"; c[2] = "Abc|z";
	if (getBestNameFromArray(c) != "ABC") assertMsg("teamname selfTest: ABC|x,abc|y,Abc|z");
	c = []; c[0] = "a"; c[1] = "b";
	if (getBestNameFromArray(c) != "a") assertMsg("teamname selfTest: a,b");
	c = []; c[0] = "123x"; c[1] = "123y";
	if (getBestNameFromArray(c) != "123") assertMsg("teamname selfTest: 123x,123y");
	c = []; c[0] = "solo";
	if (getBestNameFromArray(c) != "solo") assertMsg("teamname selfTest: solo");
	c = []; c[0] = "abAB"; c[1] = "cd";
	if (getBestNameFromArray(c) != "ab") assertMsg("teamname selfTest: abAB,cd");
	c = []; c[0] = "xAbab"; c[1] = "yabAb"; c[2] = "Q";
	if (getBestNameFromArray(c) != "Abab") assertMsg("teamname selfTest: xAbab,yabAb,Q");
	c = [];
	if (getBestNameFromArray(c) != "") assertMsg("teamname selfTest: empty");

	// 10 distinct 32-character names: the worst case of a full team in one frame
	alphabet = "abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz0123456789";
	c = [];
	for (i = 0; i < 10; i++)
		c[i] = "TLS|" + getsubstr(alphabet, i, i + 28);
	if (getBestNameFromArray(c) != "ijklmnopqrstuvwxyz01") assertMsg("teamname selfTest: 10 names of 32 chars");
}
