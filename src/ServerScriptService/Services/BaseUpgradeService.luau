--!strict
-- Buys and applies base upgrades. Prices come only from UpgradeDefinitions.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local UpgradeDefinitions = require(ReplicatedStorage.Shared.UpgradeDefinitions)
local Net = require(script.Parent.Net)
local PlayerDataService = require(script.Parent.PlayerDataService)
local StateSyncService = require(script.Parent.StateSyncService)
local StorageService = require(script.Parent.StorageService)

local BaseUpgradeService = {}

type Listener = (player: Player, upgradeId: string) -> ()
local listeners: { Listener } = {}

function BaseUpgradeService.OnPurchased(listener: Listener)
	table.insert(listeners, listener)
end

function BaseUpgradeService.Owns(player: Player, upgradeId: string): boolean
	local data = PlayerDataService.Get(player)
	return data ~= nil and data.upgrades[upgradeId] == true
end

function BaseUpgradeService.FormatCost(cost: { [string]: number }): string
	local parts = {}
	for _, itemId in ItemDefinitions.Order do
		local amount = cost[itemId]
		if amount then
			table.insert(parts, ("%d %s"):format(amount, ItemDefinitions.Items[itemId].displayName))
		end
	end
	return table.concat(parts, " + ")
end

function BaseUpgradeService.Purchase(player: Player, upgradeId: any): (boolean, string?)
	local data = PlayerDataService.Get(player)
	if not data then
		return false, "Дані ще не завантажені"
	end
	local def = if type(upgradeId) == "string" then UpgradeDefinitions.Get(upgradeId) else nil
	if not def then
		return false, "Невідоме поліпшення"
	end
	if data.upgrades[def.id] then
		return false, ("%s уже збудовано"):format(def.displayName)
	end
	for _, required in def.requires do
		if not data.upgrades[required] then
			local requiredDef = UpgradeDefinitions.Upgrades[required]
			return false,
				("Спершу потрібно: %s"):format(requiredDef and requiredDef.displayName or required)
		end
	end
	local cost = UpgradeDefinitions.GetCost(def)
	if not StorageService.TrySpend(player, cost) then
		return false,
			("Недостатньо ресурсів. Потрібно: %s"):format(
				BaseUpgradeService.FormatCost(cost)
			)
	end

	data.upgrades[def.id] = true
	PlayerDataService.MarkDirty(player)
	StateSyncService.Request(player)
	Net.Notify(player, ("Збудовано: %s"):format(def.displayName), "success")
	for _, listener in listeners do
		task.spawn(listener, player, def.id)
	end
	-- Upgrades are important progress, so save right away instead of waiting for the autosave.
	task.spawn(PlayerDataService.Save, player)
	return true, nil
end

return BaseUpgradeService
