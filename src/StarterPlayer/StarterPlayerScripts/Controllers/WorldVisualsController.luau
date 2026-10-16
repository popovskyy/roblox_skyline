--!strict
-- Applies this player's personal world state locally: empty nodes, cleared rubble, built upgrades,
-- the Floor 4 door, base lights and prompt texts. The server still validates every action.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local UpgradeDefinitions = require(ReplicatedStorage.Shared.UpgradeDefinitions)
local ClientState = require(script.Parent.ClientState)

local WorldVisualsController = {}

local player = Players.LocalPlayer
local GHOST_TRANSPARENCY = 0.82

-- Original look of every part we touch, so it can be restored.
local originals: { [BasePart]: { transparency: number, collide: boolean } } = {}

local function remember(part: BasePart)
	if not originals[part] then
		originals[part] = { transparency = part.Transparency, collide = part.CanCollide }
	end
end

local function setPartState(part: BasePart, mode: "normal" | "ghost" | "hidden")
	remember(part)
	local original = originals[part]
	if mode == "normal" then
		part.Transparency = original.transparency
		part.CanCollide = original.collide
	elseif mode == "ghost" then
		part.Transparency = math.max(original.transparency, GHOST_TRANSPARENCY)
		part.CanCollide = false
	else
		part.Transparency = 1
		part.CanCollide = false
	end
end

-- Applies to the part and everything under it (rubble chunks, signs, rails).
local function setTreeState(root: BasePart, mode: "normal" | "ghost" | "hidden")
	setPartState(root, mode)
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			setPartState(d, mode)
		elseif d:IsA("SurfaceGui") then
			d.Enabled = mode ~= "hidden"
		elseif d:IsA("Light") and mode == "hidden" then
			d.Enabled = false
		end
	end
end

local function setPrompt(part: Instance, enabled: boolean, actionText: string?, objectText: string?)
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		return
	end
	prompt.Enabled = enabled
	if actionText then
		prompt.ActionText = actionText
	end
	if objectText then
		prompt.ObjectText = objectText
	end
end

local function formatCost(cost: { [string]: number }?): string
	if not cost then
		return ""
	end
	local parts = {}
	for _, itemId in ItemDefinitions.Order do
		local amount = cost[itemId]
		if amount then
			table.insert(parts, ("%d %s"):format(amount, ItemDefinitions.Items[itemId].displayName))
		end
	end
	return table.concat(parts, " + ")
end

local function applyResource(part: BasePart, s: { [string]: any })
	local nodeId = part:GetAttribute("NodeId")
	if type(nodeId) ~= "string" then
		return
	end
	local taken = if part:GetAttribute("Unique") == true
		then s.uniqueNodesTaken and s.uniqueNodesTaken[nodeId]
		else s.depletedNodes and s.depletedNodes[nodeId]
	setTreeState(part, if taken then "hidden" else "normal")
	setPrompt(part, not taken)
end

local function applyRubble(part: BasePart, s: { [string]: any })
	local rubbleId = part:GetAttribute("RubbleId")
	local cleared = type(rubbleId) == "string" and s.clearedRubble and s.clearedRubble[rubbleId]
	setTreeState(part, if cleared then "hidden" else "normal")
	setPrompt(part, not cleared)
end

local function applyUpgradePad(part: BasePart, s: { [string]: any })
	local upgradeId = part:GetAttribute("UpgradeId")
	local def = if type(upgradeId) == "string" then UpgradeDefinitions.Get(upgradeId) else nil
	if not def then
		return
	end
	local owned = s.upgrades and s.upgrades[def.id]
	local missing = nil
	for _, required in def.requires do
		if not (s.upgrades and s.upgrades[required]) then
			missing = UpgradeDefinitions.Upgrades[required].displayName
		end
	end
	local cost = s.costs and s.costs[def.id]
	local action = if missing then ("Потрібно: %s"):format(missing) else "Збудувати"
	setPrompt(part, not owned, action, ("%s: %s"):format(def.displayName, formatCost(cost)))
end

local function applyUpgradeVisual(part: BasePart, s: { [string]: any })
	local upgradeId = part:GetAttribute("UpgradeVisual")
	if type(upgradeId) ~= "string" then
		return
	end
	local owned = s.upgrades and s.upgrades[upgradeId] == true
	local mode = part:GetAttribute("VisualMode")
	if mode == "Hide" then
		setPartState(part, if owned then "hidden" else "normal")
		for _, d in part:GetDescendants() do
			if d:IsA("SurfaceGui") then
				d.Enabled = not owned
			end
		end
		if part:GetAttribute("InteractType") == "Gate" then
			setPrompt(part, not owned)
		end
	else
		setPartState(part, if owned then "normal" else "ghost")
	end
end

local function applyLight(part: BasePart, s: { [string]: any })
	local upgradeId = part:GetAttribute("UpgradeLight")
	if type(upgradeId) ~= "string" then
		return
	end
	local on = s.upgrades and s.upgrades[upgradeId] == true
	part.Material = if on then Enum.Material.Neon else Enum.Material.Glass
	part.Color = if on then Color3.fromRGB(255, 225, 170) else Color3.fromRGB(90, 90, 80)
	for _, d in part:GetDescendants() do
		if d:IsA("Light") then
			d.Enabled = on
		end
	end
end

local function applyBackpack(part: BasePart)
	local mine = part:GetAttribute("OwnerUserId") == player.UserId
	setTreeState(part, if mine then "normal" else "hidden")
	for _, d in part:GetDescendants() do
		if d:IsA("Light") then
			d.Enabled = mine
		end
	end
	setPrompt(part, mine)
end

local function applyPart(d: BasePart, s: { [string]: any })
	local interactType = d:GetAttribute("InteractType")
	if interactType == "Resource" then
		applyResource(d, s)
	elseif interactType == "Rubble" then
		applyRubble(d, s)
	elseif interactType == "Upgrade" then
		applyUpgradePad(d, s)
	elseif interactType == "Storage" then
		setPrompt(d, s.upgrades ~= nil and s.upgrades.StorageCrate == true)
	elseif interactType == "Backpack" then
		applyBackpack(d)
	end
	if d:GetAttribute("UpgradeVisual") then
		applyUpgradeVisual(d, s)
	end
	if d:GetAttribute("UpgradeLight") then
		applyLight(d, s)
	end
end

local function apply(s: { [string]: any }?)
	if not s then
		return
	end
	local world = workspace:FindFirstChild(GameConfig.World.FolderName)
	if not world then
		return
	end
	for _, d in world:GetDescendants() do
		if d:IsA("BasePart") then
			applyPart(d, s)
		end
	end
end

function WorldVisualsController.Start()
	ClientState.Changed:Connect(apply)
	-- The world streams in after the client starts; re-apply when it arrives and when backpacks drop.
	task.spawn(function()
		local world = workspace:WaitForChild(GameConfig.World.FolderName, 60)
		if not world then
			return
		end
		apply(ClientState.Get())
		-- Covers backpacks dropped later and parts that stream in after the first pass.
		world.DescendantAdded:Connect(function(d)
			if d:IsA("BasePart") then
				task.defer(function()
					local s = ClientState.Get()
					if s and d.Parent then
						applyPart(d, s)
					end
				end)
			end
		end)
	end)
end

return WorldVisualsController
