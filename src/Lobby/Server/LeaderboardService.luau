--!strict
-- "Towers completed" board in the lobby, read from the OrderedDataStore the tower writes on a first completion.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlacesConfig = require(ReplicatedStorage.Shared.PlacesConfig)

local LeaderboardService = {}

local names: { [number]: string } = {}

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
	for i, row in rows do
		local entry = entries[i]
		if entry then
			row:SetAttribute("TextKey", nil)
			row.Text = ("%d.  %s  —  %d"):format(i, nameOf(tonumber(entry.key) or 0), entry.value)
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

function LeaderboardService.Start(rows: { TextLabel })
	task.spawn(function()
		while true do
			refresh(rows)
			task.wait(PlacesConfig.LeaderboardRefreshSeconds)
		end
	end)
end

return LeaderboardService
