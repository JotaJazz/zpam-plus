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

		for (j = 0; j < separes.size; j++)
		{
			// If there is no more substrings for this player-name, break
			if (!isDefined(separes[j]) || !isDefined(separes[j][i]))
				continue;

			// Remove already defined items
			separes_clean = removeSameItems(separes[j][i]);

			for (k = 0; k < separes_clean.size; k++)
			{
				exists_in_array = false;
				for (l = 0; l < separes_marged[i].size; l++)
				{
					if (ToLower(separes_marged[i][l]) == ToLower(separes_clean[k]))
					{
						// We found word already in "separes_marged[i]" array - so count up
						separes_marged_count[i][l]++;
						exists_in_array = true;
						break;
					}
				}
				if (!exists_in_array)
				{
					// If this word does not exist in array, add it
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
    index = 0;

    for (i = 0; i < array.size; i++)
    {
        // Loop array to check if word already exists
        item_already_exists = false;
        for (j = 0; j < array_to_return.size; j++)
        {
            if (array_to_return[j] == array[i])
            {
                item_already_exists = true;
                break;
            }
        }

        if (item_already_exists)
            continue;

        array_to_return[index] = array[i];
        index++;
    }

    return array_to_return;
}
