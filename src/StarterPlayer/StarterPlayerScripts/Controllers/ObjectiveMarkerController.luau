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
		return find(STAIRS)
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
	arrow.TextColor3 = Theme.Colors.Amber
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

	-- Gentle bob and the live distance.
	local clock = 0
	RunService.RenderStepped:Connect(function(dt)
		if not target then
			return
		end
		clock += dt
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 7 + math.sin(clock * 3) * 0.6, 0)
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
