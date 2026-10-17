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

local TELEPORT_RETRIES = 2
local TELEPORT_GIVE_UP_SECONDS = 25
local retries: { [Player]: number } = {}

local function restartPlayer(player: Player)
	if player.Parent ~= Players then
		return
	end
	PlayerDataService.Reset(player)
	ResourceService.ResetMatch(player)
	player:LoadCharacter()
end

local function restartInPlace()
	for _, player in Players:GetPlayers() do
		restartPlayer(player)
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
	else
		-- A teleport can fail later (TeleportInitFailed). Anyone still here after a while starts over here.
		task.delay(TELEPORT_GIVE_UP_SECONDS, function()
			for _, player in Players:GetPlayers() do
				warn("[Match] still here after the lobby teleport, restarting:", player.Name)
				restartPlayer(player)
			end
			table.clear(retries)
		end)
	end
	-- Give a failed teleport time to settle before another game over can trigger.
	task.wait(5)
	ending = false
end

function MatchService.Start()
	DamageService.OnAllDown(onAllDown)
	TeleportService.TeleportInitFailed:Connect(function(player, result, message)
		warn("[Match] teleport failed for", player.Name, result, message)
		local count = (retries[player] or 0) + 1
		retries[player] = count
		if count > TELEPORT_RETRIES then
			restartPlayer(player)
			return
		end
		task.wait(2)
		local ok = pcall(function()
			TeleportService:TeleportAsync(PlacesConfig.LobbyPlaceId, { player })
		end)
		if not ok then
			restartPlayer(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		retries[player] = nil
	end)
end

return MatchService
