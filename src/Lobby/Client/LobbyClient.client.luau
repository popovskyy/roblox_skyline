--!strict
-- Lobby client: translates world text, shows short messages from the lifts and a language switch.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
Shared:WaitForChild("Locale")
local Locale = require(Shared:WaitForChild("Locale"))
local MusicConfig = require(Shared:WaitForChild("MusicConfig"))
local Theme = require(Shared:WaitForChild("Theme"))
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
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 64),
	Size = UDim2.fromOffset(460, 200),
	BackgroundTransparency = 1,
	Parent = screen,
})
UIKit.New("UIListLayout", {
	Padding = UDim.new(0, 6),
	VerticalAlignment = Enum.VerticalAlignment.Top,
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

-- Lift countdown ------------------------------------------------------------------------------------------
-- The server sets LiftSeconds / LiftCount / LiftCapacity on riders; show them big at the bottom of the screen.
local player = Players.LocalPlayer
local liftPanel = UIKit.Panel({
	Name = "LiftCountdown",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -24),
	Size = UDim2.fromOffset(300, 96),
	Visible = false,
	Parent = screen,
})
local liftSeconds = UIKit.Label({
	Size = UDim2.new(1, 0, 0, 60),
	TextXAlignment = Enum.TextXAlignment.Center,
	FontFace = Theme.Display,
	TextSize = 44,
	TextColor3 = C.accent,
	Parent = liftPanel,
})
local liftRiders = UIKit.Label({
	Position = UDim2.fromOffset(0, 60),
	Size = UDim2.new(1, 0, 0, 28),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextSize = 16,
	TextColor3 = C.muted,
	Parent = liftPanel,
})

local function updateLift()
	local seconds = player:GetAttribute("LiftSeconds")
	local count = player:GetAttribute("LiftCount")
	local capacity = player:GetAttribute("LiftCapacity")
	if type(seconds) ~= "number" or type(count) ~= "number" or type(capacity) ~= "number" then
		liftPanel.Visible = false
		return
	end
	liftPanel.Visible = true
	liftSeconds.Text = if seconds > 0 then Lang.T("lobby.countdown", seconds) else Lang.T("lobby.starting")
	liftRiders.Text = Lang.T("lobby.riders", count, capacity)
end
for _, name in { "LiftSeconds", "LiftCount", "LiftCapacity" } do
	player:GetAttributeChangedSignal(name):Connect(updateLift)
end
Lang.Changed:Connect(updateLift)
updateLift()

-- Teleport screen ------------------------------------------------------------------------------------------
-- Replaces Roblox's default loading screen, which shows the raw place name.
local teleportGui = Instance.new("ScreenGui")
teleportGui.Name = "SkylineTeleport"
teleportGui.IgnoreGuiInset = true
teleportGui.DisplayOrder = 100
local backdrop = UIKit.New("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(18, 16, 14),
	BorderSizePixel = 0,
	Parent = teleportGui,
})
UIKit.Label({
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.45),
	Size = UDim2.new(0.8, 0, 0, 80),
	Text = "SKYLINE ZERO",
	TextXAlignment = Enum.TextXAlignment.Center,
	FontFace = Theme.Display,
	TextSize = 64,
	TextColor3 = C.accent,
	Parent = backdrop,
})
local teleportHint = UIKit.Label({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0.45, 50),
	Size = UDim2.new(0.8, 0, 0, 30),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextSize = 20,
	TextColor3 = C.muted,
	Parent = backdrop,
})
local function updateTeleportText()
	teleportHint.Text = Lang.T("lobby.teleporting")
end
updateTeleportText()
Lang.Changed:Connect(updateTeleportText)
TeleportService:SetTeleportGui(teleportGui)

-- Music ---------------------------------------------------------------------------------------------------
local musicGroup = Instance.new("SoundGroup")
musicGroup.Name = "Music"
musicGroup.Parent = SoundService
local muted = false
local track: Sound? = nil
local index = math.random(1, #MusicConfig.Roof)

local function playNext()
	index = index % #MusicConfig.Roof + 1
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. tostring(MusicConfig.Roof[index])
	sound.Volume = if muted then 0 else MusicConfig.Volume
	sound.SoundGroup = musicGroup
	sound.Parent = SoundService
	sound.Ended:Once(function()
		sound:Destroy()
		playNext()
	end)
	sound:Play()
	track = sound
end
playNext()

local musicButton = UIKit.Button({
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -72, 0, 8),
	Size = UDim2.fromOffset(44, 44),
	Text = "♪",
	TextSize = 22,
	Parent = screen,
})
musicButton.Activated:Connect(function()
	muted = not muted
	musicButton.Text = if muted then "✕♪" else "♪"
	if track then
		track.Volume = if muted then 0 else MusicConfig.Volume
	end
end)
