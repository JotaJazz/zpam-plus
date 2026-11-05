#include maps\mp\gametypes\global\_global;

// Gametype functions with the same body in ctf, dm, htf, hq, re, sd and tdm.
// Included by those files: fix them here, not in a copy.

HUD_StratTime(time)
{
	if (time <= 0)
		return;

	// Strat Time
	strattime = addHUD(0, 450, 2, (.98, .827, .58), "center", "bottom", "center_safearea", "top");
	strattime setText(game["STRING_STRAT_TIME"]);

	// 0:05
	strat_clock = addHUD(0, 445, 2, (.98, .827, .58), "center", "top", "center_safearea", "top");
	strat_clock setTimer(time);


	// Wait untill time expired or timeout was called
	level waittill("strat_time_end");


	strattime FadeOverTime(0.5);
	strattime.alpha = 0;

	strat_clock FadeOverTime(0.5);
	strat_clock.alpha = 0;

	strat_clock moveovertime(0.5);
	strat_clock.x = -40;

	wait level.fps_multiplier * 0.5;

	strattime destroy2();
	strat_clock destroy2();
}

strattime_end_timer(time)
{
	level endon("strat_time_end");

	wait level.fps_multiplier * time;

	level notify("strat_time_end");
}

strattime_end_ontimeout()
{
	level endon("strat_time_end");

	level waittill("running_timeout");

	level notify("strat_time_end");
}
