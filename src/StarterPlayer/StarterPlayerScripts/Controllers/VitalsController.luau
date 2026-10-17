--!strict
-- Health and hunger (ui/HUD_SPEC.md, section 3). Health is ten segments with a trailing amber "chip" on
-- damage and a green one on healing; hunger is a thin olive bar. Up to two state badges (down, starving,
-- toxic, low health) and an edge vignette (red for danger, teal for toxic air).
-- PC / gamepad: bottom-left. Phone: in the top bar row, right of the Roblox buttons.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ClientState = require(script.Parent.ClientState)
local Lang = require(script.Parent.Lang)
local UIKit = require(script.Parent.UIKit)

local VitalsController = {}

local player = Players.LocalPlayer
local T = Theme.Colors
local SEGMENTS = 10

local touch = UIKit.IsTouch()
local SIZE = if touch
	then { icon = 18, segW = 14, segH = 12, segGap = 2, value = 19, barW = 158, barH = 8, padY = 7, padX = 10, gap = 6 }
	else {
		icon = 26,
		segW = 27,
		segH = 18,
		segGap = 3,
		value = 30,
		barW = 300,
		barH = 10,
		padY = 14,
		padX = 16,
		gap = 10,
	}

local panel: Frame
local shakeHolder: Frame
local healthIcon: Frame
local segments: { { chip: Frame, fill: Frame } } = {}
local valueLabel: TextLabel
local hungerIcon: ImageLabel
local hungerFill: Frame
local badgeRow: Frame
local flashlightLabel: TextLabel
local dangerVignette: Frame
local toxicVignette: Frame

-- Shown values: `fill` is the health bar, `chip` the trailing amber/green part.
local fillValue = Instance.new("NumberValue")
local chipValue = Instance.new("NumberValue")
local lastHealth = -1
local maxHealth = 100
local chipToken = 0
local pulseToken = 0
local eatHinted = false
local medkitHinted = false

-- Four soft gradients along the screen edges.
local function vignette(color: Color3, transparency: number): Frame
	local root = UIKit.New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = UIKit.FullScreen(),
	})
	local edges = {
		{ size = UDim2.fromScale(1, 0.22), pos = UDim2.fromScale(0, 0), rot = 90 },
		{ size = UDim2.fromScale(1, 0.22), pos = UDim2.fromScale(0, 0.78), rot = -90 },
		{ size = UDim2.fromScale(0.18, 1), pos = UDim2.fromScale(0, 0), rot = 0 },
		{ size = UDim2.fromScale(0.18, 1), pos = UDim2.fromScale(0.82, 0), rot = 180 },
	}
	for _, e in edges do
		local frame = UIKit.New("Frame", {
			Size = e.size,
			Position = e.pos,
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = root,
		})
		UIKit.New("UIGradient", {
			Rotation = e.rot,
			Transparency = NumberSequence.new(transparency, 1),
			Parent = frame,
		})
	end
	return root
end

local function badge(textKey: string, background: Color3, textColor: Color3, order: number): TextLabel
	local label = UIKit.Label({
		Name = textKey,
		Size = UDim2.fromOffset(0, if touch then 18 else 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 0,
		BackgroundColor3 = background,
		Text = Lang.T(textKey),
		FontFace = Theme.Bold,
		TextSize = if touch then 13 else 14,
		TextColor3 = textColor,
		TextWrapped = false,
		LayoutOrder = order,
		Parent = badgeRow,
	})
	UIKit.Corner(5).Parent = label
	UIKit.New("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		Parent = label,
	})
	return label
end

local function build()
	local parent = if touch then UIKit.TopScreen() else UIKit.Screen()
	panel = UIKit.New("Frame", {
		Name = "Vitals",
		AnchorPoint = if touch then Vector2.zero else Vector2.new(0, 1),
		Position = if touch then UDim2.fromOffset(12, 6) else UDim2.new(0, 24, 1, -24),
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Parent = parent,
	}, { UIKit.Corner(12) })
	UIKit.New("UIPadding", {
		PaddingTop = UDim.new(0, SIZE.padY),
		PaddingBottom = UDim.new(0, SIZE.padY),
		PaddingLeft = UDim.new(0, SIZE.padX),
		PaddingRight = UDim.new(0, SIZE.padX),
		Parent = panel,
	})
	shakeHolder = UIKit.New("Frame", {
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Parent = panel,
	})
	UIKit.New("UIListLayout", {
		Padding = UDim.new(0, SIZE.gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = shakeHolder,
	})
	local function row(order: number): Frame
		local r = UIKit.New("Frame", {
			Size = UDim2.fromOffset(0, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			LayoutOrder = order,
			Parent = shakeHolder,
		})
		UIKit.New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, if touch then 8 else 12),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = r,
		})
		return r
	end

	-- Health: a cross drawn from two bars, ten segments, the number.
	local healthRow = row(1)
	healthIcon = UIKit.New("Frame", {
		Size = UDim2.fromOffset(SIZE.icon, SIZE.icon),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = healthRow,
	})
	for _, size in { UDim2.fromScale(1, 0.34), UDim2.fromScale(0.34, 1) } do
		UIKit.New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = size,
			BackgroundColor3 = T.Cream,
			BorderSizePixel = 0,
			Parent = healthIcon,
		}, { UIKit.Corner(2) })
	end
	local segRow = UIKit.New("Frame", {
		Size = UDim2.fromOffset(SEGMENTS * SIZE.segW + (SEGMENTS - 1) * SIZE.segGap, SIZE.segH),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = healthRow,
	})
	UIKit.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, SIZE.segGap),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = segRow,
	})
	for i = 1, SEGMENTS do
		local seg = UIKit.New("Frame", {
			Size = UDim2.fromOffset(SIZE.segW, SIZE.segH),
			BackgroundColor3 = T.Cream,
			BackgroundTransparency = 0.84,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			LayoutOrder = i,
			Parent = segRow,
		}, { UIKit.Corner(2) })
		local chip = UIKit.New("Frame", {
			Size = UDim2.fromScale(0, 1),
			BackgroundColor3 = T.Amber,
			BorderSizePixel = 0,
			Parent = seg,
		})
		local fill = UIKit.New("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = T.Cream,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = seg,
		})
		segments[i] = { chip = chip, fill = fill }
	end
	valueLabel = UIKit.Label({
		Size = UDim2.fromOffset(if touch then 30 else 48, SIZE.value + 4),
		Text = "100",
		FontFace = Theme.Display,
		TextSize = SIZE.value,
		TextColor3 = T.Cream,
		TextWrapped = false,
		LayoutOrder = 3,
		Parent = healthRow,
	})

	-- Hunger: the food icon tinted olive, a thin bar, the word on PC, then state badges.
	local hungerRow = row(2)
	local food = ItemDefinitions.Get("Food")
	hungerIcon = UIKit.New("ImageLabel", {
		Size = UDim2.fromOffset(SIZE.icon, SIZE.icon),
		BackgroundTransparency = 1,
		Image = if food and food.iconImage then food.iconImage else "",
		ImageColor3 = T.Hunger,
		LayoutOrder = 1,
		Parent = hungerRow,
	})
	local bar = UIKit.New("Frame", {
		Size = UDim2.fromOffset(SIZE.barW, SIZE.barH),
		BackgroundColor3 = T.Cream,
		BackgroundTransparency = 0.84,
		BorderSizePixel = 0,
		LayoutOrder = 2,
		Parent = hungerRow,
	}, { UIKit.Corner(5) })
	hungerFill = UIKit.New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = T.Hunger,
		BorderSizePixel = 0,
		Parent = bar,
	}, { UIKit.Corner(5) })
	if not touch then
		local word = UIKit.Label({
			Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = Lang.T("hud.hungerWord"),
			TextSize = 15,
			TextColor3 = T.CreamDim,
			TextWrapped = false,
			LayoutOrder = 3,
			Parent = hungerRow,
		})
		Lang.Changed:Connect(function()
			word.Text = Lang.T("hud.hungerWord")
		end)
	end
	badgeRow = UIKit.New("Frame", {
		Size = UDim2.fromOffset(0, if touch then 18 else 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		LayoutOrder = 4,
		Parent = hungerRow,
	})
	UIKit.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = badgeRow,
	})

	-- Flashlight battery, only while carrying one.
	flashlightLabel = UIKit.Label({
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = "",
		TextSize = if touch then 13 else 15,
		TextColor3 = T.CreamDim,
		TextWrapped = false,
		Visible = false,
		LayoutOrder = 3,
		Parent = shakeHolder,
	})

	dangerVignette = vignette(T.Danger, 0.55)
	toxicVignette = vignette(T.ToxicFog, 0.6)
end

-- Phones: keep the panel just right of the Roblox buttons in the top bar.
local function placeOnTopbar()
	if not touch then
		return
	end
	local inset = GuiService.TopbarInset
	panel.Position = UDim2.fromOffset(inset.Min.X + 12, inset.Min.Y + 6)
end

local function render()
	local per = maxHealth / SEGMENTS
	local fillHp, chipHp = fillValue.Value, chipValue.Value
	local healing = chipHp > fillHp and chipHp > lastHealth - 0.01 and lastHealth >= fillHp
	for i, seg in segments do
		local from = (i - 1) * per
		seg.fill.Size = UDim2.fromScale(math.clamp((fillHp - from) / per, 0, 1), 1)
		seg.chip.Size = UDim2.fromScale(math.clamp((chipHp - from) / per, 0, 1), 1)
		seg.chip.BackgroundColor3 = if healing then T.Heal else T.Amber
	end
end
fillValue.Changed:Connect(render)
chipValue.Changed:Connect(render)

local function isDowned(): boolean
	return player:GetAttribute("Downed") == true
end

local function setPulse(on: boolean)
	pulseToken += 1
	local token = pulseToken
	for _, seg in segments do
		seg.fill.BackgroundTransparency = 0
	end
	if not on then
		return
	end
	task.spawn(function()
		while pulseToken == token do
			for _, t in { 0.35, 0 } do
				for _, seg in segments do
					TweenService:Create(seg.fill, TweenInfo.new(0.5), { BackgroundTransparency = t }):Play()
				end
				task.wait(0.5)
				if pulseToken ~= token then
					return
				end
			end
		end
	end)
end

local lowShown = false
local function updateBadges()
	for _, child in badgeRow:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local hp = lastHealth
	local list = {}
	if isDowned() then
		table.insert(list, { "hud.downedBadge", T.DangerBg, T.DangerText })
	end
	if player:GetAttribute("Hungry") == true then
		table.insert(list, { "hud.starving", T.DangerBg, T.DangerText })
	end
	if player:GetAttribute("InToxic") == true then
		table.insert(list, { "hud.toxicBadge", T.Toxic, T.Cream })
	end
	local low = not isDowned() and hp >= 0 and hp <= 30
	if low then
		table.insert(list, { "hud.lowHealth", T.DangerBg, T.DangerText })
	end
	for i = 1, math.min(#list, 2) do
		local b = list[i]
		badge(b[1], b[2], b[3], i)
	end
	-- Low health: red fill, pulsing, red edges. Toxic air: teal edges instead.
	for _, seg in segments do
		seg.fill.BackgroundColor3 = if low then T.Danger else T.Cream
	end
	for _, bar in healthIcon:GetChildren() do
		if bar:IsA("Frame") then
			bar.BackgroundColor3 = if low or isDowned() then T.Danger else T.Cream
		end
	end
	if low ~= lowShown then
		lowShown = low
		setPulse(low)
		-- First time low on health this match: say where medkits come from.
		if low and not medkitHinted then
			medkitHinted = true
			VitalsController.Hint(Lang.T("hud.medkitHint"))
		end
	end
	local over = player:GetAttribute("MatchOver") == true
	toxicVignette.Visible = player:GetAttribute("InToxic") == true and not over
	dangerVignette.Visible = (low or isDowned()) and not toxicVignette.Visible and not over
	panel.BackgroundColor3 = if isDowned() then Color3.fromRGB(90, 22, 18) else T.Panel
	panel.BackgroundTransparency = if isDowned() then 0.15 else 0.35
end

local function shake()
	local base = UDim2.fromOffset(0, 0)
	task.spawn(function()
		for _, dx in { 2, -2, 1, 0 } do
			shakeHolder.Position = UDim2.fromOffset(dx, 0)
			task.wait(0.04)
		end
		shakeHolder.Position = base
	end)
end

local function onHealth(health: number, max: number)
	maxHealth = math.max(max, 1)
	local hp = if isDowned() then 0 else math.max(health, 0)
	valueLabel.Text = tostring(math.ceil(hp))
	if lastHealth < 0 then
		fillValue.Value = hp
		chipValue.Value = hp
	elseif hp < lastHealth then
		-- Hit: the chip waits on the old value, then slides down.
		chipToken += 1
		local token = chipToken
		chipValue.Value = math.max(chipValue.Value, lastHealth)
		fillValue.Value = hp
		shake()
		task.delay(0.4, function()
			if chipToken == token then
				TweenService:Create(chipValue, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Value = hp }):Play()
			end
		end)
	elseif hp > lastHealth then
		-- Healed: the green chip jumps to the new value and the bar grows into it.
		chipToken += 1
		chipValue.Value = hp
		TweenService:Create(fillValue, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Value = hp }):Play()
	end
	lastHealth = hp
	updateBadges()
end

local hungerToken = 0
local function updateHunger()
	local value = player:GetAttribute("Hunger")
	local hunger = if type(value) == "number" then value else GameConfig.HungerMax
	local ratio = math.clamp(hunger / GameConfig.HungerMax, 0, 1)
	hungerFill.Size = UDim2.fromScale(ratio, 1)
	local starving = player:GetAttribute("Hungry") == true
	local low = ratio < 0.25
	local color = if starving then T.Danger elseif low then T.Amber else T.Hunger
	hungerFill.BackgroundColor3 = color
	hungerIcon.ImageColor3 = color
	-- Low: a gentle blink every 3 s and one "eat something" message.
	hungerToken += 1
	local token = hungerToken
	if low and not starving then
		if not eatHinted then
			eatHinted = true
			VitalsController.Hint(Lang.T("hud.eatHint"))
		end
		task.spawn(function()
			while hungerToken == token do
				TweenService:Create(hungerFill, TweenInfo.new(0.25), { BackgroundTransparency = 0.6 }):Play()
				task.wait(0.3)
				TweenService:Create(hungerFill, TweenInfo.new(0.25), { BackgroundTransparency = 0 }):Play()
				task.wait(2.7)
			end
		end)
	else
		hungerFill.BackgroundTransparency = 0
		if not low then
			eatHinted = false
		end
	end
	updateBadges()
end

local function updateFlashlight()
	local s = ClientState.Get()
	local has = s ~= nil and s.inventory ~= nil and (s.inventory.Flashlight or 0) > 0
	flashlightLabel.Visible = has
	if not has then
		return
	end
	local charge = player:GetAttribute("FlashlightCharge")
	local seconds = if type(charge) == "number" then charge else (s and s.flashlightCharge or 0)
	local on = player:GetAttribute("FlashlightOn") == true
	flashlightLabel.Text = Lang.T("hud.flashlight", Lang.T(if on then "hud.on" else "hud.off"), seconds)
	flashlightLabel.TextColor3 = if seconds <= 0 then T.Danger elseif on then T.AmberText else T.CreamDim
end

local function watchCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end
	lastHealth = -1
	local function update()
		onHealth(humanoid.Health, humanoid.MaxHealth)
	end
	humanoid.HealthChanged:Connect(update)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update)
	update()
end

-- Set by ClientMain: a short on-screen message.
VitalsController.Hint = function(_text: string) end

function VitalsController.Start()
	build()
	placeOnTopbar()
	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(placeOnTopbar)
	for _, attribute in { "Hunger", "Hungry" } do
		player:GetAttributeChangedSignal(attribute):Connect(updateHunger)
	end
	for _, attribute in { "InToxic", "Downed", "MatchOver" } do
		player:GetAttributeChangedSignal(attribute):Connect(function()
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				onHealth(humanoid.Health, humanoid.MaxHealth)
			else
				updateBadges()
			end
		end)
	end
	player:GetAttributeChangedSignal("FlashlightCharge"):Connect(updateFlashlight)
	player:GetAttributeChangedSignal("FlashlightOn"):Connect(updateFlashlight)
	ClientState.Changed:Connect(updateFlashlight)
	Lang.Changed:Connect(function()
		updateBadges()
		updateFlashlight()
	end)
	updateHunger()
	if player.Character then
		task.spawn(watchCharacter, player.Character)
	end
	player.CharacterAdded:Connect(watchCharacter)
end

return VitalsController
