--!strict
-- Lobby client: translates world text, shows short messages from the lifts and a language switch.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
Shared:WaitForChild("Locale")
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

-- Lift boards carry LiftCount / LiftCapacity / LiftSolo attributes instead of text.
local function liftBoard(label: TextLabel)
	local count = label:GetAttribute("LiftCount")
	local capacity = label:GetAttribute("LiftCapacity")
	if type(count) ~= "number" or type(capacity) ~= "number" then
		return
	end
	label.Text = if label:GetAttribute("LiftSolo") == true
		then Lang.T("lobby.boardSolo")
		else Lang.T("lobby.boardGroup", count, capacity)
end

local function watch(label: Instance)
	if label:IsA("TextLabel") then
		liftBoard(label)
		label:GetAttributeChangedSignal("LiftCount"):Connect(function()
			liftBoard(label)
		end)
		label:GetAttributeChangedSignal("LiftCapacity"):Connect(function()
			liftBoard(label)
		end)
	end

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
			if d:IsA("TextLabel") then
				liftBoard(d)
			end
		end
	end)
end)

-- Tokens (top-right) -------------------------------------------------------------------------------------
local T = Theme.Colors
local topScreen = UIKit.New("ScreenGui", {
	Name = "LobbyTop",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
	Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
})
local tokenChip = UIKit.New("Frame", {
	Name = "Tokens",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -8, 0, 8),
	Size = UDim2.fromOffset(0, 40),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundColor3 = T.Panel,
	BackgroundTransparency = 0.35,
	BorderSizePixel = 0,
	Visible = false,
	Parent = topScreen,
}, { UIKit.Corner(10) })
UIKit.New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12), Parent = tokenChip })
UIKit.New("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = tokenChip,
})
UIKit.New("Frame", {
	Size = UDim2.fromOffset(18, 18),
	BackgroundColor3 = T.Amber,
	BorderSizePixel = 0,
	LayoutOrder = 1,
	Parent = tokenChip,
}, { UIKit.Corner(9) })
local tokenNumber = UIKit.Label({
	Size = UDim2.fromOffset(0, 24),
	AutomaticSize = Enum.AutomaticSize.X,
	FontFace = Theme.Display,
	TextSize = 19,
	TextColor3 = T.Cream,
	TextWrapped = false,
	LayoutOrder = 2,
	Parent = tokenChip,
})
local tokenWord = UIKit.Label({
	Size = UDim2.fromOffset(0, 20),
	AutomaticSize = Enum.AutomaticSize.X,
	TextSize = 13,
	TextColor3 = T.CreamDim,
	TextWrapped = false,
	LayoutOrder = 3,
	Parent = tokenChip,
})
local function updateTokens()
	local tokens = Players.LocalPlayer:GetAttribute("Tokens")
	tokenChip.Visible = type(tokens) == "number"
	if type(tokens) == "number" then
		tokenNumber.Text = tostring(tokens)
		tokenWord.Text = Lang.T("lobby.tokensWord")
	end
end
Players.LocalPlayer:GetAttributeChangedSignal("Tokens"):Connect(updateTokens)
Lang.Changed:Connect(updateTokens)
updateTokens()

-- Classes (top-right, next to the tokens) -----------------------------------------------------------------
local Classes = require(Shared:WaitForChild("Classes"))
local classesButton = UIKit.Button({
	Name = "ClassesButton",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -8, 0, 54),
	Size = UDim2.fromOffset(120, 40),
	BackgroundColor3 = T.Panel,
	BackgroundTransparency = 0.35,
	TextColor3 = T.Cream,
	FontFace = Theme.Bold,
	TextSize = 16,
	Parent = topScreen,
})
UIKit.New("UIStroke", {
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	Color = T.Amber,
	Transparency = 0.4,
	Parent = classesButton,
})

local classPanel = UIKit.New("Frame", {
	Name = "Classes",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0, 560, 0.9, 0),
	BackgroundColor3 = T.PanelSolid,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 10,
	Parent = topScreen,
}, { UIKit.Corner(12) })
UIKit.New("UISizeConstraint", { MaxSize = Vector2.new(560, 470), Parent = classPanel })
UIKit.Padding(14).Parent = classPanel
local classTitle = UIKit.Label({
	Size = UDim2.new(1, -50, 0, 30),
	FontFace = Theme.Display,
	TextSize = 24,
	TextColor3 = T.Cream,
	ZIndex = 11,
	Parent = classPanel,
})
local closeClasses = UIKit.Button({
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.fromScale(1, 0),
	Size = UDim2.fromOffset(40, 36),
	Text = "X",
	ZIndex = 11,
	Parent = classPanel,
})
closeClasses.Activated:Connect(function()
	classPanel.Visible = false
end)
local classList = UIKit.New("ScrollingFrame", {
	Position = UDim2.fromOffset(0, 42),
	Size = UDim2.new(1, 0, 1, -42),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	ZIndex = 11,
	Parent = classPanel,
})
UIKit.New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = classList })

local function fire(name: string, ...: any)
	local remote = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then
		remote:FireServer(...)
	end
end

local function renderClasses()
	classTitle.Text = Lang.T("lobby.classes")
	classesButton.Text = Lang.T("lobby.classes")
	for _, child in classList:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local me = Players.LocalPlayer
	local tokens = me:GetAttribute("Tokens")
	local ownedText = me:GetAttribute("ClassesOwned")
	local selected = me:GetAttribute("ClassSelected")
	local owned: { [string]: boolean } = {}
	if type(ownedText) == "string" then
		for id in string.gmatch(ownedText, "[^,]+") do
			owned[id] = true
		end
	end
	local entries: { string } = { "none" }
	for _, id in Classes.Order do
		table.insert(entries, id)
	end
	for order, id in entries do
		local def = Classes.Get(id)
		local isPicked = (id == "none" and (selected == nil or selected == "")) or id == selected
		local row = UIKit.New("Frame", {
			Size = UDim2.new(1, -8, 0, 64),
			BackgroundColor3 = T.Panel,
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			LayoutOrder = order,
			ZIndex = 11,
			Parent = classList,
		}, { UIKit.Corner(10), UIKit.Padding(10) })
		if isPicked then
			UIKit.New("UIStroke", { Color = T.Amber, Thickness = 2, Parent = row })
		end
		UIKit.Label({
			Size = UDim2.new(1, -150, 0, 22),
			Text = Lang.T("class." .. id .. ".name"),
			FontFace = Theme.Display,
			TextSize = 20,
			TextColor3 = T.Cream,
			ZIndex = 11,
			Parent = row,
		})
		if def then
			UIKit.Label({
				Position = UDim2.fromOffset(0, 24),
				Size = UDim2.new(1, -150, 0, 20),
				Text = Lang.T("class." .. id .. ".desc"),
				TextSize = 14,
				TextColor3 = T.CreamDim,
				ZIndex = 11,
				Parent = row,
			})
		end
		local unlocked = id == "none" or owned[id] == true
		local action = UIKit.Button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromOffset(136, 40),
			FontFace = Theme.Bold,
			TextSize = 15,
			BackgroundColor3 = if isPicked then T.Amber elseif unlocked then T.Cream else T.PanelSolid,
			TextColor3 = if isPicked or unlocked then T.PanelSolid else T.AmberText,
			Text = if isPicked
				then Lang.T("lobby.classPicked")
				elseif unlocked then Lang.T("lobby.classPick")
				else Lang.T("lobby.classBuy", def and def.price or 0),
			ZIndex = 11,
			Parent = row,
		})
		if not unlocked and def and type(tokens) == "number" and tokens < def.price then
			action.TextColor3 = T.Muted
		end
		action.Activated:Connect(function()
			if isPicked then
				return
			elseif unlocked then
				fire("SelectClass", if id == "none" then nil else id)
			else
				fire("BuyClass", id)
			end
		end)
	end
end

classesButton.Activated:Connect(function()
	classPanel.Visible = not classPanel.Visible
	if classPanel.Visible then
		renderClasses()
	end
end)
for _, attribute in { "Tokens", "ClassesOwned", "ClassSelected" } do
	Players.LocalPlayer:GetAttributeChangedSignal(attribute):Connect(function()
		classesButton.Text = Lang.T("lobby.classes")
		if classPanel.Visible then
			renderClasses()
		end
	end)
end
Lang.Changed:Connect(function()
	classesButton.Text = Lang.T("lobby.classes")
	if classPanel.Visible then
		renderClasses()
	end
end)
classesButton.Text = Lang.T("lobby.classes")

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

-- Lift countdown ------------------------------------------------------------------------------------------
-- The server sets LiftSeconds / LiftCount / LiftCapacity on riders; show them big at the bottom of the screen.
local player = Players.LocalPlayer
local compact = UIKit.IsTouch()
local liftPanel = UIKit.New("Frame", {
	Name = "LiftCard",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -10),
	Size = UDim2.fromOffset(if compact then 420 else 480, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = T.PanelSolid,
	BackgroundTransparency = 0.1,
	BorderSizePixel = 0,
	Visible = false,
	Parent = screen,
}, { UIKit.Corner(12) })
UIKit.Padding(14).Parent = liftPanel
UIKit.New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = liftPanel })
local headRow = UIKit.New("Frame", {
	Size = UDim2.new(1, 0, 0, 32),
	BackgroundTransparency = 1,
	LayoutOrder = 1,
	Parent = liftPanel,
})
local liftName = UIKit.Label({
	Size = UDim2.fromScale(0.7, 1),
	FontFace = Theme.Display,
	TextSize = 22,
	TextColor3 = T.Cream,
	Parent = headRow,
})
local liftSeconds = UIKit.Label({
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.fromScale(1, 0),
	Size = UDim2.fromScale(0.3, 1),
	TextXAlignment = Enum.TextXAlignment.Right,
	FontFace = Theme.Display,
	TextSize = 26,
	TextColor3 = T.AmberText,
	Parent = headRow,
})
local progress = UIKit.New("Frame", {
	Size = UDim2.new(1, 0, 0, 6),
	BackgroundColor3 = T.Cream,
	BackgroundTransparency = 0.84,
	BorderSizePixel = 0,
	LayoutOrder = 2,
	Parent = liftPanel,
}, { UIKit.Corner(3) })
local progressFill = UIKit.New("Frame", {
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = T.Amber,
	BorderSizePixel = 0,
	Parent = progress,
}, { UIKit.Corner(3) })
local riders = UIKit.New("Frame", {
	Size = UDim2.new(1, 0, 0, 30),
	BackgroundTransparency = 1,
	LayoutOrder = 3,
	Parent = liftPanel,
})
UIKit.New("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 8),
	Parent = riders,
})
-- Party size: the leader of a group lift picks 2..6. Not a modal: walking and boarding never wait on it.
local PlacesConfig = require(Shared:WaitForChild("PlacesConfig"))
local sizeTitle = UIKit.Label({
	Size = UDim2.new(1, 0, 0, 20),
	FontFace = Theme.Bold,
	TextSize = 15,
	TextColor3 = T.CreamDim,
	LayoutOrder = 3,
	Visible = false,
	Parent = liftPanel,
})
local sizeRow = UIKit.New("Frame", {
	Size = UDim2.new(1, 0, 0, 44),
	BackgroundTransparency = 1,
	LayoutOrder = 3,
	Visible = false,
	Parent = liftPanel,
})
UIKit.New("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 8),
	Parent = sizeRow,
})
local sizeButtons: { [number]: TextButton } = {}
for _, size in PlacesConfig.PartySizes do
	local button = UIKit.Button({
		Size = UDim2.fromOffset(56, 44),
		Text = tostring(size),
		FontFace = Theme.Display,
		TextSize = 22,
		BackgroundColor3 = T.PanelSolid,
		TextColor3 = T.Cream,
		Parent = sizeRow,
	})
	UIKit.New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = T.Stroke,
		Transparency = 0.65,
		Parent = button,
	})
	button.Activated:Connect(function()
		local remote = remotes:FindFirstChild("SetLiftSize")
		if remote and remote:IsA("RemoteEvent") then
			remote:FireServer(size)
		end
	end)
	sizeButtons[size] = button
end

local leaveButton = UIKit.Button({
	Size = UDim2.new(1, 0, 0, 44),
	BackgroundColor3 = T.PanelSolid,
	TextColor3 = T.Cream,
	FontFace = Theme.Bold,
	TextSize = 16,
	LayoutOrder = 4,
	Parent = liftPanel,
})
UIKit.New("UIStroke", {
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	Color = T.Stroke,
	Transparency = 0.65,
	Parent = leaveButton,
})
leaveButton.Activated:Connect(function()
	local leave = remotes:FindFirstChild("LeaveLift")
	if leave and leave:IsA("RemoteEvent") then
		leave:FireServer()
	end
end)
local fullNote = UIKit.Label({
	Size = UDim2.new(1, 0, 0, 18),
	TextSize = 13,
	TextColor3 = T.Muted,
	TextXAlignment = Enum.TextXAlignment.Center,
	LayoutOrder = 5,
	Parent = liftPanel,
})

local function updateLift()
	local seconds = player:GetAttribute("LiftSeconds")
	local count = player:GetAttribute("LiftCount")
	local capacity = player:GetAttribute("LiftCapacity")
	local total = player:GetAttribute("LiftTotal")
	if type(seconds) ~= "number" or type(count) ~= "number" or type(capacity) ~= "number" then
		liftPanel.Visible = false
		return
	end
	liftPanel.Visible = true
	liftName.Text = Lang.T("lobby.lift", capacity)
	liftSeconds.Text = if seconds > 0 then ("0:%02d"):format(seconds) else Lang.T("lobby.starting")
	local full = if type(total) == "number" and total > 0 then total else math.max(seconds, 1)
	progressFill.Size = UDim2.fromScale(math.clamp(1 - seconds / full, 0, 1), 1)
	for _, child in riders:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for i = 1, capacity do
		local filled = i <= count
		local dot = UIKit.New("Frame", {
			Size = UDim2.fromOffset(30, 30),
			BackgroundColor3 = T.Amber,
			BackgroundTransparency = if filled then 0 else 1,
			BorderSizePixel = 0,
			Parent = riders,
		}, { UIKit.Corner(15) })
		if not filled then
			UIKit.New("UIStroke", { Color = T.CreamDim, Transparency = 0.4, Thickness = 1.5, Parent = dot })
		end
	end
	-- Size picker for the leader of a group lift; the chosen size is highlighted.
	local canChoose = player:GetAttribute("LiftCanChoose") == true and seconds > 0
	sizeTitle.Visible = canChoose
	sizeRow.Visible = canChoose
	sizeTitle.Text = Lang.T("lobby.pickSize")
	for size, button in sizeButtons do
		local chosen = size == capacity
		local allowed = size >= count
		button.BackgroundColor3 = if chosen then T.Amber else T.PanelSolid
		button.TextColor3 = if chosen then T.PanelSolid elseif allowed then T.Cream else T.Muted
		button.AutoButtonColor = allowed
	end
	leaveButton.Text = Lang.T("lobby.leaveLift")
	leaveButton.Visible = seconds > 0
	fullNote.Text = Lang.T("lobby.fullFaster")
	fullNote.Visible = count >= capacity and capacity > 1
end
for _, name in { "LiftSeconds", "LiftCount", "LiftCapacity", "LiftTotal", "LiftCanChoose" } do
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
local index = math.random(1, #MusicConfig.Roof)

local function playNext()
	index = index % #MusicConfig.Roof + 1
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. tostring(MusicConfig.Roof[index])
	sound.Volume = MusicConfig.Volume
	sound.SoundGroup = musicGroup
	sound.Parent = SoundService
	sound.Ended:Once(function()
		sound:Destroy()
		playNext()
	end)
	sound:Play()
end
playNext()
