--!strict
-- Lobby place entry point: builds the plaza, starts the lifts and the leaderboard.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Atmosphere = require(script.Parent.Atmosphere)
local LeaderboardService = require(script.Parent.LeaderboardService)
local LiftService = require(script.Parent.LiftService)
local LobbyWorld = require(script.Parent.LobbyWorld)
local RateLimiter = require(script.Parent.RateLimiter)

Players.CharacterAutoLoads = true

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local notifyRemote = Instance.new("RemoteEvent")
notifyRemote.Name = "Notify"
notifyRemote.Parent = remotes
local leaveLift = Instance.new("RemoteEvent")
leaveLift.Name = "LeaveLift"
leaveLift.Parent = remotes
local setLiftSize = Instance.new("RemoteEvent")
setLiftSize.Name = "SetLiftSize"
setLiftSize.Parent = remotes
local buyClass = Instance.new("RemoteEvent")
buyClass.Name = "BuyClass"
buyClass.Parent = remotes
local selectClass = Instance.new("RemoteEvent")
selectClass.Name = "SelectClass"
selectClass.Parent = remotes
local setLanguage = Instance.new("RemoteEvent")
setLanguage.Name = "SetLanguage"
setLanguage.Parent = remotes
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local requestRecords = Instance.new("RemoteEvent")
requestRecords.Name = RemoteNames.RequestRecords
requestRecords.Parent = remotes
local showRecords = Instance.new("RemoteEvent")
showRecords.Name = RemoteNames.ShowRecords
showRecords.Parent = remotes
remotes.Parent = ReplicatedStorage

-- The lobby keeps the language choice only for this visit; the tower saves it with the player's progress.
setLanguage.OnServerEvent:Connect(function(player, code)
	if code == "uk" or code == "ru" or code == "en" then
		player:SetAttribute("Language", code)
	end
end)

Atmosphere.Apply()
local world = LobbyWorld.Build()
LiftService.Start(world.lifts, function(player, message, kind)
	notifyRemote:FireClient(player, message, kind or "info")
end)
LeaderboardService.Start(world.leaderboardRows)
-- The "Records" panel: the cached board, at most once a second per player.
requestRecords.OnServerEvent:Connect(function(player)
	if RateLimiter.Allow(player, "RequestRecords", 1) then
		showRecords:FireClient(player, LeaderboardService.Get())
	end
end)
leaveLift.OnServerEvent:Connect(LiftService.Leave)
setLiftSize.OnServerEvent:Connect(LiftService.SetSize)

-- Tokens earned in matches, shown in the lobby HUD.
local MetaProgress = require(ReplicatedStorage.Shared.MetaProgress)
local Classes = require(ReplicatedStorage.Shared.Classes)

-- Tokens, unlocked classes (comma list) and the picked class go to the player as attributes for the UI.
local function show(player: Player, meta: MetaProgress.Meta)
	if player.Parent ~= Players then
		return
	end
	local owned = {}
	for _, id in Classes.Order do
		if meta.classes[id] then
			table.insert(owned, id)
		end
	end
	player:SetAttribute("Tokens", meta.tokens)
	player:SetAttribute("ClassesOwned", table.concat(owned, ","))
	player:SetAttribute("ClassSelected", meta.selected or "")
end

local function loadTokens(player: Player)
	show(player, MetaProgress.Load(player.UserId))
end

local busy: { [Player]: boolean } = {}
local function guarded(player: Player, fn: () -> ())
	if busy[player] then
		return
	end
	busy[player] = true
	local ok, err = pcall(fn)
	busy[player] = nil
	if not ok then
		warn("[Lobby] class request failed:", err)
	end
end

buyClass.OnServerEvent:Connect(function(player, classId)
	local def = Classes.Get(classId)
	if not def then
		return
	end
	guarded(player, function()
		local meta, reason = MetaProgress.BuyClass(player.UserId, def.id, def.price)
		if meta then
			show(player, meta)
			notifyRemote:FireClient(player, { "lobby.classBought", { ref = "class." .. def.id .. ".name" } }, "success")
		elseif reason == "tokens" then
			notifyRemote:FireClient(player, "lobby.classNoTokens", "warning")
		end
	end)
end)

selectClass.OnServerEvent:Connect(function(player, classId)
	if classId ~= nil and not Classes.Get(classId) then
		return
	end
	guarded(player, function()
		local meta = MetaProgress.SelectClass(player.UserId, classId)
		if meta then
			show(player, meta)
		end
	end)
end)
Players.PlayerRemoving:Connect(function(player)
	busy[player] = nil
end)
Players.PlayerAdded:Connect(loadTokens)
for _, player in Players:GetPlayers() do
	task.spawn(loadTokens, player)
end

local PlacesConfig = require(ReplicatedStorage.Shared.PlacesConfig)
print(("[Skyline Zero] Lobby ready, build %s, tower place %d"):format(PlacesConfig.Build, PlacesConfig.TowerPlaceId))
