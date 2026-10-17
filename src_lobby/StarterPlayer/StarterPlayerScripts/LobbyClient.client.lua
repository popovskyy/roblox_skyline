--!strict
-- Lobby client: lift size modal (1–6), toasts, language, countdown, teleport GUI, music.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
Shared:WaitForChild("Locale")
local Locale = require(Shared:WaitForChild("Locale"))
local MusicConfig = require(Shared:WaitForChild("MusicConfig"))
local PlacesConfig = require(Shared:WaitForChild("PlacesConfig"))
local Theme = require(Shared:WaitForChild("Theme"))
local Lang = require(script.Parent:WaitForChild("Lang"))
local UIKit = require(script.Parent:WaitForChild("UIKit"))

local C = UIKit.Colors
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Dedicated high-order ScreenGui so the modal is never buried under touch controls / other UI.
local screen = Instance.new("ScreenGui")
screen.Name = "SkylineLobbyUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.DisplayOrder = 80
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
-- Do not block the whole UI if a remote is late; bind when present.
local chooseLiftSize: RemoteEvent? = nil
local openLiftPick: RemoteEvent? = nil
task.spawn(function()
	chooseLiftSize = remotesFolder:WaitForChild("ChooseLiftSize", 30) :: RemoteEvent?
	openLiftPick = remotesFolder:WaitForChild("OpenLiftSizePick", 30) :: RemoteEvent?
end)

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
	Position = UDim2.new(0.5, 0, 0, 72),
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

task.spawn(function()
	local notify = remotesFolder:WaitForChild("Notify", 30) :: RemoteEvent?
	if not notify then
		return
	end
	notify.OnClientEvent:Connect(function(message, kind)
		local text = Lang.Format(message)
		if text ~= "" then
			toast(text, if type(kind) == "string" then kind else nil)
		end
	end)
end)

-- Party size modal (1–6). Opened AFTER physics entry into the cabin zone (attribute + remote).
-- Critical for mobile: NEVER cover the full screen with an Active GuiObject — that steals the
-- thumbstick/jump and makes it feel like you "cannot enter" the lift.
local dimmer = UIKit.New("Frame", {
	Name = "LiftPickDimmer",
	-- Soft vignette only behind the panel area (not the bottom touch controls).
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.42),
	Size = UDim2.fromOffset(420, 360),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.55,
	BorderSizePixel = 0,
	Visible = false,
	Active = false, -- must stay false so world touch movement keeps working
	ZIndex = 10,
	Parent = screen,
}, { UIKit.Corner(16) })

local pickPanel = UIKit.New("Frame", {
	Name = "LiftSizePick",
	AnchorPoint = Vector2.new(0.5, 0.5),
	-- Upper-mid so jump / thumbstick at the bottom stay free on phones.
	Position = UDim2.fromScale(0.5, 0.42),
	Size = UDim2.fromOffset(340, 280),
	BackgroundColor3 = Color3.fromRGB(28, 26, 24),
	BackgroundTransparency = 0.02,
	BorderSizePixel = 0,
	Visible = false,
	Active = true,
	ZIndex = 11,
	Parent = screen,
}, {
	UIKit.Corner(12),
	UIKit.New("UIStroke", {
		Color = C.accent,
		Thickness = 2,
		Transparency = 0.15,
	}),
})
UIKit.Padding(16).Parent = pickPanel

-- Scale panel for narrow phones without shrinking the whole lobby HUD.
local pickScale = Instance.new("UIScale")
pickScale.Parent = pickPanel
local function updatePickScale()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local w = cam.ViewportSize.X
	pickScale.Scale = if w < 420 then math.clamp(w / 380, 0.75, 1) else 1
end
updatePickScale()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updatePickScale)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updatePickScale)

local pickTitle = UIKit.Label({
	Size = UDim2.new(1, 0, 0, 36),
	TextXAlignment = Enum.TextXAlignment.Center,
	FontFace = Theme.Display,
	TextSize = 28,
	TextColor3 = C.accent,
	ZIndex = 12,
	Parent = pickPanel,
})
local pickBody = UIKit.Label({
	Position = UDim2.fromOffset(0, 40),
	Size = UDim2.new(1, 0, 0, 48),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextSize = 16,
	TextColor3 = C.muted,
	ZIndex = 12,
	Parent = pickPanel,
})

local pickGrid = UIKit.New("Frame", {
	Position = UDim2.fromOffset(0, 100),
	Size = UDim2.new(1, 0, 0, 140),
	BackgroundTransparency = 1,
	ZIndex = 12,
	Parent = pickPanel,
})
UIKit.New("UIGridLayout", {
	CellSize = UDim2.fromOffset(92, 56),
	CellPadding = UDim2.fromOffset(10, 10),
	FillDirectionMaxCells = 3,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = pickGrid,
})

local minSize = PlacesConfig.MinPartySize or 1
local maxSize = PlacesConfig.MaxPartySize or 6
local selectedSize: number? = nil

local function styleSizeButton(button: TextButton, size: number, selected: boolean)
	if selected then
		button.BackgroundColor3 = C.accent
		button.TextColor3 = Color3.fromRGB(20, 18, 16)
	else
		button.BackgroundColor3 = Color3.fromRGB(42, 40, 38)
		button.TextColor3 = C.text
	end
	if size == 1 then
		button.Text = Lang.T("lobby.pickSolo")
	else
		button.Text = tostring(size)
	end
end

local sizeButtons: { [number]: TextButton } = {}
for size = minSize, maxSize do
	local button = UIKit.Button({
		Text = if size == 1 then "Solo" else tostring(size),
		TextSize = if size == 1 then 18 else 24,
		FontFace = Theme.Bold,
		AutoButtonColor = true,
		LayoutOrder = size,
		ZIndex = 13,
		Parent = pickGrid,
	})
	styleSizeButton(button, size, false)
	button.Activated:Connect(function()
		selectedSize = size
		for s, b in sizeButtons do
			styleSizeButton(b, s, s == size)
		end
		local remote = chooseLiftSize or remotesFolder:FindFirstChild("ChooseLiftSize")
		if remote and remote:IsA("RemoteEvent") then
			remote:FireServer(size)
		end
	end)
	sizeButtons[size] = button
end

local function refreshPickCopy()
	pickTitle.Text = Lang.T("lobby.pickSizeTitle")
	pickBody.Text = Lang.T("lobby.pickSizeBody")
	for s, b in sizeButtons do
		styleSizeButton(b, s, selectedSize == s)
	end
end
refreshPickCopy()
Lang.Changed:Connect(refreshPickCopy)

local pickOpen = false
local function setPickVisible(visible: boolean)
	pickOpen = visible
	pickPanel.Visible = visible
	dimmer.Visible = visible
	if not visible then
		selectedSize = nil
		for s, b in sizeButtons do
			styleSizeButton(b, s, false)
		end
	end
end

local function updatePickDialog()
	local open = player:GetAttribute("LiftPickOpen") == true
	setPickVisible(open)
end
player:GetAttributeChangedSignal("LiftPickOpen"):Connect(updatePickDialog)
updatePickDialog()

task.spawn(function()
	local remote = remotesFolder:WaitForChild("OpenLiftSizePick", 30) :: RemoteEvent?
	if not remote then
		return
	end
	-- Never open from a late remote after walk-out — attributes are source of truth.
	remote.OnClientEvent:Connect(function()
		if player:GetAttribute("LiftPickOpen") == true then
			setPickVisible(true)
		end
	end)
end)

-- Language switch ----------------------------------------------------------------------------------------
local languageButton = UIKit.Button({
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 8),
	Size = UDim2.fromOffset(52, 44),
	Text = string.upper(Lang.Get()),
	ZIndex = 5,
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
-- Top-center: never cover mobile jump / thumbstick (nuance Top #2).
local liftPanel = UIKit.Panel({
	Name = "LiftCountdown",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 72),
	Size = UDim2.fromOffset(300, 96),
	Visible = false,
	Active = false,
	ZIndex = 5,
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
	-- Hide countdown while the pick modal is open so they don't fight.
	if pickOpen then
		liftPanel.Visible = false
		return
	end
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
	ZIndex = 5,
	Parent = screen,
})
musicButton.Activated:Connect(function()
	muted = not muted
	musicButton.Text = if muted then "✕♪" else "♪"
	if track then
		track.Volume = if muted then 0 else MusicConfig.Volume
	end
end)

-- Touch: dimmer tap does not close (must pick a size or walk out). Keeps modal sticky on mobile.
_ = UserInputService
