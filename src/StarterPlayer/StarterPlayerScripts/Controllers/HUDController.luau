--!strict
-- HUD: health, carry weight, flashlight battery, hazard warnings, objective and short messages.
-- Kept to the screen edges so the centre stays clear while exploring.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local ClientState = require(script.Parent.ClientState)
local UIKit = require(script.Parent.UIKit)

local HUDController = {}

local player = Players.LocalPlayer
local C = UIKit.Colors

local healthFill: Frame
local healthText: TextLabel
local weightText: TextLabel
local flashlightText: TextLabel
local warningText: TextLabel
local objectiveText: TextLabel
local actsText: TextLabel
local toastHolder: Frame

local function buildStatusPanel(screen: ScreenGui)
	local panel = UIKit.Panel({
		Name = "Status",
		-- Bottom-left: the default chat window lives in the top-left corner.
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 12, 1, -12),
		Size = UDim2.fromOffset(250, 150),
		Parent = screen,
	})
	UIKit.Padding(10).Parent = panel
	UIKit.New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })

	local bar = UIKit.New("Frame", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundColor3 = C.panelLight,
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Parent = panel,
	}, { UIKit.Corner(6) })
	healthFill = UIKit.New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.health,
		BorderSizePixel = 0,
		Parent = bar,
	}, { UIKit.Corner(6) })
	healthText = UIKit.Label({
		Size = UDim2.fromScale(1, 1),
		Text = "Здоров'я 100 / 100",
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		ZIndex = 2,
		Parent = bar,
	})
	weightText =
		UIKit.Label({ Size = UDim2.new(1, 0, 0, 20), Text = "Вага 0 / 20", LayoutOrder = 2, Parent = panel })
	flashlightText = UIKit.Label({
		Size = UDim2.new(1, 0, 0, 20),
		Text = "",
		TextColor3 = C.muted,
		LayoutOrder = 3,
		Visible = false,
		Parent = panel,
	})
	warningText = UIKit.Label({
		Size = UDim2.new(1, 0, 0, 40),
		Text = "",
		Font = Enum.Font.GothamBold,
		TextColor3 = C.warn,
		LayoutOrder = 4,
		Parent = panel,
	})
end

local function buildObjective(screen: ScreenGui)
	local panel = UIKit.Panel({
		Name = "Objective",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(520, 56),
		Parent = screen,
	})
	UIKit.New("UISizeConstraint", { MaxSize = Vector2.new(520, 80), Parent = panel })
	panel.Size = UDim2.new(0.6, 0, 0, 56)
	UIKit.Padding(8).Parent = panel
	objectiveText = UIKit.Label({
		Size = UDim2.new(1, -90, 1, 0),
		Text = "Ціль: ...",
		TextSize = 15,
		Parent = panel,
	})
	actsText = UIKit.Label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, 85, 1, 0),
		Text = "Системи 0/3",
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = C.accent,
		TextSize = 14,
		Parent = panel,
	})
end

local function buildToasts(screen: ScreenGui)
	toastHolder = UIKit.New("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 72),
		Size = UDim2.fromOffset(320, 300),
		BackgroundTransparency = 1,
		Parent = screen,
	})
	UIKit.New("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Parent = toastHolder,
	})
end

local toastCounter = 0
local KIND_COLORS = {
	info = C.text,
	success = C.good,
	warning = C.warn,
	error = C.bad,
}

function HUDController.Toast(text: string, kind: string?)
	toastCounter += 1
	local children = toastHolder:GetChildren()
	local toasts = {}
	for _, child in children do
		if child:IsA("Frame") then
			table.insert(toasts, child)
		end
	end
	if #toasts >= 4 then
		table.sort(toasts, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		toasts[1]:Destroy()
	end
	local toast = UIKit.Panel({
		Size = UDim2.fromOffset(320, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = toastCounter,
		Parent = toastHolder,
	})
	UIKit.Padding(8).Parent = toast
	local label = UIKit.Label({
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = text,
		TextSize = 15,
		TextColor3 = KIND_COLORS[kind or "info"] or C.text,
		Parent = toast,
	})
	task.delay(3.5, function()
		if toast.Parent then
			local info = TweenInfo.new(0.4)
			TweenService:Create(toast, info, { BackgroundTransparency = 1 }):Play()
			TweenService:Create(label, info, { TextTransparency = 1 }):Play()
			task.wait(0.45)
			toast:Destroy()
		end
	end)
end

local function updateHealth()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local ratio = if humanoid.MaxHealth > 0 then math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1) else 0
	healthFill.Size = UDim2.fromScale(ratio, 1)
	healthText.Text = ("Здоров'я %d / %d"):format(math.ceil(humanoid.Health), humanoid.MaxHealth)
end

local function updateWarnings()
	local lines = {}
	if player:GetAttribute("InToxic") == true then
		table.insert(lines, "⚠ ТОКСИЧНЕ ПОВІТРЯ")
	end
	if player:GetAttribute("Hungry") == true then
		table.insert(lines, "⚠ ГОЛОД: з'їж їжу")
	end
	warningText.Text = table.concat(lines, "\n")
end

local function updateFlashlight()
	local s = ClientState.Get()
	local has = s ~= nil and s.inventory ~= nil and (s.inventory.Flashlight or 0) > 0
	flashlightText.Visible = has
	if not has then
		return
	end
	local charge = player:GetAttribute("FlashlightCharge")
	local seconds = if type(charge) == "number" then charge else (s and s.flashlightCharge or 0)
	local on = player:GetAttribute("FlashlightOn") == true
	flashlightText.Text = ("Ліхтарик %s · %d с  [F]"):format(
		if on then "увімк." else "вимк.",
		seconds
	)
	flashlightText.TextColor3 = if seconds <= 0 then C.bad elseif on then C.accent else C.muted
end

local function onState(s: { [string]: any })
	weightText.Text = ("Вага %d / %d"):format(s.weight or 0, s.maxWeight or 0)
	weightText.TextColor3 = if (s.weight or 0) >= (s.maxWeight or 1) then C.warn else C.text
	if s.tutorial then
		objectiveText.Text = "Ціль: " .. s.tutorial.text
	end
	actsText.Text = ("Системи %d/3"):format(s.acts or 0)
	updateFlashlight()
end

local function watchCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.HealthChanged:Connect(updateHealth)
		humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealth)
		updateHealth()
	end
end

function HUDController.Start()
	local screen = UIKit.Screen()
	buildStatusPanel(screen)
	buildObjective(screen)
	buildToasts(screen)

	ClientState.Changed:Connect(onState)
	player:GetAttributeChangedSignal("InToxic"):Connect(updateWarnings)
	player:GetAttributeChangedSignal("Hungry"):Connect(updateWarnings)
	player:GetAttributeChangedSignal("FlashlightCharge"):Connect(updateFlashlight)
	player:GetAttributeChangedSignal("FlashlightOn"):Connect(updateFlashlight)
	if player.Character then
		task.spawn(watchCharacter, player.Character)
	end
	player.CharacterAdded:Connect(watchCharacter)
end

return HUDController
