--!strict
-- The only thing that survives between matches besides the leaderboard: tokens and lifetime stats,
-- kept in a DataStore per player. Used by servers only (tower writes, lobby reads).

local DataStoreService = game:GetService("DataStoreService")

local MetaProgress = {}

local STORE_NAME = "SkylineZero_Meta_v1"

export type Meta = {
	tokens: number,
	matches: number,
	wins: number,
	zombies: number,
	chests: number,
	bestFloor: number,
}

local function fresh(): Meta
	return { tokens = 0, matches = 0, wins = 0, zombies = 0, chests = 0, bestFloor = 0 }
end

local function normalize(value: any): Meta
	local meta = fresh()
	if type(value) == "table" then
		for key in meta do
			if type(value[key]) == "number" then
				(meta :: any)[key] = value[key]
			end
		end
	end
	return meta
end

local function store(): DataStore
	return DataStoreService:GetDataStore(STORE_NAME)
end

-- Current meta progress, or a fresh one when the store cannot be read.
function MetaProgress.Load(userId: number): Meta
	local ok, value = pcall(function()
		return store():GetAsync("u_" .. userId)
	end)
	if not ok then
		warn("[Meta] load failed:", value)
	end
	return normalize(if ok then value else nil)
end

-- Adds a finished match. Returns the new totals, or nil when saving failed.
function MetaProgress.AddMatch(
	userId: number,
	tokens: number,
	won: boolean,
	zombies: number,
	chests: number,
	floor: number
): Meta?
	local result: Meta? = nil
	for attempt = 1, 3 do
		local ok, err = pcall(function()
			store():UpdateAsync("u_" .. userId, function(old)
				local meta = normalize(old)
				meta.tokens += tokens
				meta.matches += 1
				meta.wins += if won then 1 else 0
				meta.zombies += zombies
				meta.chests += chests
				meta.bestFloor = math.max(meta.bestFloor, floor)
				result = meta
				return meta
			end)
		end)
		if ok then
			return result
		end
		warn(("[Meta] save failed (attempt %d): %s"):format(attempt, tostring(err)))
		task.wait(attempt)
	end
	return nil
end

return MetaProgress
