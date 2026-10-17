--!strict
-- Every ProximityPrompt in the world ends up here. The server re-checks the object, the distance and the rate
-- before handing the request to the service that owns it.

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local BaseUpgradeService = require(script.Parent.BaseUpgradeService)
local CharacterUtil = require(script.Parent.CharacterUtil)
local CraftService = require(script.Parent.CraftService)
local DamageService = require(script.Parent.DamageService)
local Net = require(script.Parent.Net)
local PlayerDataService = require(script.Parent.PlayerDataService)
local PlayerLifecycleService = require(script.Parent.PlayerLifecycleService)
local RateLimiter = require(script.Parent.RateLimiter)
local DropService = require(script.Parent.DropService)
local ResourceService = require(script.Parent.ResourceService)
local TutorialService = require(script.Parent.TutorialService)

local InteractionService = {}

local interactables: Folder? = nil

function InteractionService.SetInteractables(folder: Folder)
	interactables = folder
end

type Handler = (player: Player, target: BasePart) -> (boolean, any)

local handlers: { [string]: Handler } = {
	Resource = function(player, target)
		return ResourceService.Collect(player, target)
	end,
	Rubble = function(player, target)
		return ResourceService.ClearRubble(player, target)
	end,
	Terminal = function(player)
		TutorialService.ReadTerminal(player)
		return true, nil
	end,
	Storage = function(player)
		local data = PlayerDataService.Get(player)
		if not data or not data.upgrades.StorageCrate then
			return false, "interact.noStorage"
		end
		Net.Get(RemoteNames.OpenStorage):FireClient(player)
		return true, nil
	end,
	Upgrade = function(player, target)
		return BaseUpgradeService.Purchase(player, target:GetAttribute("UpgradeId"))
	end,
	Gate = function(player, target)
		local required = target:GetAttribute("RequiresUpgrade")
		if type(required) == "string" and not BaseUpgradeService.Owns(player, required) then
			return false, "interact.gateLocked"
		end
		return true, nil
	end,
	Backpack = function(player, target)
		return PlayerLifecycleService.RecoverBackpack(player, target)
	end,
	LootChest = function(player, target)
		return ResourceService.OpenCrate(player, target)
	end,
	GroundDrop = function(player, target)
		return DropService.Pickup(player, target)
	end,
	Workbench = function(player)
		return CraftService.Open(player)
	end,
}

local function onPromptTriggered(prompt: ProximityPrompt, player: Player)
	local folder = interactables
	local target = prompt.Parent
	if not folder or not target or not target:IsA("BasePart") or not target:IsDescendantOf(folder) then
		return
	end
	if not CharacterUtil.GetRoot(player) or DamageService.IsDowned(player) then
		return
	end
	if not RateLimiter.Allow(player, "Interact", GameConfig.InteractionCooldown) then
		return
	end
	if not CharacterUtil.IsNear(player, target, GameConfig.InteractionDistance) then
		Net.Notify(player, "err.tooFar", "warning")
		return
	end
	local interactType = target:GetAttribute("InteractType")
	local handler = if type(interactType) == "string" then handlers[interactType] else nil
	if not handler then
		return
	end
	local ok, reason = handler(player, target)
	if not ok and reason then
		Net.Notify(player, reason, "warning")
	end
end

function InteractionService.Start()
	ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)
end

return InteractionService
