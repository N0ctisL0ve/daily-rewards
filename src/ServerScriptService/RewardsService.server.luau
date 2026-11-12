local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local DataManager = require(ServerScriptService:WaitForChild("DataManager"))

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local function ensureRemote(className, name)
	local existing = remotesFolder:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local remote = Instance.new(className)
	remote.Name = name
	remote.Parent = remotesFolder
	return remote
end

local claimDaily = ensureRemote("RemoteFunction", "ClaimDaily")
local redeemCode = ensureRemote("RemoteFunction", "RedeemCode")
local dataUpdated = ensureRemote("RemoteEvent", "DataUpdated")

local lastRequestAt = {}

local function formatClock(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
end

local function rateLimited(player)
	local now = os.clock()
	local last = lastRequestAt[player.UserId]
	if last and now - last < Config.RateLimitSeconds then
		return true
	end
	lastRequestAt[player.UserId] = now
	return false
end

local function nextClaimAt(profile)
	if profile.LastClaimTime == 0 then
		return 0
	end
	local expiresAt = profile.LastClaimTime + Config.CooldownSeconds
	if os.time() >= expiresAt then
		return 0
	end
	return expiresAt
end

local function pushData(player)
	local profile = DataManager.Get(player)
	if not profile then
		return
	end

	dataUpdated:FireClient(player, {
		Coins = profile.Coins,
		Streak = profile.Streak,
		NextClaimAt = nextClaimAt(profile),
	})
end

local function claimReward(player)
	if rateLimited(player) then
		return { ok = false, message = "Slow down, one request per second." }
	end

	local profile = DataManager.Get(player)
	if not profile then
		return { ok = false, message = "Data is still loading." }
	end

	local now = os.time()
	local elapsed = now - profile.LastClaimTime

	if profile.LastClaimTime > 0 and elapsed < Config.CooldownSeconds then
		return {
			ok = false,
			message = ("Next reward in %s."):format(formatClock(Config.CooldownSeconds - elapsed)),
			nextClaimAt = profile.LastClaimTime + Config.CooldownSeconds,
		}
	end

	-- Past 48h the ladder drops back to day 1 even if the player only ever missed one day.
	local day
	if profile.LastClaimTime == 0 or elapsed > Config.StreakResetSeconds then
		day = 1
	else
		day = (profile.Streak % #Config.DailyRewards) + 1
	end

	local reward = Config.DailyRewards[day]
	if not reward then
		return { ok = false, message = "Reward table is broken." }
	end

	local oldCoins = profile.Coins
	local oldStreak = profile.Streak
	local oldClaimTime = profile.LastClaimTime

	profile.Coins = oldCoins + reward.Coins
	profile.Streak = day
	profile.LastClaimTime = now

	if not DataManager.Save(player) then
		profile.Coins = oldCoins
		profile.Streak = oldStreak
		profile.LastClaimTime = oldClaimTime
		return { ok = false, message = "Save failed, nothing was granted." }
	end

	pushData(player)

	return {
		ok = true,
		message = ("Day %d claimed, +%d coins."):format(day, reward.Coins),
		coins = profile.Coins,
		streak = day,
		nextClaimAt = profile.LastClaimTime + Config.CooldownSeconds,
	}
end

local function normalizeCode(raw)
	if typeof(raw) ~= "string" then
		return nil
	end

	local code = string.upper((string.gsub(raw, "%s+", "")))
	if #code == 0 or #code > 32 then
		return nil
	end

	return code
end

local function redeem(player, raw)
	local code = normalizeCode(raw)
	if not code then
		return { ok = false, message = "Invalid code format." }
	end

	if rateLimited(player) then
		return { ok = false, message = "Slow down, one request per second." }
	end

	local entry = Config.Codes[code]
	if typeof(entry) ~= "table" or not entry.Active then
		return { ok = false, message = "Code is invalid or expired." }
	end

	local profile = DataManager.Get(player)
	if not profile then
		return { ok = false, message = "Data is still loading." }
	end

	if table.find(profile.UsedCodes, code) then
		return { ok = false, message = "This code was already used." }
	end

	local coins = math.max(0, math.floor(tonumber(entry.Coins) or 0))
	local oldCoins = profile.Coins

	-- Burn the code before paying out. A duplicated invoke then hits the UsedCodes check instead of double paying.
	table.insert(profile.UsedCodes, code)
	profile.Coins = oldCoins + coins

	if not DataManager.Save(player) then
		profile.Coins = oldCoins
		local index = table.find(profile.UsedCodes, code)
		if index then
			table.remove(profile.UsedCodes, index)
		end
		return { ok = false, message = "Save failed, nothing was granted." }
	end

	pushData(player)

	return {
		ok = true,
		message = ("Code %s redeemed, +%d coins."):format(code, coins),
		coins = profile.Coins,
	}
end

local function bind(remote, handler)
	remote.OnServerInvoke = function(player, ...)
		local ok, result = pcall(handler, player, ...)
		if not ok then
			warn(("RewardsService: %s failed for %s: %s"):format(remote.Name, player.Name, tostring(result)))
			return { ok = false, message = "Server error, try again later." }
		end
		return result
	end
end

bind(claimDaily, claimReward)
bind(redeemCode, redeem)

local function onPlayerAdded(player)
	if not DataManager.Load(player) then
		player:Kick("Could not load your data, rejoin in a minute.")
		return
	end

	pushData(player)
end

local function onPlayerRemoving(player)
	DataManager.Save(player)
	DataManager.Release(player)
	lastRequestAt[player.UserId] = nil
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(onPlayerAdded, player)
end)

Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		task.spawn(DataManager.Save, player)
	end

	-- Studio does not give the server time to flush saves.
	if not RunService:IsStudio() then
		task.wait(3)
	end
end)
