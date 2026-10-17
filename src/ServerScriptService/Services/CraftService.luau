--!strict
-- Workbench on the roof: turns resources into bandages and weapons. Recipes live in GameConfig.Recipes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local Locale = require(ReplicatedStorage.Shared.Locale)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local SfxService = require(script.Parent.SfxService)
local CharacterUtil = require(script.Parent.CharacterUtil)
local DamageService = require(script.Parent.DamageService)
local InventoryService = require(script.Parent.InventoryService)
local Net = require(script.Parent.Net)
local RateLimiter = require(script.Parent.RateLimiter)
local StorageService = require(script.Parent.StorageService)

local CraftService = {}

local workbench: BasePart? = nil

function CraftService.SetWorkbench(part: BasePart)
	workbench = part
end

-- Opened from the workbench prompt (InteractionService).
function CraftService.Open(player: Player): (boolean, any)
	Net.Get(RemoteNames.OpenCraft):FireClient(player)
	return true, nil
end

local function craft(player: Player, recipeId: any): (boolean, any)
	if DamageService.IsDowned(player) then
		return false, nil
	end
	local recipe = nil
	for _, r in GameConfig.Recipes do
		if r.id == recipeId then
			recipe = r
		end
	end
	if not recipe then
		return false, "craft.unknown"
	end
	if not workbench or not CharacterUtil.IsNear(player, workbench, GameConfig.InteractionDistance + 4) then
		return false, "craft.tooFar"
	end
	local def = ItemDefinitions.Items[recipe.id]
	if def.weapon and InventoryService.GetCount(player, recipe.id) > 0 then
		return false, "craft.haveIt"
	end
	if not InventoryService.CanAdd(player, recipe.id, 1) and def.weight > 0 then
		return false, "storage.invFull"
	end
	-- Pays from the backpack first, then from the chest, all or nothing.
	if not StorageService.TrySpend(player, recipe.cost) then
		return false, { "upgrade.notEnough", Locale.Cost(recipe.cost) }
	end
	InventoryService.ForceAdd(player, recipe.id, 1)
	SfxService.PlayAtPlayer("Build", player, 0.8)
	Net.Notify(player, { "craft.done", Locale.Item(recipe.id) }, "success")
	return true, nil
end

function CraftService.Start()
	Net.Get(RemoteNames.Craft).OnServerEvent:Connect(function(player, recipeId)
		if not RateLimiter.Allow(player, "Craft", 0.4) then
			return
		end
		local ok, reason = craft(player, recipeId)
		if not ok and reason then
			Net.Notify(player, reason, "warning")
		end
	end)
end

return CraftService
