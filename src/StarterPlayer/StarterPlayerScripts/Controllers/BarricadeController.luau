--!strict
-- The barricade on the roof stair mouth, made readable: a health bar over the boards once built
-- ("БАРИКАДА 60 / 100", red when it is about to give way), the repair prompt only while it is damaged,
-- and a one-time hint on the first horde wave when the team has not built one yet.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ClientState = require(script.Parent.ClientState)
local Lang = require(script.Parent.Lang)
local UIKit = require(script.Parent.UIKit)

local BarricadeController = {}

local player = Players.LocalPlayer
local T = Theme.Colors

-- Set by ClientMain: a short on-screen message.
BarricadeController.Hint = function(_text: string) end

local billboard: BillboardGui
local fill: Frame
local label: TextLabel
local hinted = false

local function built(): boolean
	local s = ClientState.Get()
	return s ~= nil and s.upgrades ~= nil and s.upgrades.Barricade == true
end

local function update()
	local hp = workspace:GetAttribute("BarricadeHp")
	local max = workspace:GetAttribute("BarricadeMax")
	hp = if type(hp) == "number" then hp else 0
	max = if type(max) == "number" and max > 0 then max else 100
	local isBuilt = built()
	billboard.Enabled = isBuilt
	local ratio = math.clamp(hp / max, 0, 1)
	fill.Size = UDim2.fromScale(ratio, 1)
	fill.BackgroundColor3 = if ratio <= 0.3 then T.Danger else T.Amber
	label.Text = if hp <= 0 then Lang.T("barricade.brokenLabel") else Lang.T("barricade.hp", math.ceil(hp), max)
	label.TextColor3 = if hp <= 0 then T.DangerText else T.Cream
	-- Repair prompt: only when there is something to repair.
	local world = workspace:FindFirstChild(GameConfig.World.FolderName)
	local interactables = world and world:FindFirstChild("Interactables")
	local repair = interactables and interactables:FindFirstChild("BarricadeRepair")
	local prompt = repair and repair:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Enabled = isBuilt and hp < max
	end
end

local function onWave()
	local wave = workspace:GetAttribute("HordeWave")
	if not hinted and type(wave) == "number" and wave >= 1 and not built() then
		hinted = true
		BarricadeController.Hint(Lang.T("hint.barricade"))
	end
end

function BarricadeController.Start()
	billboard = UIKit.New("BillboardGui", {
		Name = "BarricadeHealth",
		Size = UDim2.fromOffset(200, 44),
		StudsOffsetWorldSpace = Vector3.new(0, 5.5, 0),
		LightInfluence = 0,
		MaxDistance = 80,
		Enabled = false,
		Parent = player:WaitForChild("PlayerGui"),
	})
	label = UIKit.Label({
		Size = UDim2.new(1, 0, 0, 22),
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = Theme.Display,
		TextSize = 18,
		TextStrokeTransparency = 0.3,
		Parent = billboard,
	})
	local bar = UIKit.New("Frame", {
		Position = UDim2.fromOffset(20, 26),
		Size = UDim2.new(1, -40, 0, 10),
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Parent = billboard,
	}, { UIKit.Corner(5) })
	fill = UIKit.New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = T.Amber,
		BorderSizePixel = 0,
		Parent = bar,
	}, { UIKit.Corner(5) })

	task.spawn(function()
		local world = workspace:WaitForChild(GameConfig.World.FolderName, 60)
		local roof = world and world:WaitForChild("RoofBase", 60)
		local visuals = roof and roof:WaitForChild("UpgradeVisuals", 60)
		local barrier = visuals and visuals:WaitForChild("BarricadeBarrier", 60)
		if barrier and barrier:IsA("BasePart") then
			billboard.Adornee = barrier
		end
		update()
	end)
	workspace:GetAttributeChangedSignal("BarricadeHp"):Connect(update)
	workspace:GetAttributeChangedSignal("HordeWave"):Connect(onWave)
	ClientState.Changed:Connect(update)
	Lang.Changed:Connect(update)
end

return BarricadeController
