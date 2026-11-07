#include maps\mp\gametypes\global\_global;

Load()
{
	game["ruleCvars"] = GetCvars(game["ruleCvars"]);
}

GetCvars(arr)
{
	arr = ruleCvarDefault(arr, "scr_overtime", 0);	// A tie stays a tie

	return arr;
}
