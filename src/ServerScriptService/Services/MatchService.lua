--!strict
-- Ends a lost match: when everyone is down, show "you lost" to all players, then send the whole
-- server back to the lobby. Where teleporting is impossible (Studio, lobby not published) the run
-- restarts in place with fresh characters and a clean slate.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlacesConfig = require(ReplicatedStorage.Shared.PlacesConfig)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local DamageService = require(script.Parent.DamageService)
local Net = require(script.Parent.Net)
local PlayerDataService = require(script.Parent.PlayerDataService)
local ResourceService = require(script.Parent.ResourceService)

local MatchService = {}

local ending = false

local function restartInPlace()
	for _, player in Players:GetPlayers() do
		PlayerDataService.Reset(player)
		ResourceService.OnReturnedToRoof(player)
		player:LoadCharacter()
	end
end

local function sendToLobby(): boolean
	if PlacesConfig.LobbyPlaceId == 0 or RunService:IsStudio() then
		return false
	end
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(PlacesConfig.LobbyPlaceId, Players:GetPlayers())
	end)
	if not ok then
		warn("[Match] teleport to lobby failed:", err)
	end
	return ok
end

local function onAllDown()
	if ending then
		return
	end
	ending = true
	for _, player in Players:GetPlayers() do
		Net.Get(RemoteNames.ShowNote):FireClient(player, {
			kind = "ending",
			title = "gameover.title",
			body = "gameover.body",
			footer = "gameover.footer",
		})
	end
	task.wait(GameConfig.GameOverSeconds)
	if not sendToLobby() then
		restartInPlace()
	end
	-- Give a failed teleport time to settle before another game over can trigger.
	task.wait(5)
	ending = false
end

function MatchService.Start()
	DamageService.OnAllDown(onAllDown)
end

return MatchService
