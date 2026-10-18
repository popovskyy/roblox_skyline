--!strict
-- Tiny helpers for building UI in code with a consistent look.

local Theme = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Theme"))
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local UIKit = {}

-- Older names kept for existing code, now mapped onto the HUD tokens (Theme.Colors), so every window
-- shares the HUD look (docs/design/POLISH_SPEC: one visual language).
local TC = Theme.Colors
UIKit.Colors = {
	panel = TC.PanelSolid,
	panelLight = Color3.fromHex("26231E"),
	text = TC.Cream,
	muted = TC.Muted,
	accent = TC.Amber,
	good = TC.Heal,
	warn = TC.Amber,
	bad = TC.Danger,
	health = TC.Danger,
	toxic = TC.ToxicFog,
}

function UIKit.New(className: string, props: { [string]: any }, children: { Instance }?): any
	local instance = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			(instance :: any)[key] = value
		end
	end
	if children then
		for _, child in children do
			child.Parent = instance
		end
	end
	if props.Parent then
		instance.Parent = props.Parent
	end
	return instance
end

function UIKit.Corner(radius: number?): UICorner
	return UIKit.New("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

function UIKit.Padding(px: number): UIPadding
	return UIKit.New("UIPadding", {
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
	})
end

function UIKit.Panel(props: { [string]: any }): Frame
	local merged = {
		BackgroundColor3 = UIKit.Colors.panel,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
	}
	for k, v in props do
		merged[k] = v
	end
	return UIKit.New("Frame", merged, { UIKit.Corner(10) })
end

-- Phones use their own layout at scale 1; nothing smaller than this stays readable there.
local TOUCH_MIN_TEXT = 13

-- Phone / tablet touch layout. Tablets often report KeyboardEnabled (on-screen or BT keyboard)
-- even when the player is tapping; Prefer Touch when that is the preferred input.
function UIKit.IsTouch(): boolean
	if not UserInputService.TouchEnabled then
		return false
	end
	local preferred = UserInputService.PreferredInput
	if preferred == Enum.PreferredInput.Touch then
		return true
	end
	if preferred == Enum.PreferredInput.Gamepad then
		return false
	end
	return not UserInputService.KeyboardEnabled
end

function UIKit.Label(props: { [string]: any }): TextLabel
	local merged = {
		BackgroundTransparency = 1,
		FontFace = Theme.Body,
		TextColor3 = UIKit.Colors.text,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	}
	for k, v in props do
		merged[k] = v
	end
	if UIKit.IsTouch() and not merged.TextScaled and merged.TextSize < TOUCH_MIN_TEXT then
		merged.TextSize = TOUCH_MIN_TEXT
	end
	return UIKit.New("TextLabel", merged)
end

-- A soft click for every button, played locally.
local clickSound: Sound? = nil
local function playClick()
	if not clickSound then
		local ok, config = pcall(function()
			return require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("SoundConfig"))
		end)
		if not ok then
			return
		end
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://" .. tostring(config.Sounds.Click[1])
		sound.Volume = 0.35
		sound.Parent = game:GetService("SoundService")
		clickSound = sound
	end
	if clickSound then
		clickSound:Play()
	end
end

function UIKit.Button(props: { [string]: any }): TextButton
	local merged = {
		BackgroundColor3 = UIKit.Colors.panelLight,
		BorderSizePixel = 0,
		FontFace = Theme.Bold,
		TextColor3 = UIKit.Colors.text,
		TextSize = 18,
		AutoButtonColor = true,
	}
	for k, v in props do
		merged[k] = v
	end
	local button = UIKit.New("TextButton", merged, { UIKit.Corner(8) })
	button.Activated:Connect(playClick)
	return button
end

-- Button kinds from the polish spec: primary / secondary / accent / danger / hold, plus disabled.
--   UIKit.KindButton("primary", { Text = ..., Size = ..., Parent = ... })
local KINDS = {
	primary = { bg = TC.Cream, bgT = 0, text = Color3.fromHex("1A1915"), stroke = nil },
	secondary = { bg = TC.PanelSolid, bgT = 1, text = TC.Cream, stroke = TC.Cream, strokeT = 0.6 },
	accent = { bg = TC.Amber, bgT = 0, text = Color3.fromHex("1A1408"), stroke = nil },
	danger = { bg = TC.PanelSolid, bgT = 1, text = TC.DangerText, stroke = TC.Danger, strokeT = 0.3 },
	hold = { bg = Color3.fromHex("3A1A16"), bgT = 0, text = Color3.fromHex("FFE3DD"), stroke = TC.Danger, strokeT = 0 },
}

function UIKit.KindButton(kind: string, props: { [string]: any }): TextButton
	local k = KINDS[kind] or KINDS.secondary
	local merged: { [string]: any } = {
		BackgroundColor3 = k.bg,
		BackgroundTransparency = k.bgT,
		TextColor3 = k.text,
		FontFace = Theme.Bold,
		TextSize = if UIKit.IsTouch() then 15 else 16,
		Size = UDim2.fromOffset(160, if UIKit.IsTouch() then 46 else 48),
	}
	for key, value in props do
		merged[key] = value
	end
	local button = UIKit.Button(merged)
	if k.stroke then
		UIKit.New("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = k.stroke,
			Transparency = k.strokeT or 0,
			Thickness = 1.5,
			Parent = button,
		})
	end
	return button
end

-- Grey out a kind button (it keeps its kind colours at 0.6 transparency and stops reacting).
function UIKit.SetDisabled(button: TextButton, disabled: boolean)
	button.AutoButtonColor = not disabled
	button.Active = not disabled
	button:SetAttribute("Disabled", disabled)
	button.TextTransparency = if disabled then 0.6 else 0
	button.BackgroundTransparency = if disabled then math.max(button.BackgroundTransparency, 0.6) else 0
end

-- A cross drawn from two bars (the ✕ glyph is missing from the game fonts).
local function cross(parent: GuiObject, size: number)
	for _, angle in { 45, -45 } do
		UIKit.New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(size, 2),
			Rotation = angle,
			BackgroundColor3 = TC.Cream,
			BorderSizePixel = 0,
			Parent = parent,
		})
	end
end

-- Open windows, newest last: Esc / B / the back button close the top one.
local openWindows: { Frame } = {}

-- The one window used everywhere (chest, workbench, classes, records, how to play, menu, story card).
--   local root, body, footer = UIKit.Window({ name, kicker = text, title = text, width = 560|720|880,
--       parent = ScreenGui?, noFooter = bool?, modal = bool? })
-- Show / hide with root.Visible (opening plays a short pop-in). The body is a ScrollingFrame that grows
-- with its content; the footer holds up to two buttons on the right (main button last).
function UIKit.Window(opts: { [string]: any }): (Frame, ScrollingFrame, Frame, { kicker: TextLabel, title: TextLabel })
	local touch = UIKit.IsTouch()
	local root = UIKit.New("Frame", {
		Name = opts.name or "Window",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 30,
		Parent = opts.parent or UIKit.FullScreen(),
	})
	local dim = UIKit.New("TextButton", {
		Name = "Dim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromHex("0A0908"),
		BackgroundTransparency = 0.45,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 30,
		Parent = root,
	})
	local width = opts.width or 560
	local panel = UIKit.New("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = if touch then UDim2.new(1, -24, 1, -20) else UDim2.new(0, width, 0.8, 0),
		BackgroundColor3 = TC.PanelSolid,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 31,
		Parent = root,
	}, { UIKit.Corner(10) })
	UIKit.New("UISizeConstraint", {
		MaxSize = Vector2.new(if touch then 760 else width, if touch then 2000 else 640),
		Parent = panel,
	})
	UIKit.New("UIStroke", { Color = TC.Cream, Transparency = 0.72, Thickness = 1, Parent = panel })
	local scale = UIKit.New("UIScale", { Scale = 1, Parent = panel })
	-- Amber seal in the top-left corner.
	UIKit.New("Frame", {
		Size = UDim2.fromOffset(72, 4),
		BackgroundColor3 = TC.Amber,
		BorderSizePixel = 0,
		ZIndex = 33,
		Parent = panel,
	})
	local headH = if touch then 56 else 76
	local kicker = UIKit.Label({
		Position = UDim2.fromOffset(16, if touch then 8 else 14),
		Size = UDim2.new(1, -80, 0, 16),
		Text = opts.kicker or "",
		FontFace = Theme.Heading,
		TextSize = 13,
		TextColor3 = TC.Amber,
		TextWrapped = false,
		ZIndex = 32,
		Parent = panel,
	})
	local title = UIKit.Label({
		Position = UDim2.fromOffset(16, if touch then 24 else 32),
		Size = UDim2.new(1, -80, 0, if touch then 28 else 34),
		Text = string.upper(opts.title or ""),
		FontFace = Theme.Display,
		TextSize = if touch then 24 else 28,
		TextColor3 = TC.Cream,
		TextWrapped = false,
		ZIndex = 32,
		Parent = panel,
	})
	UIKit.New("Frame", {
		Position = UDim2.fromOffset(0, headH),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = TC.Cream,
		BackgroundTransparency = 0.86,
		BorderSizePixel = 0,
		ZIndex = 32,
		Parent = panel,
	})
	local close = UIKit.Button({
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, (headH - 44) / 2),
		Size = UDim2.fromOffset(44, 44),
		Text = "",
		BackgroundColor3 = TC.Cream,
		BackgroundTransparency = 0.92,
		ZIndex = 33,
		Parent = panel,
	})
	UIKit.New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = TC.Cream,
		Transparency = 0.75,
		Parent = close,
	})
	cross(close, 18)
	for _, d in close:GetChildren() do
		if d:IsA("Frame") then
			d.ZIndex = 34
		end
	end
	local footH = if opts.noFooter then 0 else 66
	local body = UIKit.New("ScrollingFrame", {
		Name = "Body",
		Position = UDim2.fromOffset(0, headH + 1),
		Size = UDim2.new(1, 0, 1, -(headH + 1 + footH)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = TC.Cream,
		ScrollBarImageTransparency = 0.6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 32,
		Parent = panel,
	})
	UIKit.New("UIPadding", {
		PaddingTop = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 14),
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		Parent = body,
	})
	local footer = UIKit.New("Frame", {
		Name = "Footer",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, footH),
		BackgroundColor3 = Color3.fromHex("191714"),
		BorderSizePixel = 0,
		Visible = footH > 0,
		ZIndex = 32,
		Parent = panel,
	})
	UIKit.New("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = TC.Cream,
		BackgroundTransparency = 0.86,
		BorderSizePixel = 0,
		ZIndex = 33,
		Parent = footer,
	})
	UIKit.New("UIPadding", { PaddingRight = UDim.new(0, 16), PaddingLeft = UDim.new(0, 16), Parent = footer })
	UIKit.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = footer,
	})

	local function hide()
		root.Visible = false
	end
	close.Activated:Connect(hide)
	dim.Activated:Connect(function()
		if not opts.modal then
			hide()
		end
	end)
	root:GetPropertyChangedSignal("Visible"):Connect(function()
		local index = table.find(openWindows, root)
		if index then
			table.remove(openWindows, index)
		end
		if root.Visible then
			table.insert(openWindows, root)
			dim.BackgroundTransparency = 1
			scale.Scale = 0.96
			local info = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			game:GetService("TweenService"):Create(dim, info, { BackgroundTransparency = 0.45 }):Play()
			game:GetService("TweenService"):Create(scale, info, { Scale = 1 }):Play()
			playClick()
		end
	end)
	return root, body, footer, { kicker = kicker, title = title }
end

UserInputService.InputBegan:Connect(function(input)
	local key = input.KeyCode
	if key == Enum.KeyCode.Escape or key == Enum.KeyCode.ButtonB then
		local top = openWindows[#openWindows]
		if top then
			top.Visible = false
		end
	end
end)

-- Single ScreenGui shared by all controllers.
local screen: ScreenGui? = nil
function UIKit.Screen(): ScreenGui
	if screen then
		return screen
	end
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = UIKit.New("ScreenGui", {
		Name = "SkylineUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		Parent = playerGui,
	})
	-- Phones keep scale 1 with their own layout; PC and consoles scale with the screen height.
	local scale = UIKit.New("UIScale", { Parent = gui })
	local function updateScale()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		scale.Scale = if UIKit.IsTouch() then 1 else math.clamp(camera.ViewportSize.Y / 1080, 0.9, 1.25)
	end
	updateScale()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateScale)
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	end
	screen = gui
	return gui
end

-- A second layer that reaches into the Roblox top bar row (vitals on phones, the menu button).
local topScreen: ScreenGui? = nil
function UIKit.TopScreen(): ScreenGui
	if topScreen then
		return topScreen
	end
	local gui = UIKit.New("ScreenGui", {
		Name = "SkylineTop",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 2,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	topScreen = gui
	return gui
end

-- Full-screen effects (vignettes, the downed screen): no insets at all.
local fullScreen: ScreenGui? = nil
function UIKit.FullScreen(): ScreenGui
	if fullScreen then
		return fullScreen
	end
	local gui = UIKit.New("ScreenGui", {
		Name = "SkylineFull",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ScreenInsets = Enum.ScreenInsets.None,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 1,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	fullScreen = gui
	return gui
end

return UIKit
