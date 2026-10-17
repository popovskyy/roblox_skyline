--!strict
-- Carried inventory with a weight limit. The only code that changes inventory counts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local Types = require(ReplicatedStorage.Shared.Types)
local MonetizationService = require(script.Parent.MonetizationService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local StateSyncService = require(script.Parent.StateSyncService)

local InventoryService = {}

local function isPositiveInt(value: any): boolean
	return type(value) == "number" and value == value and value > 0 and value < math.huge and value % 1 == 0
end

-- Melee weapons share one slot: a better weapon removes weaker ones (loot / craft / class grant).
-- Weaker pickups do not strip a stronger weapon already carried.
local function replaceWeakerWeapons(player: Player, newId: string)
	local newStats = GameConfig.Weapons[newId]
	if not newStats then
		return
	end
	local data = PlayerDataService.Get(player)
	if not data then
		return
	end
	local equippedId = player:GetAttribute("Equipped")
	local strippedEquipped = false
	for id, count in data.inventory do
		local other = GameConfig.Weapons[id]
		if other and id ~= newId and count > 0 and other.rank < newStats.rank then
			data.inventory[id] = nil
			if equippedId == id then
				strippedEquipped = true
			end
		end
	end
	-- Keep a weapon in hand when the equipped one was replaced, or when nothing was equipped.
	if strippedEquipped or type(equippedId) ~= "string" or GameConfig.Weapons[equippedId] == nil then
		player:SetAttribute("Equipped", newId)
	end
	-- No inv.weaponReplaced toast: hotbar change is visible.
end

function InventoryService.IsPositiveInt(value: any): boolean
	return isPositiveInt(value)
end

function InventoryService.WeightOf(counts: Types.ItemCounts): number
	local total = 0
	for id, amount in counts do
		local def = ItemDefinitions.Get(id)
		if def then
			total += def.weight * amount
		end
	end
	return total
end

function InventoryService.GetCapacity(player: Player): number
	return GameConfig.MaxInventoryWeight + MonetizationService.GetInventoryBonus(player)
end

function InventoryService.GetWeight(player: Player): number
	local data = PlayerDataService.Get(player)
	return data and InventoryService.WeightOf(data.inventory) or 0
end

function InventoryService.GetCount(player: Player, itemId: string): number
	local data = PlayerDataService.Get(player)
	return data and data.inventory[itemId] or 0
end

-- How many of itemId fit into the remaining carry weight.
function InventoryService.SpaceFor(player: Player, itemId: string): number
	local def = ItemDefinitions.Get(itemId)
	if not def then
		return 0
	end
	if def.weight <= 0 then
		-- Weightless items (Key, Club) never fill the backpack.
		return math.huge
	end
	local free = InventoryService.GetCapacity(player) - InventoryService.GetWeight(player)
	return math.max(0, math.floor(free / def.weight))
end

function InventoryService.CanAdd(player: Player, itemId: string, amount: number): boolean
	return isPositiveInt(amount) and InventoryService.SpaceFor(player, itemId) >= amount
end

function InventoryService.Add(player: Player, itemId: string, amount: number): boolean
	local data = PlayerDataService.Get(player)
	if not data or not ItemDefinitions.IsValid(itemId) or not InventoryService.CanAdd(player, itemId, amount) then
		return false
	end
	-- Do not pick up a weaker duplicate melee while a stronger one is already carried.
	local newStats = GameConfig.Weapons[itemId]
	if newStats then
		for id, count in data.inventory do
			local other = GameConfig.Weapons[id]
			if other and count > 0 and other.rank > newStats.rank then
				return false
			end
		end
		replaceWeakerWeapons(player, itemId)
	end
	data.inventory[itemId] = (data.inventory[itemId] or 0) + amount
	PlayerDataService.MarkDirty(player)
	StateSyncService.Request(player)
	return true
end

-- Adds without the weight check. Only for returning items the player already owned (e.g. a death backpack).
function InventoryService.ForceAdd(player: Player, itemId: string, amount: number): boolean
	local data = PlayerDataService.Get(player)
	if not data or not ItemDefinitions.IsValid(itemId) or not isPositiveInt(amount) then
		return false
	end
	local newStats = GameConfig.Weapons[itemId]
	if newStats then
		for id, count in data.inventory do
			local other = GameConfig.Weapons[id]
			if other and count > 0 and other.rank > newStats.rank then
				-- Keep the stronger melee; skip the weaker grant (death bag / duplicate craft).
				return true
			end
		end
		replaceWeakerWeapons(player, itemId)
	end
	data.inventory[itemId] = (data.inventory[itemId] or 0) + amount
	PlayerDataService.MarkDirty(player)
	StateSyncService.Request(player)
	return true
end

function InventoryService.Has(player: Player, itemId: string, amount: number): boolean
	return InventoryService.GetCount(player, itemId) >= amount
end

function InventoryService.Remove(player: Player, itemId: string, amount: number): boolean
	local data = PlayerDataService.Get(player)
	if not data or not ItemDefinitions.IsValid(itemId) or not isPositiveInt(amount) then
		return false
	end
	local current = data.inventory[itemId] or 0
	if current < amount then
		return false
	end
	data.inventory[itemId] = current - amount
	PlayerDataService.MarkDirty(player)
	StateSyncService.Request(player)
	return true
end

return InventoryService
