--!strict
-- A floating "here" arrow over the place the current tutorial step needs: the terminal, the stairs,
-- the chest spot, the generator, the bridge. Visible through walls, with the distance under it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ClientState = require(script.Parent.ClientState)
local Lang = require(script.Parent.Lang)

local ObjectiveMarkerController = {}

local player = Players.LocalPlayer
local billboard: BillboardGui
local distanceLabel: TextLabel
local target: BasePart? = nil

local function find(path: { string }): BasePart?
	local node: Instance? = workspace:FindFirstChild(GameConfig.World.FolderName)
	for _, name in path do
		node = node and node:FindFirstChild(name)
	end
	if node and node:IsA("BasePart") then
		return node
	end
	return nil
end

local STAIRS = { "Stairwell", "Ramp0_Down" }

-- On a floor during a collecting goal: the nearest node of a wanted item on this floor that the player can
-- still take (not emptied, not behind uncleared rubble). Nil on the roof or when the floor has none left.
local function nearestLoot(s: { [string]: any }, wanted: { [string]: boolean }): BasePart?
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local world = workspace:FindFirstChild(GameConfig.World.FolderName)
	local folder = world and world:FindFirstChild("Interactables")
	local zone = player:GetAttribute("Zone")
	if
		not root
		or not root:IsA("BasePart")
		or not folder
		or type(zone) ~= "string"
		or string.sub(zone, 1, 5) ~= "Floor"
	then
		return nil
	end
	local depleted = s.depletedNodes or {}
	local unique = s.uniqueNodesTaken or {}
	local cleared = s.clearedRubble or {}
	local best: BasePart? = nil
	local bestDistance = math.huge
	for _, d in folder:GetChildren() do
		if
			d:IsA("BasePart")
			and d:GetAttribute("InteractType") == "Resource"
			and wanted[d:GetAttribute("ItemId") or ""]
		then
			local nodeId = d:GetAttribute("NodeId")
			local rubble = d:GetAttribute("RequiresRubble")
			local taken = type(nodeId) == "string" and (depleted[nodeId] or unique[nodeId])
			local blocked = type(rubble) == "string" and not cleared[rubble]
			local offset = d.Position - root.Position
			if not taken and not blocked and math.abs(offset.Y) < 10 and offset.Magnitude < bestDistance then
				best, bestDistance = d, offset.Magnitude
			end
		end
	end
	return best
end

-- Which part the marker points at for each tutorial step (see TutorialService).
local function targetFor(s: { [string]: any }): BasePart?
	local tutorial = s.tutorial
	if not tutorial or tutorial.done then
		return nil
	end
	local step = tutorial.step
	if step == 1 then
		return find({ "Interactables", "EmergencyTerminal" })
	elseif step == 2 or step == 5 then
		-- On the roof: the stairs. On a floor: the nearest scrap / electronics there (stairs if none left).
		local wanted = if step == 2 then { Scrap = true } else { Electronics = true }
		return nearestLoot(s, wanted) or find(STAIRS)
	elseif step == 3 then
		return find({ "RoofBase", "RoofSpawn" })
	elseif step == 4 then
		return find({ "Interactables", "StorageCrate_Pad" })
	elseif step == 6 then
		return find({ "Interactables", "Generator_Pad" })
	elseif step == 7 then
		local have = function(id: string): number
			return (s.inventory and s.inventory[id] or 0) + (s.storage and s.storage[id] or 0)
		end
		if have("Cable") >= 4 and have("Motor") >= 2 then
			return find({ "Interactables", "Bridge_Pad" })
		end
		return nearestLoot(s, { Cable = true, Motor = true }) or find(STAIRS)
	end
	return nil
end

local function refresh()
	local s = ClientState.Get()
	target = if s then targetFor(s) else nil
	billboard.Adornee = target
	billboard.Enabled = target ~= nil
end

function ObjectiveMarkerController.Start()
	billboard = Instance.new("BillboardGui")
	billboard.Name = "ObjectiveMarker"
	billboard.Size = UDim2.fromOffset(120, 70)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 7, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Enabled = false
	billboard.Parent = player:WaitForChild("PlayerGui")

	-- A downward chevron drawn from two bars (the ▼ glyph is missing from the game fonts).
	local arrow = Instance.new("Frame")
	arrow.BackgroundTransparency = 1
	arrow.Size = UDim2.fromScale(1, 0.62)
	arrow.Parent = billboard
	for _, side in { -1, 1 } do
		local bar = Instance.new("Frame")
		bar.AnchorPoint = Vector2.new(0.5, 0.5)
		bar.Position = UDim2.new(0.5, side * 9, 0.45, 0)
		bar.Size = UDim2.fromOffset(30, 9)
		bar.Rotation = side * -45
		bar.BackgroundColor3 = Theme.Colors.Amber
		bar.BorderSizePixel = 0
		bar.Parent = arrow
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = bar
	end

	distanceLabel = Instance.new("TextLabel")
	distanceLabel.BackgroundTransparency = 1
	distanceLabel.Position = UDim2.fromScale(0, 0.62)
	distanceLabel.Size = UDim2.fromScale(1, 0.38)
	distanceLabel.TextScaled = true
	distanceLabel.FontFace = Theme.Bold
	distanceLabel.TextColor3 = Color3.new(1, 1, 1)
	distanceLabel.TextStrokeTransparency = 0.3
	distanceLabel.Parent = billboard

	ClientState.Changed:Connect(refresh)
	-- The nearest loot changes as the player walks, so look again twice a second.
	task.spawn(function()
		while true do
			task.wait(0.5)
			refresh()
		end
	end)
	task.spawn(function()
		workspace:WaitForChild(GameConfig.World.FolderName, 60)
		refresh()
	end)

	-- Gentle bob and the live distance. Idle nudge from the server makes the bob stronger briefly.
	local clock = 0
	local nudgeUntil = 0
	player:GetAttributeChangedSignal("ObjectiveNudge"):Connect(function()
		nudgeUntil = os.clock() + 3.5
	end)
	RunService.RenderStepped:Connect(function(dt)
		if not target then
			return
		end
		clock += dt
		local nudged = os.clock() < nudgeUntil
		local amp = if nudged then 1.8 else 0.6
		local speed = if nudged then 7 else 3
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 7 + math.sin(clock * speed) * amp, 0)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local distance = math.floor((root.Position - target.Position).Magnitude)
			-- The way down gets "Stairs · 14 m" (studs shown as metres).
			distanceLabel.Text = if target.Name == "Ramp0_Down"
				then Lang.T("hud.stairs", math.floor(distance * 0.28 + 0.5))
				else Lang.T("marker.here", distance)
		end
	end)
end

return ObjectiveMarkerController
