--!strict
-- Every ProximityPrompt in the world ends up here. The server re-checks the object, the distance and the rate
-- before handing the request to the service that owns it.

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local BaseUpgradeService = require(script.Parent.BaseUpgradeService)
local CharacterUtil = require(script.Parent.CharacterUtil)
local Net = require(script.Parent.Net)
local PlayerDataService = require(script.Parent.PlayerDataService)
local PlayerLifecycleService = require(script.Parent.PlayerLifecycleService)
local RateLimiter = require(script.Parent.RateLimiter)
local ResourceService = require(script.Parent.ResourceService)
local TutorialService = require(script.Parent.TutorialService)

local InteractionService = {}

local interactables: Folder? = nil

function InteractionService.SetInteractables(folder: Folder)
	interactables = folder
end

type Handler = (player: Player, target: BasePart) -> (boolean, string?)

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
			return false, "Сховища ще немає. Збудуй його за 8 металобрухту"
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
			return false, "Двері заблоковано. Потрібен генератор на даху"
		end
		return true, nil
	end,
	Backpack = function(player, target)
		return PlayerLifecycleService.RecoverBackpack(player, target)
	end,
}

local function onPromptTriggered(prompt: ProximityPrompt, player: Player)
	local folder = interactables
	local target = prompt.Parent
	if not folder or not target or not target:IsA("BasePart") or not target:IsDescendantOf(folder) then
		return
	end
	if not CharacterUtil.GetRoot(player) then
		return
	end
	if not RateLimiter.Allow(player, "Interact", GameConfig.InteractionCooldown) then
		return
	end
	if not CharacterUtil.IsNear(player, target, GameConfig.InteractionDistance) then
		Net.Notify(player, "Занадто далеко", "warning")
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
