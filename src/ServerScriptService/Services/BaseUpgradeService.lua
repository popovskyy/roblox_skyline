--!strict
-- Buys and applies base upgrades. Prices come only from UpgradeDefinitions.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Locale = require(ReplicatedStorage.Shared.Locale)
local UpgradeDefinitions = require(ReplicatedStorage.Shared.UpgradeDefinitions)
local SfxService = require(script.Parent.SfxService)
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

function BaseUpgradeService.Purchase(player: Player, upgradeId: any): (boolean, any)
	local data = PlayerDataService.Get(player)
	if not data then
		return false, "err.notLoaded"
	end
	local def = if type(upgradeId) == "string" then UpgradeDefinitions.Get(upgradeId) else nil
	if not def then
		return false, "err.unknownUpgrade"
	end
	if data.upgrades[def.id] then
		return false, { "upgrade.alreadyBuilt", Locale.Upgrade(def.id) }
	end
	for _, required in def.requires do
		if not data.upgrades[required] then
			return false, { "upgrade.requires", Locale.Upgrade(required) }
		end
	end
	local cost = UpgradeDefinitions.GetCost(def)
	if not StorageService.TrySpend(player, cost) then
		return false, { "upgrade.notEnough", Locale.Cost(cost) }
	end

	data.upgrades[def.id] = true
	PlayerDataService.MarkDirty(player)
	StateSyncService.Request(player)
	Net.Notify(player, { "upgrade.built", Locale.Upgrade(def.id) }, "success")
	SfxService.PlayAtPlayer(if def.id == "Generator" then "GeneratorStart" else "Build", player)
	for _, listener in listeners do
		task.spawn(listener, player, def.id)
	end
	-- Upgrades are important progress, so save right away instead of waiting for the autosave.
	task.spawn(PlayerDataService.Save, player)
	return true, nil
end

return BaseUpgradeService
