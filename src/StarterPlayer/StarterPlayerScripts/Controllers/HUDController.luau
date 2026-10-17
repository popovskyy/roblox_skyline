--!strict
-- HUD: the current goal and short messages, top centre. Health and hunger live in VitalsController.

local Theme = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Theme"))
local TweenService = game:GetService("TweenService")

local ClientState = require(script.Parent.ClientState)
local Lang = require(script.Parent.Lang)
local UIKit = require(script.Parent.UIKit)

local HUDController = {}

local C = UIKit.Colors
local T = Theme.Colors

local objectiveText: TextLabel
local actsText: TextLabel
local toastHolder: Frame

local touch = UIKit.IsTouch()

-- Goal, top centre: amber "GOAL", the task, systems restored.
local function buildObjective(screen: ScreenGui)
	local panel = UIKit.New("Frame", {
		Name = "Objective",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, if touch then 8 else 14),
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Parent = screen,
	}, { UIKit.Corner(10) })
	UIKit.New("UIPadding", {
		PaddingTop = UDim.new(0, if touch then 6 else 10),
		PaddingBottom = UDim.new(0, if touch then 6 else 10),
		PaddingLeft = UDim.new(0, if touch then 12 else 20),
		PaddingRight = UDim.new(0, if touch then 12 else 20),
		Parent = panel,
	})
	UIKit.New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = panel,
	})
	local goal = UIKit.Label({
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = Lang.T("hud.goal"),
		FontFace = Theme.Display,
		TextSize = 16,
		TextColor3 = T.Amber,
		TextWrapped = false,
		LayoutOrder = 1,
		Parent = panel,
	})
	Lang.Changed:Connect(function()
		goal.Text = Lang.T("hud.goal")
	end)
	objectiveText = UIKit.Label({
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.XY,
		Text = "",
		FontFace = Theme.Semi,
		TextSize = if touch then 16 else 20,
		TextColor3 = T.Cream,
		TextWrapped = false,
		LayoutOrder = 2,
		Parent = panel,
	})
	UIKit.New("UISizeConstraint", { MaxSize = Vector2.new(if touch then 340 else 560, 60), Parent = objectiveText })
	actsText = UIKit.Label({
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = "",
		FontFace = Theme.Display,
		TextSize = 18,
		TextColor3 = T.AmberText,
		TextWrapped = false,
		LayoutOrder = 3,
		Parent = panel,
	})
end

local function buildToasts(screen: ScreenGui)
	toastHolder = UIKit.New("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, if touch then 46 else 70),
		Size = UDim2.fromOffset(if touch then 340 else 420, 200),
		BackgroundTransparency = 1,
		Parent = screen,
	})
	UIKit.New("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
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
	if #toasts >= (if touch then 2 else 3) then
		table.sort(toasts, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		toasts[1]:Destroy()
	end
	local toast = UIKit.Panel({
		Size = UDim2.fromScale(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.25,
		LayoutOrder = toastCounter,
		Parent = toastHolder,
	})
	UIKit.Padding(8).Parent = toast
	local label = UIKit.Label({
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		Text = text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = KIND_COLORS[kind or "info"] or C.text,
		Parent = toast,
	})
	task.delay(if touch then 2.5 else 3.5, function()
		if toast.Parent then
			local info = TweenInfo.new(0.4)
			TweenService:Create(toast, info, { BackgroundTransparency = 1 }):Play()
			TweenService:Create(label, info, { TextTransparency = 1 }):Play()
			task.wait(0.45)
			toast:Destroy()
		end
	end)
end

local function onState(s: { [string]: any })
	if s.tutorial then
		objectiveText.Text = Lang.T(s.tutorial.text)
	end
	actsText.Text = ("%d/3"):format(s.acts or 0)
end

function HUDController.Start()
	local screen = UIKit.Screen()
	buildObjective(screen)
	buildToasts(screen)
	ClientState.Changed:Connect(onState)
end

return HUDController
