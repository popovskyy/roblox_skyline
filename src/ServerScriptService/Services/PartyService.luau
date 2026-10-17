--!strict
-- Party matches started from the lobby. A lobby lift reserves this server and stores the party in MemoryStore
-- under game.PrivateServerId. Here:
--   * the base starts from the leader's saved upgrades (members keep anything extra they had),
--   * anything a member builds is written into every member's save,
--   * inventory, storage and resource nodes stay personal.
-- With no party record (Studio, a public server, a failed read) every player plays solo.

local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Locale = require(ReplicatedStorage.Shared.Locale)
local PlacesConfig = require(ReplicatedStorage.Shared.PlacesConfig)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local BaseUpgradeService = require(script.Parent.BaseUpgradeService)
local Net = require(script.Parent.Net)
local PlayerDataService = require(script.Parent.PlayerDataService)
local RateLimiter = require(script.Parent.RateLimiter)
local StateSyncService = require(script.Parent.StateSyncService)

local PartyService = {}

type Party = { leaderUserId: number, members: { [number]: boolean } }
local party: Party? = nil

local function isMember(player: Player): boolean
	return party ~= nil and party.members[player.UserId] == true
end

local function leaderData()
	if not party then
		return nil
	end
	local leader = Players:GetPlayerByUserId(party.leaderUserId)
	return leader and PlayerDataService.Get(leader)
end

-- Adds the leader's built upgrades to a member's data. Never removes anything.
local function adoptLeaderBase(player: Player)
	local source = leaderData()
	local data = PlayerDataService.Get(player)
	if not source or not data or source == data then
		return
	end
	local changed = false
	for id, built in source.upgrades do
		if built and not data.upgrades[id] then
			data.upgrades[id] = true
			changed = true
		end
	end
	if changed then
		PlayerDataService.MarkDirty(player)
		StateSyncService.Request(player)
	end
end

local function applyToEveryone()
	if not party then
		return
	end
	for _, player in Players:GetPlayers() do
		if isMember(player) then
			adoptLeaderBase(player)
		end
	end
end

local function onDataLoaded(player: Player)
	if not isMember(player) then
		return
	end
	if party and player.UserId == party.leaderUserId then
		applyToEveryone()
	else
		adoptLeaderBase(player)
	end
	-- No party.leader toast: spawn clutter; party state is visible elsewhere.
end

-- Something one member built goes into every member's save.
local function onPurchased(builder: Player, upgradeId: string)
	if not isMember(builder) then
		return
	end
	for _, player in Players:GetPlayers() do
		if player ~= builder and isMember(player) then
			local data = PlayerDataService.Get(player)
			if data and not data.upgrades[upgradeId] then
				data.upgrades[upgradeId] = true
				PlayerDataService.MarkDirty(player)
				StateSyncService.Request(player)
				task.spawn(PlayerDataService.Save, player)
			end
			Net.Notify(player, { "party.built", builder.DisplayName, Locale.Upgrade(upgradeId) }, "success")
		end
	end
end

local function readParty()
	if RunService:IsStudio() or game.PrivateServerId == "" or game.PrivateServerOwnerId ~= 0 then
		return
	end
	local map = MemoryStoreService:GetHashMap(PlacesConfig.PartyMapName)
	for attempt = 1, PlacesConfig.TeleportRetries do
		local ok, record = pcall(function()
			return map:GetAsync(game.PrivateServerId)
		end)
		if ok then
			if
				type(record) == "table"
				and type(record.leaderUserId) == "number"
				and type(record.partyUserIds) == "table"
			then
				local members = {}
				for _, userId in record.partyUserIds do
					if type(userId) == "number" then
						members[userId] = true
					end
				end
				members[record.leaderUserId] = true
				party = { leaderUserId = record.leaderUserId, members = members }
				applyToEveryone()
			end
			return
		end
		warn(("[Party] read attempt %d failed: %s"):format(attempt, tostring(record)))
		task.wait(attempt)
	end
end

local function returnToLobby(player: Player)
	if not RateLimiter.Allow(player, "ReturnToLobby", 3) then
		return
	end
	if PlacesConfig.LobbyPlaceId == 0 then
		Net.Notify(player, "lobby.notPublished", "warning")
		return
	end
	if RunService:IsStudio() then
		Net.Notify(player, "lobby.studio", "warning")
		return
	end
	-- Save first so nothing is lost on the way.
	PlayerDataService.Save(player)
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(PlacesConfig.LobbyPlaceId, { player })
	end)
	if not ok then
		warn("[Party] return to lobby failed:", err)
		Net.Notify(player, "lobby.failed", "error")
	end
end

function PartyService.Start()
	PlayerDataService.OnLoaded(onDataLoaded)
	BaseUpgradeService.OnPurchased(onPurchased)
	Net.Get(RemoteNames.ReturnToLobby).OnServerEvent:Connect(returnToLobby)
	task.spawn(readParty)
end

return PartyService
