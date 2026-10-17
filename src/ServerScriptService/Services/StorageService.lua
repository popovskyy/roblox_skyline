--!strict
-- Moves items between the carried inventory and the base storage.
-- Each transfer is checked and applied without yielding, so repeated requests cannot duplicate items.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local CharacterUtil = require(script.Parent.CharacterUtil)
local InventoryService = require(script.Parent.InventoryService)
local Net = require(script.Parent.Net)
local PlayerDataService = require(script.Parent.PlayerDataService)
local RateLimiter = require(script.Parent.RateLimiter)
local StateSyncService = require(script.Parent.StateSyncService)

local StorageService = {}

local storagePart: BasePart? = nil

function StorageService.SetStoragePart(part: BasePart)
	storagePart = part
end

function StorageService.GetWeight(player: Player): number
	local data = PlayerDataService.Get(player)
	return data and InventoryService.WeightOf(data.storage) or 0
end

function StorageService.Total(player: Player, itemId: string): number
	local data = PlayerDataService.Get(player)
	if not data then
		return 0
	end
	return (data.inventory[itemId] or 0) + (data.storage[itemId] or 0)
end

local function isNearStorage(player: Player): boolean
	-- A little slack over the prompt distance because the UI stays open while the player shuffles around.
	return storagePart ~= nil and CharacterUtil.IsNear(player, storagePart, GameConfig.InteractionDistance + 4)
end

-- direction: "Deposit" moves inventory -> storage, "Withdraw" moves storage -> inventory.
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
		data.storage[id] = (data.storage[id] or 0) + count
	else
		local stored = data.storage[id] or 0
		count = math.min(count, stored, InventoryService.SpaceFor(player, id))
		if count <= 0 then
			return false, if stored <= 0 then "storage.notInStorage" else "storage.invFull"
		end
		data.storage[id] = stored - count
		data.inventory[id] = (data.inventory[id] or 0) + count
	end

	PlayerDataService.MarkDirty(player)
	StateSyncService.Request(player)
	return true, nil
end

-- Takes cost from inventory first, then storage. Returns false and changes nothing if it is not affordable.
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
		data.storage[id] = (data.storage[id] or 0) - (amount - fromInventory)
	end
	PlayerDataService.MarkDirty(player)
	StateSyncService.Request(player)
	return true
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
end

return StorageService
