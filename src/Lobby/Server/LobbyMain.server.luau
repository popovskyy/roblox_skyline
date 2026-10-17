--!strict
-- Lobby place entry point: builds the plaza, starts the lifts and the leaderboard.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Atmosphere = require(script.Parent.Atmosphere)
local LeaderboardService = require(script.Parent.LeaderboardService)
local LiftService = require(script.Parent.LiftService)
local LobbyWorld = require(script.Parent.LobbyWorld)

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
local setLanguage = Instance.new("RemoteEvent")
setLanguage.Name = "SetLanguage"
setLanguage.Parent = remotes
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
leaveLift.OnServerEvent:Connect(LiftService.Leave)
setLiftSize.OnServerEvent:Connect(LiftService.SetSize)

-- Tokens earned in matches, shown in the lobby HUD.
local MetaProgress = require(ReplicatedStorage.Shared.MetaProgress)
local function loadTokens(player: Player)
	local meta = MetaProgress.Load(player.UserId)
	if player.Parent == Players then
		player:SetAttribute("Tokens", meta.tokens)
	end
end
Players.PlayerAdded:Connect(loadTokens)
for _, player in Players:GetPlayers() do
	task.spawn(loadTokens, player)
end

local PlacesConfig = require(ReplicatedStorage.Shared.PlacesConfig)
print(("[Skyline Zero] Lobby ready, build %s, tower place %d"):format(PlacesConfig.Build, PlacesConfig.TowerPlaceId))
