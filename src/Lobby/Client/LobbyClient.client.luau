--!strict
-- Lobby client: translates world text, shows short messages from the lifts and a language switch.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
Shared:WaitForChild("Locale")
local Locale = require(Shared:WaitForChild("Locale"))
local Lang = require(script.Parent:WaitForChild("Lang"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))

local C = UIKit.Colors
local screen = UIKit.Screen()

-- World text ------------------------------------------------------------------------------------------
local function localize(label: Instance)
	if not label:IsA("TextLabel") then
		return
	end
	local key = label:GetAttribute("TextKey")
	if type(key) == "string" then
		label.Text = Lang.T(key)
	end
end

local function watch(label: Instance)
	if label:IsA("TextLabel") then
		localize(label)
		label:GetAttributeChangedSignal("TextKey"):Connect(function()
			localize(label)
		end)
	end
end

task.spawn(function()
	local world = workspace:WaitForChild("LobbyWorld", 60)
	if not world then
		return
	end
	for _, d in world:GetDescendants() do
		watch(d)
	end
	world.DescendantAdded:Connect(watch)
	Lang.Changed:Connect(function()
		for _, d in world:GetDescendants() do
			localize(d)
		end
	end)
end)

-- Messages ---------------------------------------------------------------------------------------------
local toastHolder = UIKit.New("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -40),
	Size = UDim2.fromOffset(460, 200),
	BackgroundTransparency = 1,
	Parent = screen,
})
UIKit.New("UIListLayout", {
	Padding = UDim.new(0, 6),
	VerticalAlignment = Enum.VerticalAlignment.Bottom,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = toastHolder,
})
local KIND_COLORS = { info = C.text, success = C.good, warning = C.warn, error = C.bad }
local order = 0

local function toast(text: string, kind: string?)
	order += 1
	local panel = UIKit.Panel({
		Size = UDim2.fromOffset(460, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
		Parent = toastHolder,
	})
	UIKit.Padding(10).Parent = panel
	local label = UIKit.Label({
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = text,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = KIND_COLORS[kind or "info"] or C.text,
		Parent = panel,
	})
	task.delay(4, function()
		local info = TweenInfo.new(0.4)
		TweenService:Create(panel, info, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(label, info, { TextTransparency = 1 }):Play()
		task.wait(0.45)
		panel:Destroy()
	end)
end

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local notify = remotes:WaitForChild("Notify") :: RemoteEvent
notify.OnClientEvent:Connect(function(message, kind)
	local text = Lang.Format(message)
	if text ~= "" then
		toast(text, if type(kind) == "string" then kind else nil)
	end
end)

-- Language switch ----------------------------------------------------------------------------------------
local languageButton = UIKit.Button({
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 8),
	Size = UDim2.fromOffset(52, 44),
	Text = string.upper(Lang.Get()),
	Parent = screen,
})
languageButton.Activated:Connect(function()
	local code = Lang.Cycle()
	Lang.Set(code)
	toast(Locale.LanguageNames[code], "info")
end)
Lang.Changed:Connect(function(code)
	languageButton.Text = string.upper(code)
end)
