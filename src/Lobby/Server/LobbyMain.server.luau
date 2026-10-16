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

print("[Skyline Zero] Lobby ready")
