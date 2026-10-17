--!strict
-- A floating "here" arrow over the place the current tutorial step needs: the terminal, the stairs,
-- nearest scrap/electronics, the chest spot, the generator, the bridge. Visible through walls.

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

local function playerRoot(): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function isTaken(part: BasePart, s: { [string]: any }): boolean
	local nodeId = part:GetAttribute("NodeId")
	if type(nodeId) ~= "string" then
		return true
	end
	if part:GetAttribute("Unique") == true then
		return s.uniqueNodesTaken ~= nil and s.uniqueNodesTaken[nodeId] == true
	end
	return s.depletedNodes ~= nil and s.depletedNodes[nodeId] == true
end

local function rubbleOk(part: BasePart, s: { [string]: any }): boolean
	local required = part:GetAttribute("RequiresRubble")
	if type(required) ~= "string" then
		return true
	end
	return s.clearedRubble ~= nil and s.clearedRubble[required] == true
end

-- Nearest available resource node of the given item (not depleted, rubble cleared if gated).
local function nearestResource(itemId: string, s: { [string]: any }): BasePart?
	local world = workspace:FindFirstChild(GameConfig.World.FolderName)
	local folder = world and world:FindFirstChild("Interactables")
	if not folder then
		return nil
	end
	local root = playerRoot()
	local best: BasePart? = nil
	local bestDist = math.huge
	local origin = if root then root.Position else Vector3.zero
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("InteractType") == "Resource" and d:GetAttribute("ItemId") == itemId then
			if not isTaken(d, s) and rubbleOk(d, s) then
				local dist = (d.Position - origin).Magnitude
				if dist < bestDist then
					best = d
					bestDist = dist
				end
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
	elseif step == 2 then
		-- Point at nearest scrap, not the stairs (gap-report G1.2).
		return nearestResource("Scrap", s) or find(STAIRS)
	elseif step == 5 then
		return nearestResource("Electronics", s) or find(STAIRS)
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
		return find(STAIRS)
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

	local arrow = Instance.new("TextLabel")
	arrow.BackgroundTransparency = 1
	arrow.Size = UDim2.fromScale(1, 0.62)
	arrow.Text = "▼"
	arrow.TextScaled = true
	arrow.FontFace = Theme.Display
	arrow.TextColor3 = Color3.fromRGB(255, 196, 64)
	arrow.TextStrokeTransparency = 0.3
	arrow.Parent = billboard

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
	task.spawn(function()
		workspace:WaitForChild(GameConfig.World.FolderName, 60)
		refresh()
	end)

	-- Gentle bob and the live distance; re-pick nearest loot periodically.
	-- Idle 45s on roof with step 1 incomplete → one soft ping (bob + click), not text spam.
	local clock = 0
	local retargetAt = 0
	local idleSeconds = 0
	local idlePinged = false
	local lastRootPos: Vector3? = nil
	local bobAmp = 0.6
	local bobSpeed = 3
	RunService.RenderStepped:Connect(function(dt)
		clock += dt
		retargetAt += dt
		if retargetAt > 0.5 then
			retargetAt = 0
			refresh()
		end
		local s = ClientState.Get()
		local step1 = s and s.tutorial and not s.tutorial.done and s.tutorial.step == 1
		local root = playerRoot()
		if step1 and root then
			local moved = lastRootPos and (root.Position - lastRootPos).Magnitude > 1.5
			lastRootPos = root.Position
			if moved then
				idleSeconds = 0
			else
				idleSeconds += dt
			end
			if idleSeconds >= 45 and not idlePinged then
				idlePinged = true
				bobAmp = 1.8
				bobSpeed = 7
				local sound = Instance.new("Sound")
				sound.SoundId = "rbxassetid://15675032796" -- Click
				sound.Volume = 0.45
				sound.Parent = root
				sound:Play()
				task.delay(1.2, function()
					sound:Destroy()
					bobAmp = 0.6
					bobSpeed = 3
				end)
			end
		else
			idleSeconds = 0
			idlePinged = false
			lastRootPos = if root then root.Position else nil
		end
		if not target then
			return
		end
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 7 + math.sin(clock * bobSpeed) * bobAmp, 0)
		if root then
			local distance = math.floor((root.Position - target.Position).Magnitude)
			distanceLabel.Text = Lang.T("marker.here", distance)
		end
	end)
end

return ObjectiveMarkerController
