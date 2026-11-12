local Config = {}

Config.DataStoreName = "DailyRewards_v1"
Config.CooldownSeconds = 24 * 60 * 60
Config.StreakResetSeconds = 48 * 60 * 60
Config.RateLimitSeconds = 1
Config.MaxUsedCodes = 200

-- Array index == day number. Keep 7 entries or the streak maths shifts.
Config.DailyRewards = {
	{ Coins = 100 },
	{ Coins = 150 },
	{ Coins = 200 },
	{ Coins = 300 },
	{ Coins = 400 },
	{ Coins = 600 },
	{ Coins = 1000 },
}

Config.Codes = {
	FREE100 = { Coins = 100, Active = true },
	WEEK7 = { Coins = 700, Active = true },
	OLDCODE = { Coins = 500, Active = false },
}

return Config
