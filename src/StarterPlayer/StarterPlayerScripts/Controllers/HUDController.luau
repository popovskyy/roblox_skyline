--!strict
-- HUD: the current goal and short messages, top centre. Health and hunger live in VitalsController.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))

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

-- Toast spacing: info/success at most once per ToastMinIntervalSeconds; warning/error always show.
local lastToastAt = -math.huge
local pendingToast: { text: string, kind: string? }? = nil
local pendingToken = 0

local KIND_RANK = {
	info = 1,
	success = 2,
	warning = 3,
	error = 4,
}

-- Goal, top centre: amber "GOAL", the task, live n/m. Plate grows with wrapped text so
-- long uk/ru/en lines never spill past the black backdrop (phone / tablet especially).
local function buildObjective(screen: ScreenGui)
	local maxTextW = if touch then 260 else 440
	local panel = UIKit.New("Frame", {
		Name = "Objective",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, if touch then 8 else 14),
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		Parent = screen,
	}, { UIKit.Corner(10) })
	UIKit.New("UISizeConstraint", {
		MaxSize = Vector2.new(if touch then 360 else 620, 120),
		Parent = panel,
	})
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
		TextSize = if touch then 14 else 16,
		TextColor3 = T.Amber,
		TextWrapped = false,
		LayoutOrder = 1,
		Parent = panel,
	})
	Lang.Changed:Connect(function()
		goal.Text = Lang.T("hud.goal")
	end)
	objectiveText = UIKit.Label({
		-- Fixed width + wrap + grow height: AutomaticSize.X with TextWrapped=false used to
		-- clamp via UISizeConstraint while glyphs still painted outside the plate.
		Size = UDim2.fromOffset(maxTextW, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = "",
		FontFace = Theme.Semi,
		TextSize = if touch then 15 else 18,
		TextColor3 = T.Cream,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 2,
		Parent = panel,
	})
	actsText = UIKit.Label({
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = "",
		FontFace = Theme.Display,
		TextSize = if touch then 16 else 18,
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

local function showToast(text: string, kind: string?)
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
		BackgroundTransparency = 0.08,
		LayoutOrder = toastCounter,
		Parent = toastHolder,
	})
	UIKit.New("UISizeConstraint", {
		MaxSize = Vector2.new(if touch then 340 else 420, 80),
		Parent = toast,
	})
	UIKit.Padding(8).Parent = toast
	local label = UIKit.Label({
		Size = UDim2.fromOffset(if touch then 300 else 380, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = text,
		TextSize = 16,
		TextWrapped = true,
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

local function flushPending()
	local pending = pendingToast
	if not pending then
		return
	end
	pendingToast = nil
	lastToastAt = os.clock()
	showToast(pending.text, pending.kind)
end

function HUDController.Toast(text: string, kind: string?)
	local rank = KIND_RANK[kind or "info"] or 1
	-- Danger always lands; soft tips wait so loot / tutorial lines do not stack.
	if rank >= 3 then
		pendingToast = nil
		pendingToken += 1
		lastToastAt = os.clock()
		showToast(text, kind)
		return
	end
	local now = os.clock()
	local wait = GameConfig.ToastMinIntervalSeconds - (now - lastToastAt)
	if wait <= 0 then
		pendingToast = nil
		pendingToken += 1
		lastToastAt = now
		showToast(text, kind)
		return
	end
	local existing = pendingToast
	local existingRank = if existing then (KIND_RANK[existing.kind or "info"] or 1) else 0
	if not existing or rank >= existingRank then
		pendingToast = { text = text, kind = kind }
	end
	pendingToken += 1
	local token = pendingToken
	task.delay(wait, function()
		if pendingToken == token then
			flushPending()
		end
	end)
end

local function onState(s: { [string]: any })
	if s.tutorial then
		objectiveText.Text = Lang.T(s.tutorial.text)
	end
	-- Live progress of a collecting goal ("2/4"); nothing for other goals.
	local t = s.tutorial
	if t and type(t.have) == "number" and type(t.need) == "number" then
		actsText.Text = ("%d/%d"):format(t.have, t.need)
		actsText.Visible = true
	else
		actsText.Visible = false
	end
end

function HUDController.Start()
	local screen = UIKit.Screen()
	buildObjective(screen)
	buildToasts(screen)
	ClientState.Changed:Connect(onState)
end

return HUDController
