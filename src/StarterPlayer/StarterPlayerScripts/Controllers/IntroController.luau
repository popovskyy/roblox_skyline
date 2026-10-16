--!strict
-- Story screen shown once per match, right after the lift brings the player up to the roof:
-- what happened, what to do, how to win. Closed with the START button (or A / Enter).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(ReplicatedStorage.Shared.Theme)
local Lang = require(script.Parent.Lang)
local UIKit = require(script.Parent.UIKit)

local IntroController = {}

local C = UIKit.Colors
local GOALS = {
	{ icon = "🔩", key = "intro.goal1" },
	{ icon = "📦", key = "intro.goal2" },
	{ icon = "⚡", key = "intro.goal3" },
	{ icon = "🌉", key = "intro.goal4" },
	{ icon = "🩹", key = "intro.goal5" },
}

local overlay: Frame
-- Phones in landscape are short: tighter type so the whole card fits without scrolling.
local COMPACT = UserInputService.TouchEnabled
local function size(normal: number, compact: number): number
	return if COMPACT then compact else normal
end

local function close()
	if not overlay.Visible then
		return
	end
	local info = TweenInfo.new(0.35)
	TweenService:Create(overlay, info, { BackgroundTransparency = 1 }):Play()
	task.delay(0.35, function()
		overlay.Visible = false
	end)
end

local function build(screen: ScreenGui)
	overlay = UIKit.New("Frame", {
		Name = "Intro",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(10, 10, 8),
		BackgroundTransparency = 0.25,
		ZIndex = 20,
		Parent = screen,
	})
	local card = UIKit.Panel({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(620, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(26, 26, 22),
		BackgroundTransparency = 0.02,
		ZIndex = 21,
		Parent = overlay,
	})
	UIKit.New("UISizeConstraint", { MaxSize = Vector2.new(620, 900), Parent = card })
	UIKit.New("UIStroke", { Color = C.accent, Thickness = 2, Transparency = 0.4, Parent = card })
	UIKit.Padding(size(22, 12)).Parent = card
	UIKit.New("UIListLayout", {
		Padding = UDim.new(0, size(10, 5)),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = card,
	})

	local function label(
		order: number,
		key: string,
		textSize: number,
		font: Font,
		color: Color3,
		center: boolean
	): TextLabel
		local l = UIKit.Label({
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextSize = textSize,
			FontFace = font,
			TextColor3 = color,
			TextXAlignment = if center then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left,
			LayoutOrder = order,
			ZIndex = 22,
			Parent = card,
		})
		Lang.Bind(l, key)
		return l
	end
	label(1, "intro.kicker", size(16, 13), Theme.Heading, C.muted, true)
	label(2, "intro.title", size(52, 34), Theme.Display, C.accent, true)
	label(3, "intro.body", size(17, 14), Theme.Body, C.text, false)

	local goals = UIKit.New("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 4,
		ZIndex = 22,
		Parent = card,
	})
	UIKit.New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = goals })
	for i, goal in GOALS do
		local row = UIKit.New("Frame", {
			Size = UDim2.new(1, 0, 0, size(30, 22)),
			BackgroundTransparency = 1,
			LayoutOrder = i,
			ZIndex = 22,
			Parent = goals,
		})
		UIKit.Label({
			Size = UDim2.fromOffset(34, 30),
			Text = goal.icon,
			TextSize = 22,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 22,
			Parent = row,
		})
		local text = UIKit.Label({
			Position = UDim2.fromOffset(42, 0),
			Size = UDim2.new(1, -42, 1, 0),
			TextSize = size(16, 13),
			FontFace = Theme.Bold,
			ZIndex = 22,
			Parent = row,
		})
		Lang.Bind(text, goal.key)
	end

	local start = UIKit.Button({
		Size = UDim2.fromOffset(240, size(56, 42)),
		FontFace = Theme.Display,
		TextSize = size(26, 20),
		BackgroundColor3 = Color3.fromRGB(196, 140, 40),
		TextColor3 = Color3.fromRGB(20, 18, 14),
		LayoutOrder = 5,
		ZIndex = 22,
		Parent = card,
	})
	Lang.Bind(start, "intro.start")
	start.Activated:Connect(close)
end

function IntroController.Start()
	build(UIKit.Screen())
	-- One showing per match: the ScreenGui survives respawns, so it is not shown again after being closed.
	overlay.Visible = true
	UserInputService.InputBegan:Connect(function(input)
		local key = input.KeyCode
		if overlay.Visible and (key == Enum.KeyCode.ButtonA or key == Enum.KeyCode.Return) then
			close()
		end
	end)
end

return IntroController
