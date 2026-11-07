// Replaces ';' with ':' so a player name cannot add fields to a log line
logSafe(string)
{
	result = "";
	for (i = 0; i < string.size; i++)
	{
		if (string[i] == ";")
			result += ":";
		else
			result += string[i];
	}
	return result;
}

// String starts with substring
startsWith(string, substring)
{
	if (substring.size > string.size)
		return false;
	for (i = 0; i < string.size && i < substring.size; i++)
	{
		if (string[i] != substring[i])
		{
			return false;
		}
	}
	return true;
}

// String contains a substring
contains(string, substring)
{
	if (substring.size > string.size)
		return false;
	for (i = 0; i < string.size - (substring.size - 1); i++)
	{
		match = true;
		for (j = 0; j < substring.size; j++)
		{
			if (string[i+j] != substring[j])
			{
				match = false;
				break;
			}
		}
		if (match)
			return true;
	}
	return false;
}

// If string contain just numbers, return true
// If string starts with dash and number, like -1337, true is returned
isDigitalNumber(string)
{
	if (string.size == 0)
		return false;

	for (i = 0; i < string.size; i++)
	{
		char = string[i];
		charNext = "";
		if ((i+1) < string.size)
			charNext = string[i+1];

		if (isDigit(char)  ||  (i == 0 && char == "-" && isDigit(charNext)))
			continue;

		return false;
	}

	return true;
}

isDigit(char)
{
	if (char == "0" ||
	    char == "1" ||
	    char == "2" ||
	    char == "3" ||
	    char == "4" ||
	    char == "5" ||
	    char == "6" ||
	    char == "7" ||
	    char == "8" ||
	    char == "9")
	{
		return true;
	}
	return false;
}

// Return array with separated items
splitString(string, delimiter)
{
	if (delimiter == "")
		return string;

	array = [];
	buffer = "";
	for (i = 0; i <= string.size; i++)
	{
		char = "";

		match = true;
		if (i < string.size)
		{
			char = string[i];
			for (j = 0; j < delimiter.size; j++)
			{
				if (i + j >= string.size || string[i+j] != delimiter[j])
				{
					match = false;
					break;
				}
			}
		}

		if (match)
		{
			if (buffer != "")
			{
				array[array.size] = buffer;
				buffer = "";
			}
			i += delimiter.size - 1;
		}
		else
			buffer += char;
	}
	return array;
}


// Remove ^1 colors from string
// may be like: "ahoj^1kokos^^25pica^^^123neco_^^^^1234_^nic^^kok^^1os^^1p2a"
// clean:      	"ahoj^1kokos^5pica^3neco_^4_^nic^^kok^os^p2a"
removeColorsFromString(string, keepSingleColors)
{
	clean = "";

	if (!isDefined(string))
		return clean;

	maxLevel = -1;
	if (isDefined(keepSingleColors))
		maxLevel = 0;

	deepLevel = 0;
	charLast = "";
	for (j = 0; j < string.size; j++)
	{
		char = string[j];

		if (char == "^")
		{
			deepLevel++;
		}
		else if (isDigit(char))
		{
			if (deepLevel > 0)
			{
				deepLevel--;
				if (deepLevel == maxLevel)
					clean += "^" + char;
			}
			else
				clean += char;
		}
		else
		{
			for (; deepLevel > 0; deepLevel--)
				clean += "^";
			clean += char;
		}
	}

	return clean;
}

// Prints second in format 00:00:00 (hours are printed only if > 0)
formatTime(timeSec, separator)
{
	if (!isDefined(separator)) separator = ":";
	timeSec = int(timeSec); // to avoid unmatching types 'float' and 'int'
	str = "";
	min = int(timeSec / 60);
	hour = int(min / 60);
	sec = timeSec % 60;
	if (hour > 0)
	{
		if (hour < 10) hour = "0" + hour;
		min = min % 60;
		str += hour + separator;
	}
	if (min < 10) min = "0" + min;
	if (sec < 10) sec = "0" + sec;

	str += min + separator;
	str += sec;

	return str;
}

// Add char 's' to the end of the string if num is > 1
plural_s(num, text)
{
	if (num > 1)
		text += "s";
	return num + " " + text;
}

// Format the number into specified number of decimal places
format_fractional(num, fixedPositions, precision)
{
	// Is negative number
	num2 = num;
	if (num < 0)
		num2 *= -1;

	// Get the fraction part as integer formated to 9 places
	fraction = "" + int((num2 - int(num2)) * 1000000000);
	fraction2 = "000000000" + fraction;
	fraction2 = getsubstr(fraction2, fraction2.size - 9);
	fraction2 = getsubstr(fraction2, 0, precision);

	// Format the whole number
	whole = "" + int(num2);
	if (whole.size < fixedPositions)
	{
		whole = "000000000" + whole;
		whole = getsubstr(whole, whole.size - fixedPositions);
	}

	sign = "";
	if (num < 0)
		sign = "-";

	return sign + whole + "." + fraction2;
}

// Runs only with developer_script 1
selfTest()
{
	if (!startsWith("abc", "ab"))
		assertMsg("string selfTest: startsWith abc/ab");
	if (startsWith("ab", "abc"))
		assertMsg("string selfTest: startsWith ab/abc");
	if (!isDigitalNumber("12"))
		assertMsg("string selfTest: 12");
	if (!isDigitalNumber("-5"))
		assertMsg("string selfTest: -5");
	if (isDigitalNumber("x5"))
		assertMsg("string selfTest: x5");
	if (isDigitalNumber("5x"))
		assertMsg("string selfTest: 5x");
	if (isDigitalNumber(""))
		assertMsg("string selfTest: empty");
	if (isDigitalNumber("-"))
		assertMsg("string selfTest: dash");
	if (logSafe("a;b;;c") != "a:b::c")
		assertMsg("string selfTest: logSafe a;b;;c");
	if (logSafe("") != "")
		assertMsg("string selfTest: logSafe empty");
	if (logSafe("abc") != "abc")
		assertMsg("string selfTest: logSafe abc");
	if (!hasBindPattern("a[{+attack}]b"))
		assertMsg("string selfTest: bind +attack");
	if (!hasBindPattern("[{x}]"))
		assertMsg("string selfTest: bind x");
	if (hasBindPattern("[{}]"))
		assertMsg("string selfTest: bind empty");
	if (hasBindPattern("}][{x"))
		assertMsg("string selfTest: bind reversed");
	if (hasBindPattern("[x]{y}"))
		assertMsg("string selfTest: bind plain brackets");
}

// True if string has "[{" followed later by "}]" with at least one character between them,
// which the client draws as a key binding
hasBindPattern(string)
{
	for (o = 0; o + 1 < string.size; o++)
	{
		if (string[o] != "[" || string[o + 1] != "{")
			continue;
		for (c = o + 3; c + 1 < string.size; c++)
			if (string[c] == "}" && string[c + 1] == "]")
				return true;
	}
	return false;
}
