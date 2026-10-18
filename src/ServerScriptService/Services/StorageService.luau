--!strict
-- Moves items between the carried inventory and the base storage.
-- Each transfer is checked and applied without yielding, so repeated requests cannot duplicate items.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local Locale = require(ReplicatedStorage.Shared.Locale)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local CharacterUtil = require(script.Parent.CharacterUtil)
local InventoryService = require(script.Parent.InventoryService)
local DamageService = require(script.Parent.DamageService)
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

-- Team pool: building and crafting on the roof pay from the whole team, not one backpack.
-- Order: the player's own backpack, then the team chest, then teammates who are on the roof too.
local function contributors(player: Player): { Player }
	local list = {}
	for _, other in Players:GetPlayers() do
		if other ~= player and other:GetAttribute("Zone") == "Roof" and not DamageService.IsDowned(other) then
			table.insert(list, other)
		end
	end
	return list
end

-- What teammates on the roof carry (not counting the player), for the build / craft prices on screen.
function StorageService.TeamPool(player: Player): { [string]: number }
	local pool: { [string]: number } = {}
	for _, other in contributors(player) do
		local data = PlayerDataService.Get(other)
		if data then
			for id, count in data.inventory do
				if count > 0 then
					pool[id] = (pool[id] or 0) + count
				end
			end
		end
	end
	return pool
end

-- Everything the team can put toward a build right now: own backpack + chest + teammates on the roof.
function StorageService.TeamTotal(player: Player, itemId: string): number
	return StorageService.Total(player, itemId) + (StorageService.TeamPool(player)[itemId] or 0)
end

-- Everything the whole team has collected, wherever they are (goal counters).
function StorageService.TeamCollected(itemId: string): number
	local total = 0
	local storageCounted = false
	for _, other in Players:GetPlayers() do
		local data = PlayerDataService.Get(other)
		if data then
			total += data.inventory[itemId] or 0
			if not storageCounted then
				-- The chest is one shared table for everyone; count it once.
				total += data.storage[itemId] or 0
				storageCounted = true
			end
		end
	end
	return total
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
	if DamageService.IsDowned(player) then
		return false, nil
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
		if def.weight > 0 then
			local free = GameConfig.StorageCapacity - StorageService.GetWeight(player)
			count = math.min(count, math.floor(free / def.weight))
		end
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
	StateSyncService.RequestAll()
	return true, nil
end

-- Takes cost from inventory first, then storage. Returns false and changes nothing if it is not affordable.
function StorageService.TrySpend(player: Player, cost: { [string]: number }): boolean
	local data = PlayerDataService.Get(player)
	if not data then
		return false
	end
	for id, amount in cost do
		if StorageService.TeamTotal(player, id) < amount then
			return false
		end
	end
	local helpers = contributors(player)
	for id, amount in cost do
		local left = amount
		local fromInventory = math.min(left, data.inventory[id] or 0)
		data.inventory[id] = (data.inventory[id] or 0) - fromInventory
		left -= fromInventory
		local fromStorage = math.min(left, data.storage[id] or 0)
		data.storage[id] = (data.storage[id] or 0) - fromStorage
		left -= fromStorage
		for _, other in helpers do
			if left <= 0 then
				break
			end
			local otherData = PlayerDataService.Get(other)
			if otherData then
				local take = math.min(left, otherData.inventory[id] or 0)
				otherData.inventory[id] = (otherData.inventory[id] or 0) - take
				left -= take
				if take > 0 then
					Net.Notify(other, { "team.chippedIn", Locale.Item(id), take }, "info")
				end
			end
		end
	end
	PlayerDataService.MarkDirty(player)
	StateSyncService.RequestAll()
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
