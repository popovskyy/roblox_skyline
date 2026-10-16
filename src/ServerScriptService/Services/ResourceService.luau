--!strict
-- Resource nodes and rubble. Node state is kept per player, so co-op players never take each other's loot.
-- Resources are handed out only after every server check passes.
--
-- Node attributes:  NodeId, ItemId, Amount, Unique?, RequiresUpgrade?, RequiresRubble?
-- Rubble attributes: RubbleId, RequiresTool?, RewardItem?, RequiresUpgrade?

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local InventoryService = require(script.Parent.InventoryService)
local Net = require(script.Parent.Net)
local PlayerDataService = require(script.Parent.PlayerDataService)
local StateSyncService = require(script.Parent.StateSyncService)

local ResourceService = {}

type PlayerNodes = {
	depleted: { [string]: boolean }, -- normal nodes, refilled on roof return
	cleared: { [string]: boolean }, -- rubble, cleared for this session
}

local state: { [Player]: PlayerNodes } = {}

local function getState(player: Player): PlayerNodes
	local s = state[player]
	if not s then
		s = { depleted = {}, cleared = {} }
		state[player] = s
	end
	return s
end

-- Checks the access attributes a node or rubble may carry. Returns a reason when access is denied.
function ResourceService.CheckAccess(player: Player, object: Instance): string?
	local data = PlayerDataService.Get(player)
	if not data then
		return "Дані ще не завантажені"
	end
	local requiredUpgrade = object:GetAttribute("RequiresUpgrade")
	if type(requiredUpgrade) == "string" and not data.upgrades[requiredUpgrade] then
		return "Ця зона відкриється після поліпшення бази"
	end
	local requiredRubble = object:GetAttribute("RequiresRubble")
	if type(requiredRubble) == "string" and not getState(player).cleared[requiredRubble] then
		return "Прохід завалено"
	end
	return nil
end

function ResourceService.IsTaken(player: Player, node: Instance): boolean
	local nodeId = node:GetAttribute("NodeId")
	if type(nodeId) ~= "string" then
		return true
	end
	if node:GetAttribute("Unique") == true then
		local data = PlayerDataService.Get(player)
		return data ~= nil and data.uniqueNodesTaken[nodeId] == true
	end
	return getState(player).depleted[nodeId] == true
end

function ResourceService.Collect(player: Player, node: BasePart): (boolean, string?)
	local data = PlayerDataService.Get(player)
	local nodeId = node:GetAttribute("NodeId")
	local itemId = node:GetAttribute("ItemId")
	local amount = node:GetAttribute("Amount")
	if not data or type(nodeId) ~= "string" or not ItemDefinitions.IsValid(itemId) then
		return false, nil
	end
	if not InventoryService.IsPositiveInt(amount) then
		warn("[Resource] Misconfigured node", node:GetFullName())
		return false, nil
	end
	if ResourceService.IsTaken(player, node) then
		return false, "Тут уже порожньо"
	end
	local denied = ResourceService.CheckAccess(player, node)
	if denied then
		return false, denied
	end
	local id = itemId :: string
	local count = amount :: number
	local unique = node:GetAttribute("Unique") == true
	if unique and InventoryService.GetCount(player, id) > 0 then
		return false, "У тебе вже є цей предмет"
	end
	if not InventoryService.CanAdd(player, id, count) then
		return false, "Інвентар переповнений. Віднеси знахідки на дах"
	end

	if unique then
		data.uniqueNodesTaken[nodeId] = true
		PlayerDataService.MarkDirty(player)
	else
		getState(player).depleted[nodeId] = true
	end
	InventoryService.Add(player, id, count)
	StateSyncService.Request(player)
	Net.Notify(player, ("Зібрано: %s +%d"):format(ItemDefinitions.Items[id].displayName, count), "success")
	return true, nil
end

function ResourceService.ClearRubble(player: Player, rubble: BasePart): (boolean, string?)
	local rubbleId = rubble:GetAttribute("RubbleId")
	if type(rubbleId) ~= "string" then
		return false, nil
	end
	local s = getState(player)
	if s.cleared[rubbleId] then
		return false, nil
	end
	local denied = ResourceService.CheckAccess(player, rubble)
	if denied then
		return false, denied
	end
	local tool = rubble:GetAttribute("RequiresTool")
	if type(tool) == "string" and not InventoryService.Has(player, tool, 1) then
		return false,
			"Потрібен лом. Розбери перший завал на технічному поверсі"
	end

	s.cleared[rubbleId] = true
	local reward = rubble:GetAttribute("RewardItem")
	if ItemDefinitions.IsValid(reward) and InventoryService.GetCount(player, reward :: string) == 0 then
		-- The reward is a tool the player needs, so it ignores the weight limit.
		InventoryService.ForceAdd(player, reward :: string, 1)
		Net.Notify(
			player,
			("Під завалом знайдено: %s"):format(ItemDefinitions.Items[reward :: string].displayName),
			"success"
		)
	else
		Net.Notify(player, "Завал розібрано", "success")
	end
	StateSyncService.Request(player)
	return true, nil
end

-- Called when the player comes back up to the roof.
function ResourceService.OnReturnedToRoof(player: Player)
	if not GameConfig.ResetNodesOnRoofReturn then
		return
	end
	local s = getState(player)
	if next(s.depleted) then
		table.clear(s.depleted)
		StateSyncService.Request(player)
	end
end

function ResourceService.Init()
	StateSyncService.RegisterProvider(function(player, snapshot)
		local s = getState(player)
		local data = PlayerDataService.Get(player)
		snapshot.depletedNodes = table.clone(s.depleted)
		snapshot.clearedRubble = table.clone(s.cleared)
		snapshot.uniqueNodesTaken = if data then table.clone(data.uniqueNodesTaken) else {}
	end)
	Players.PlayerRemoving:Connect(function(player)
		state[player] = nil
	end)
end

return ResourceService
