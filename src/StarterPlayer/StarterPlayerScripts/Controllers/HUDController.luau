--!strict
-- HUD: the current goal and short messages, top centre. Health and hunger live in VitalsController.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local Theme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Theme"))

local ClientState = require(script.Parent.ClientState)
local IntroController = require(script.Parent.IntroController)
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

local function isDanger(kind: string?): boolean
	local rank = KIND_RANK[kind or "info"] or 1
	return rank >= 3
end

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

local function listToasts(): { Frame }
	local toasts = {}
	for _, child in toastHolder:GetChildren() do
		if child:IsA("Frame") then
			table.insert(toasts, child)
		end
	end
	table.sort(toasts, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	return toasts
end

-- Cap: desktop 1 soft + 1 danger; touch 1 total (incoming kind wins the slot).
local function enforceCap(incomingDanger: boolean)
	local softs: { Frame } = {}
	local dangers: { Frame } = {}
	for _, toast in listToasts() do
		if toast:GetAttribute("ToastDanger") == true then
			table.insert(dangers, toast)
		else
			table.insert(softs, toast)
		end
	end
	local function clearAll(list: { Frame })
		for _, toast in list do
			toast:Destroy()
		end
	end
	if touch then
		clearAll(if incomingDanger then softs else dangers)
		clearAll(if incomingDanger then dangers else softs)
		return
	end
	-- Make room for the new toast of this kind (at most one of each kind after insert).
	clearAll(if incomingDanger then dangers else softs)
	-- Trim the other kind to one if somehow stacked from older builds.
	local other = if incomingDanger then softs else dangers
	while #other > 1 do
		other[1]:Destroy()
		table.remove(other, 1)
	end
end

local function showToast(text: string, kind: string?)
	local danger = isDanger(kind)
	enforceCap(danger)
	toastCounter += 1
	local toast = UIKit.Panel({
		Size = UDim2.fromScale(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.08,
		LayoutOrder = toastCounter,
		Parent = toastHolder,
	})
	toast:SetAttribute("ToastDanger", danger)
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
	if IntroController.BlocksSoftToasts() and not isDanger(pending.kind) then
		return
	end
	lastToastAt = os.clock()
	showToast(pending.text, pending.kind)
end

-- Returns false if intro soft-silence dropped the toast (caller must not mark one-shots done).
-- force: Scrap≠Crowbar only — bypasses soft throttle and intro silence.
function HUDController.Toast(text: string, kind: string?, force: boolean?): boolean
	local rank = KIND_RANK[kind or "info"] or 1
	local danger = rank >= 3
	-- Spawn silence: intro card (and 2 s after) drops soft toasts; danger / force still land.
	if not danger and not force and IntroController.BlocksSoftToasts() then
		return false
	end
	if force then
		pendingToast = nil
		pendingToken += 1
		lastToastAt = os.clock()
		showToast(text, kind)
		return true
	end
	-- Danger always lands; soft tips wait so lines do not stack.
	if danger then
		pendingToast = nil
		pendingToken += 1
		lastToastAt = os.clock()
		showToast(text, kind)
		return true
	end
	local now = os.clock()
	local wait = GameConfig.ToastMinIntervalSeconds - (now - lastToastAt)
	if wait <= 0 then
		pendingToast = nil
		pendingToken += 1
		lastToastAt = now
		showToast(text, kind)
		return true
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
	return true
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
