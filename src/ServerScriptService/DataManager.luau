local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local DataManager = {}
DataManager.Profiles = {}

local saving = {}
local memoryStore = {}

-- Unpublished places cannot touch DataStore at all, so local testing falls back to memory.
local dataStore
local canPersist = false

do
	local ok, err = pcall(function()
		dataStore = DataStoreService:GetDataStore(Config.DataStoreName)
		return dataStore:GetAsync("probe")
	end)
	canPersist = ok
	if not ok then
		warn(("DataManager: DataStore unavailable, profiles stay in memory (%s)"):format(tostring(err)))
	end
end

local function freshProfile()
	return {
		Coins = 0,
		LastClaimTime = 0,
		Streak = 0,
		UsedCodes = {},
	}
end

-- DataStore payloads outlive the code that wrote them, so everything gets clamped on the way in.
local function coerce(raw)
	local profile = freshProfile()
	if typeof(raw) ~= "table" then
		return profile
	end

	profile.Coins = math.max(0, math.floor(tonumber(raw.Coins) or 0))
	profile.LastClaimTime = math.max(0, math.floor(tonumber(raw.LastClaimTime) or 0))
	profile.Streak = math.clamp(math.floor(tonumber(raw.Streak) or 0), 0, #Config.DailyRewards)

	if typeof(raw.UsedCodes) == "table" then
		local seen = {}
		for _, code in ipairs(raw.UsedCodes) do
			if typeof(code) == "string" and not seen[code] then
				seen[code] = true
				table.insert(profile.UsedCodes, code)
				if #profile.UsedCodes >= Config.MaxUsedCodes then
					break
				end
			end
		end
	end

	return profile
end

local function keyFor(player)
	return "u_" .. player.UserId
end

-- Two remotes can fire at once, and UpdateAsync on the same key from one session is just wasted budget.
local function acquire(player)
	local deadline = os.clock() + 5
	while saving[player] do
		if os.clock() >= deadline then
			return false
		end
		task.wait(0.05)
	end
	saving[player] = true
	return true
end

function DataManager.Get(player)
	return DataManager.Profiles[player]
end

function DataManager.Load(player)
	local cached = DataManager.Profiles[player]
	if cached then
		return cached
	end

	if not canPersist then
		local profile = coerce(memoryStore[player.UserId])
		DataManager.Profiles[player] = profile
		return profile
	end

	local raw
	local loaded = false

	for attempt = 1, 3 do
		local ok, result = pcall(store.GetAsync, dataStore, keyFor(player))
		if ok then
			raw = result
			loaded = true
			break
		end
		warn(("DataManager: get failed for %s (%d/3): %s"):format(player.Name, attempt, tostring(result)))
		task.wait(attempt)
	end

	if not loaded then
		return nil
	end

	local profile = coerce(raw)
	DataManager.Profiles[player] = profile
	return profile
end

function DataManager.Save(player)
	local profile = DataManager.Profiles[player]
	if not profile then
		return false
	end

	if not acquire(player) then
		warn(("DataManager: save lock timeout for %s"):format(player.Name))
		return false
	end

	local snapshot = {
		Coins = profile.Coins,
		LastClaimTime = profile.LastClaimTime,
		Streak = profile.Streak,
		UsedCodes = table.clone(profile.UsedCodes),
	}

	if not canPersist then
		memoryStore[player.UserId] = snapshot
		saving[player] = nil
		return true
	end

	local ok, err = pcall(function()
		dataStore:UpdateAsync(keyFor(player), function()
			-- The live session wins. Merging old values would resurrect coins that were already spent.
			return snapshot
		end)
	end)

	saving[player] = nil

	if not ok then
		warn(("DataManager: save failed for %s: %s"):format(player.Name, tostring(err)))
		return false
	end

	return true
end

function DataManager.Release(player)
	DataManager.Profiles[player] = nil
	saving[player] = nil
end

return DataManager
