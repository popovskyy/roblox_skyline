--!strict
-- "Towers completed" board in the lobby, read from the OrderedDataStore the tower writes on a first completion.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlacesConfig = require(ReplicatedStorage.Shared.PlacesConfig)

local LeaderboardService = {}

export type Entry = { rank: number, userId: number, name: string, towers: number }

local names: { [number]: string } = {}
-- The last board read from the store, kept so the "Records" panel never costs a DataStore call.
local latest: { Entry } = {}

local function nameOf(userId: number): string
	if names[userId] then
		return names[userId]
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	local result = if ok and type(name) == "string" then name else ("#" .. tostring(userId))
	names[userId] = result
	return result
end

local function refresh(rows: { TextLabel })
	local ok, pages = pcall(function()
		local store = DataStoreService:GetOrderedDataStore(PlacesConfig.LeaderboardStoreName)
		return store:GetSortedAsync(false, PlacesConfig.LeaderboardSize)
	end)
	local entries = if ok and pages then pages:GetCurrentPage() else {}
	local board: { Entry } = {}
	for i, entry in entries do
		local userId = tonumber(entry.key) or 0
		local towers = if type(entry.value) == "number" then entry.value else 0
		table.insert(board, { rank = i, userId = userId, name = nameOf(userId), towers = towers })
	end
	if ok then
		latest = board
	end
	for i, row in rows do
		local entry = board[i]
		if entry then
			row:SetAttribute("TextKey", nil)
			row.Text = ("%d.  %s  —  %d"):format(i, entry.name, entry.towers)
		elseif i == 1 then
			-- The client translates it.
			row:SetAttribute("TextKey", "lobby.leadersEmpty")
			row.Text = "—"
		else
			row:SetAttribute("TextKey", nil)
			row.Text = ""
		end
	end
	if not ok then
		warn("[Leaderboard] could not read the board:", pages)
	end
end

function LeaderboardService.Get(): { Entry }
	return latest
end

function LeaderboardService.Start(rows: { TextLabel })
	task.spawn(function()
		while true do
			refresh(rows)
			task.wait(PlacesConfig.LeaderboardRefreshSeconds)
		end
	end)
end

return LeaderboardService
