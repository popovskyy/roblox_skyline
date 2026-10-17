--!strict
-- HUD: health, carry weight, flashlight battery, hazard warnings, objective and short messages.
-- Kept to the screen edges so the centre stays clear while exploring.

local Theme = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Theme"))
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local ClientState = require(script.Parent.ClientState)
local Lang = require(script.Parent.Lang)
local UIKit = require(script.Parent.UIKit)

local HUDController = {}

local player = Players.LocalPlayer
local C = UIKit.Colors

local healthFill: Frame
local healthText: TextLabel
local hungerFill: Frame
local hungerText: TextLabel
local flashlightText: TextLabel
local warningText: TextLabel
local objectiveText: TextLabel
local actsText: TextLabel
local toastHolder: Frame

local function buildStatusPanel(screen: ScreenGui)
	local panel = UIKit.Panel({
		Name = "Status",
		-- PC/console: bottom-left (chat sits top-left). Touch: top-left, because the thumbstick owns bottom-left.
		AnchorPoint = if UserInputService.TouchEnabled then Vector2.new(0, 0) else Vector2.new(0, 1),
		Position = if UserInputService.TouchEnabled then UDim2.fromOffset(12, 56) else UDim2.new(0, 12, 1, -12),
		Size = UDim2.fromOffset(230, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
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
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = Theme.Bold,
		TextSize = 14,
		ZIndex = 2,
		Parent = bar,
	})
	local hungerBar = UIKit.New("Frame", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundColor3 = C.panelLight,
		BorderSizePixel = 0,
		LayoutOrder = 2,
		Parent = panel,
	}, { UIKit.Corner(6) })
	hungerFill = UIKit.New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(214, 150, 60),
		BorderSizePixel = 0,
		Parent = hungerBar,
	}, { UIKit.Corner(6) })
	hungerText = UIKit.Label({
		Size = UDim2.fromScale(1, 1),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = Theme.Bold,
		TextSize = 14,
		ZIndex = 2,
		Parent = hungerBar,
	})
	flashlightText = UIKit.Label({
		Size = UDim2.new(1, 0, 0, 20),
		Text = "",
		TextColor3 = C.muted,
		LayoutOrder = 4,
		Visible = false,
		Parent = panel,
	})
	warningText = UIKit.Label({
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = "",
		FontFace = Theme.Bold,
		TextColor3 = C.warn,
		LayoutOrder = 5,
		Parent = panel,
	})
end

local function buildObjective(screen: ScreenGui)
	local panel = UIKit.Panel({
		Name = "Objective",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		-- Narrow enough to never reach the buttons in the top-right corner.
		Size = UDim2.fromScale(0.42, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = screen,
	})
	UIKit.New("UISizeConstraint", { MaxSize = Vector2.new(460, 120), Parent = panel })
	UIKit.Padding(8).Parent = panel
	objectiveText = UIKit.Label({
		Size = UDim2.new(1, -78, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = "",
		TextSize = 15,
		Parent = panel,
	})
	actsText = UIKit.Label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(74, 20),
		Text = "",
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

local function updateHunger()
	local value = player:GetAttribute("Hunger")
	local hunger = if type(value) == "number" then value else 100
	hungerFill.Size = UDim2.fromScale(math.clamp(hunger / 100, 0, 1), 1)
	hungerFill.BackgroundColor3 = if hunger <= 25 then C.bad else Color3.fromRGB(214, 150, 60)
	hungerText.Text = Lang.T("hud.hunger", math.floor(hunger))
end

local function updateHealth()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local ratio = if humanoid.MaxHealth > 0 then math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1) else 0
	healthFill.Size = UDim2.fromScale(ratio, 1)
	healthText.Text = Lang.T("hud.health", math.ceil(humanoid.Health), humanoid.MaxHealth)
end

local function updateWarnings()
	local lines = {}
	if player:GetAttribute("InToxic") == true then
		table.insert(lines, Lang.T("hud.toxic"))
	end
	if player:GetAttribute("Hungry") == true then
		table.insert(lines, Lang.T("hud.hungry"))
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
	flashlightText.Text = Lang.T("hud.flashlight", Lang.T(if on then "hud.on" else "hud.off"), seconds) .. "  [F]"
	flashlightText.TextColor3 = if seconds <= 0 then C.bad elseif on then C.accent else C.muted
end

local function objectiveLine(s: { [string]: any }): string
	local tutorial = s.tutorial
	if not tutorial then
		return ""
	end
	if tutorial.done then
		return Lang.T("hud.objective", { ref = "tutorial.done" })
	end
	local step = tutorial.step
	local inv = s.inventory or {}
	local storage = s.storage or {}
	local function total(id: string): number
		return (inv[id] or 0) + (storage[id] or 0)
	end
	-- Live n/m for loot steps (gap-report G1.1 / first-session-ux §3).
	if step == 2 then
		return Lang.T("hud.objective", Lang.T("tutorial.scrapProgress", math.min(total("Scrap"), 3), 3))
	elseif step == 5 then
		return Lang.T("hud.objective", Lang.T("tutorial.elecProgress", math.min(total("Electronics"), 4), 4))
	end
	return Lang.T("hud.objective", { ref = tutorial.text })
end

local function onState(s: { [string]: any })
	objectiveText.Text = objectiveLine(s)
	actsText.Text = Lang.T("hud.systems", s.acts or 0)
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

-- Only shown once the lobby place exists (PlacesConfig.LobbyPlaceId).
local function buildLobbyButton(screen: ScreenGui)
	local PlacesConfig = require(game:GetService("ReplicatedStorage").Shared.PlacesConfig)
	if PlacesConfig.LobbyPlaceId == 0 then
		return
	end
	local button = UIKit.Button({
		Name = "LobbyButton",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -64, 0, 8),
		Size = UDim2.fromOffset(84, 44),
		Text = "",
		TextSize = 15,
		Parent = screen,
	})
	Lang.Bind(button, "ui.toLobby")
	button.Activated:Connect(function()
		local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
		local remote = remotes and remotes:FindFirstChild("ReturnToLobby")
		if remote and remote:IsA("RemoteEvent") then
			remote:FireServer()
		end
	end)
end

function HUDController.Start()
	local screen = UIKit.Screen()
	buildLobbyButton(screen)
	buildStatusPanel(screen)
	buildObjective(screen)
	buildToasts(screen)

	ClientState.Changed:Connect(onState)
	Lang.Changed:Connect(function()
		updateHealth()
		updateWarnings()
	end)
	player:GetAttributeChangedSignal("InToxic"):Connect(updateWarnings)
	player:GetAttributeChangedSignal("Hungry"):Connect(updateWarnings)
	player:GetAttributeChangedSignal("Hunger"):Connect(updateHunger)
	Lang.Changed:Connect(updateHunger)
	updateHunger()
	player:GetAttributeChangedSignal("FlashlightCharge"):Connect(updateFlashlight)
	player:GetAttributeChangedSignal("FlashlightOn"):Connect(updateFlashlight)
	if player.Character then
		task.spawn(watchCharacter, player.Character)
	end
	player.CharacterAdded:Connect(watchCharacter)
end

return HUDController
