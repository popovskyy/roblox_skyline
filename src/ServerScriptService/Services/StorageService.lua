--!strict
-- Team chest: one shared stash for everyone on this tower server (party or solo session).
-- Transfers are checked and applied without yielding, so repeated requests cannot duplicate items.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local Locale = require(ReplicatedStorage.Shared.Locale)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local CharacterUtil = require(script.Parent.CharacterUtil)
local InventoryService = require(script.Parent.InventoryService)
local Net = require(script.Parent.Net)
local PlayerDataService = require(script.Parent.PlayerDataService)
local RateLimiter = require(script.Parent.RateLimiter)
local StateSyncService = require(script.Parent.StateSyncService)

local StorageService = {}

local storagePart: BasePart? = nil
-- Shared session chest (not per-player).
local teamStorage: { [string]: number } = {}
local lastDepositToastAt: { [Player]: number } = {}

function StorageService.SetStoragePart(part: BasePart)
	storagePart = part
end

function StorageService.GetTeamStorage(): { [string]: number }
	return teamStorage
end

function StorageService.GetWeight(_player: Player?): number
	return InventoryService.WeightOf(teamStorage)
end

function StorageService.Total(player: Player, itemId: string): number
	local data = PlayerDataService.Get(player)
	if not data then
		return teamStorage[itemId] or 0
	end
	return (data.inventory[itemId] or 0) + (teamStorage[itemId] or 0)
end

local function syncEveryone()
	for _, player in Players:GetPlayers() do
		StateSyncService.Request(player)
	end
end

local function isNearStorage(player: Player): boolean
	return storagePart ~= nil and CharacterUtil.IsNear(player, storagePart, GameConfig.InteractionDistance + 4)
end

-- direction: "Deposit" moves inventory -> team chest, "Withdraw" moves team chest -> inventory.
function StorageService.Transfer(player: Player, direction: any, itemId: any, amount: any): (boolean, any)
	local data = PlayerDataService.Get(player)
	if not data then
		return false, "err.notLoaded"
	end
	if direction ~= "Deposit" and direction ~= "Withdraw" then
		return false, "storage.invalid"
	end
	if not ItemDefinitions.IsValid(itemId) or not ItemDefinitions.Items[itemId].storable then
		return false, "storage.notStorable"
	end
	if not InventoryService.IsPositiveInt(amount) or amount > 1000 then
		return false, "storage.badAmount"
	end
	if not data.upgrades.StorageCrate then
		return false, "storage.buildFirst"
	end
	if not isNearStorage(player) then
		return false, "storage.tooFar"
	end

	local def = ItemDefinitions.Items[itemId :: string]
	local id = itemId :: string
	local count = amount :: number

	if direction == "Deposit" then
		local have = data.inventory[id] or 0
		count = math.min(count, have)
		local free = GameConfig.StorageCapacity - StorageService.GetWeight(player)
		count = math.min(count, math.floor(free / def.weight))
		if count <= 0 then
			return false, if have <= 0 then "storage.nothing" else "storage.full"
		end
		data.inventory[id] = have - count
		teamStorage[id] = (teamStorage[id] or 0) + count
		-- Keep legacy personal mirror empty so old saves don't diverge mid-session.
		data.storage[id] = 0
		PlayerDataService.MarkDirty(player)
		syncEveryone()
		local now = os.clock()
		if (lastDepositToastAt[player] or 0) + 3 <= now then
			lastDepositToastAt[player] = now
			for _, other in Players:GetPlayers() do
				if other ~= player then
					Net.Notify(other, { "party.stored", player.DisplayName, Locale.Cost({ [id] = count }) }, "info")
				end
			end
		end
	else
		local stored = teamStorage[id] or 0
		count = math.min(count, stored, InventoryService.SpaceFor(player, id))
		if count <= 0 then
			return false, if stored <= 0 then "storage.notInStorage" else "storage.invFull"
		end
		teamStorage[id] = stored - count
		if teamStorage[id] <= 0 then
			teamStorage[id] = nil
		end
		data.inventory[id] = (data.inventory[id] or 0) + count
		PlayerDataService.MarkDirty(player)
		syncEveryone()
	end

	return true, nil
end

-- Takes cost from inventory first, then the team chest.
function StorageService.TrySpend(player: Player, cost: { [string]: number }): boolean
	local data = PlayerDataService.Get(player)
	if not data then
		return false
	end
	for id, amount in cost do
		if StorageService.Total(player, id) < amount then
			return false
		end
	end
	for id, amount in cost do
		local fromInventory = math.min(amount, data.inventory[id] or 0)
		data.inventory[id] = (data.inventory[id] or 0) - fromInventory
		local fromChest = amount - fromInventory
		if fromChest > 0 then
			teamStorage[id] = (teamStorage[id] or 0) - fromChest
			if (teamStorage[id] or 0) <= 0 then
				teamStorage[id] = nil
			end
		end
	end
	PlayerDataService.MarkDirty(player)
	syncEveryone()
	return true
end

function StorageService.Init()
	StateSyncService.RegisterProvider(function(_player, snapshot)
		snapshot.storage = table.clone(teamStorage)
		snapshot.storageWeight = InventoryService.WeightOf(teamStorage)
		snapshot.storageCapacity = GameConfig.StorageCapacity
		snapshot.teamChest = true
	end)
end

function StorageService.Start()
	Net.Get(RemoteNames.StorageTransfer).OnServerEvent:Connect(function(player, direction, itemId, amount)
		if not RateLimiter.Allow(player, "StorageTransfer", 0.15) then
			return
		end
		local ok, reason = StorageService.Transfer(player, direction, itemId, amount)
		if not ok and reason then
			Net.Notify(player, reason, "warning")
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastDepositToastAt[player] = nil
	end)
end

return StorageService
