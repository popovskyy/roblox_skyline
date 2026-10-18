--!strict
-- Lobby client: translates world text, shows short messages from the lifts and a language switch.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
Shared:WaitForChild("Locale")
local MusicConfig = require(Shared:WaitForChild("MusicConfig"))
local PlacesConfig = require(Shared:WaitForChild("PlacesConfig"))
local RemoteNames = require(Shared:WaitForChild("RemoteNames"))
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
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	-- Above SkylineUI (lift card, toasts); below teleport overlay (100). Same band as UIKit.TopScreen.
	DisplayOrder = 2,
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

-- Buttons under the tokens: Records, How to play, Classes (docs/design/HUD_SPEC.md, section 8) ---------------
local touch = UIKit.IsTouch()
local BUTTON_HEIGHT = if touch then 44 else 40

local function usingGamepad(): boolean
	return string.sub(UserInputService:GetLastInputType().Name, 1, 7) == "Gamepad"
end

local buttonRow = UIKit.New("Frame", {
	Name = "LobbyButtons",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -8, 0, 54),
	Size = UDim2.fromOffset(0, BUTTON_HEIGHT),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundTransparency = 1,
	Parent = topScreen,
})
UIKit.New("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = buttonRow,
})

-- The gamepad button that opens a panel, drawn in the corner of its lobby button while a pad is in use.
local padBadges: { ImageLabel } = {}
local function updatePadBadges()
	local pad = usingGamepad()
	for _, badge in padBadges do
		badge.Visible = pad
	end
end
UserInputService.LastInputTypeChanged:Connect(updatePadBadges)

local function topButton(name: string, width: number, order: number, padKey: Enum.KeyCode?): TextButton
	local button = UIKit.Button({
		Name = name,
		Size = UDim2.fromOffset(width, BUTTON_HEIGHT),
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.35,
		TextColor3 = T.Cream,
		FontFace = Theme.Bold,
		TextSize = 16,
		LayoutOrder = order,
		Parent = buttonRow,
	})
	UIKit.New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = T.Amber,
		Transparency = 0.4,
		Parent = button,
	})
	if padKey then
		local image = ""
		pcall(function()
			image = UserInputService:GetImageForKeyCode(padKey)
		end)
		local badge = UIKit.New("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(1, -2, 1, -2),
			Size = UDim2.fromOffset(22, 22),
			BackgroundTransparency = 1,
			Image = image,
			Visible = usingGamepad(),
			Parent = button,
		})
		table.insert(padBadges, badge)
	end
	return button
end

-- Close button: a cross drawn with two Frames (the ✕ glyph is missing from the game fonts).

-- One panel at a time, over a dim backdrop; tapping the backdrop or B on a gamepad closes it.
local panels: { GuiObject } = {}
local dim = UIKit.New("TextButton", {
	Name = "Dim",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.45,
	Text = "",
	AutoButtonColor = false,
	Visible = false,
	ZIndex = 9,
	Parent = topScreen,
})

local function closePanels()
	for _, panel in panels do
		panel.Visible = false
	end
	dim.Visible = false
	GuiService.SelectedObject = nil
end
dim.Activated:Connect(closePanels)

local function anyPanelOpen(): boolean
	for _, panel in panels do
		if panel.Visible then
			return true
		end
	end
	return false
end

-- Opens the panel (closing any other); returns false when it was already open and is now closed.
local function togglePanel(panel: GuiObject): boolean
	if panel.Visible then
		closePanels()
		return false
	end
	closePanels()
	panel.Visible = true
	if usingGamepad() then
		GuiService.SelectedObject = panel:FindFirstChild("Close", true) :: GuiObject?
	end
	return true
end

-- A centred card with a title, a close button and a scrolling body.
local function sheet(name: string, titleKey: string, width: number?): (Frame, ScrollingFrame)
	-- The same window as in the tower (UIKit.Window): dim, seal, kicker + title, close, scrolling body.
	local root, body, _footer, refs = UIKit.Window({
		name = name,
		kicker = Lang.T("lobby.kicker"),
		title = Lang.T(titleKey),
		width = width or 560,
		noFooter = true,
		parent = topScreen,
	})
	Lang.Changed:Connect(function()
		refs.kicker.Text = Lang.T("lobby.kicker")
		refs.title.Text = string.upper(Lang.T(titleKey))
	end)
	UIKit.New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = body })
	table.insert(panels, root)
	return root, body
end

-- Classes ----------------------------------------------------------------------------------------------------
local Classes = require(Shared:WaitForChild("Classes"))
-- L1 / LB on a gamepad (X and Y already open Records and How to play; A/B/Select left alone).
local classesButton = topButton("ClassesButton", 120, 3, Enum.KeyCode.ButtonL1)

local classPanel, classList, _classFooter, classRefs = UIKit.Window({
	name = "Classes",
	kicker = Lang.T("class.kicker"),
	title = Lang.T("lobby.classes"),
	width = 880,
	noFooter = true,
	parent = topScreen,
})
table.insert(panels, classPanel)
local classTitle = classRefs.title
UIKit.New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = classList })

local function fire(name: string, ...: any)
	local remote = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then
		remote:FireServer(...)
	end
end

local function renderClasses()
	classTitle.Text = string.upper(Lang.T("lobby.classes"))
	classRefs.kicker.Text = Lang.T("class.kicker")
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

local function toggleClasses()
	if togglePanel(classPanel) then
		renderClasses()
	end
end
classesButton.Activated:Connect(toggleClasses)
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

-- Records: the "towers completed" board up close. The server sends its cached board on request.
local recordsButton = topButton("RecordsButton", 120, 1, Enum.KeyCode.ButtonX)
Lang.Bind(recordsButton, "lobby.records")
local recordsPanel, recordsList = sheet("Records", "lobby.recordsTitle")

type Record = { rank: number, userId: number, name: string, towers: number }
local records: { Record }? = nil

local function clearList(list: Instance)
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function listNote(list: Instance, text: string, order: number)
	UIKit.Label({
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = text,
		TextSize = 15,
		TextColor3 = T.Muted,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = order,
		ZIndex = 11,
		Parent = list,
	})
end

local function renderRecords()
	clearList(recordsList)
	local board = records
	if board == nil then
		listNote(recordsList, Lang.T("lobby.recordsLoading"), 1)
		return
	end
	if #board == 0 then
		listNote(recordsList, Lang.T("lobby.leadersEmpty"), 1)
	else
		local header = UIKit.New("Frame", {
			Size = UDim2.new(1, -8, 0, 20),
			BackgroundTransparency = 1,
			LayoutOrder = 0,
			ZIndex = 11,
			Parent = recordsList,
		})
		UIKit.Label({
			Size = UDim2.fromScale(1, 1),
			Text = Lang.T("lobby.leaders"),
			FontFace = Theme.Bold,
			TextSize = 14,
			TextColor3 = T.CreamDim,
			ZIndex = 11,
			Parent = header,
		})
		local me = Players.LocalPlayer.UserId
		for _, record in board do
			local mine = record.userId == me
			local row = UIKit.New("Frame", {
				Size = UDim2.new(1, -8, 0, 40),
				BackgroundColor3 = T.Panel,
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
				LayoutOrder = record.rank,
				ZIndex = 11,
				Parent = recordsList,
			}, { UIKit.Corner(8) })
			UIKit.New("UIPadding", {
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
				Parent = row,
			})
			if mine then
				UIKit.New("UIStroke", { Color = T.Amber, Thickness = 2, Parent = row })
			end
			UIKit.Label({
				Size = UDim2.new(0, 34, 1, 0),
				Text = tostring(record.rank),
				FontFace = Theme.Display,
				TextSize = 20,
				TextColor3 = if record.rank <= 3 then T.AmberText else T.CreamDim,
				ZIndex = 11,
				Parent = row,
			})
			UIKit.Label({
				Position = UDim2.fromOffset(40, 0),
				Size = UDim2.new(1, -110, 1, 0),
				Text = if mine then ("%s · %s"):format(record.name, Lang.T("lobby.recordsYou")) else record.name,
				TextSize = 17,
				TextColor3 = T.Cream,
				TextWrapped = false,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 11,
				Parent = row,
			})
			UIKit.Label({
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.new(0, 64, 1, 0),
				Text = tostring(record.towers),
				FontFace = Theme.Display,
				TextSize = 20,
				TextColor3 = T.Cream,
				TextXAlignment = Enum.TextXAlignment.Right,
				ZIndex = 11,
				Parent = row,
			})
		end
	end
	listNote(recordsList, Lang.T("lobby.recordsNote", PlacesConfig.LeaderboardRefreshSeconds), 1000)
end

-- Only well-formed rows from the server are drawn.
local function readRecords(data: any): { Record }
	local list: { Record } = {}
	if type(data) ~= "table" then
		return list
	end
	for _, entry in data do
		if
			type(entry) == "table"
			and type(entry.rank) == "number"
			and type(entry.userId) == "number"
			and type(entry.name) == "string"
			and type(entry.towers) == "number"
		then
			table.insert(list, { rank = entry.rank, userId = entry.userId, name = entry.name, towers = entry.towers })
		end
	end
	return list
end

local recordsRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(RemoteNames.ShowRecords)
if recordsRemote:IsA("RemoteEvent") then
	recordsRemote.OnClientEvent:Connect(function(data)
		records = readRecords(data)
		if recordsPanel.Visible then
			renderRecords()
		end
	end)
end

local function toggleRecords()
	if togglePanel(recordsPanel) then
		renderRecords()
		fire(RemoteNames.RequestRecords)
	end
end
recordsButton.Activated:Connect(toggleRecords)

-- How to play: the match loop in five steps, then tokens and classes.
local howButton = topButton("HowButton", BUTTON_HEIGHT, 2, Enum.KeyCode.ButtonY)
howButton.Text = "?"
howButton.FontFace = Theme.Display
howButton.TextSize = 22
local howPanel, howList = sheet("HowToPlay", "lobby.howTitle")

for step = 1, 5 do
	local row = UIKit.New("Frame", {
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = step,
		ZIndex = 11,
		Parent = howList,
	})
	local badge = UIKit.New("Frame", {
		Size = UDim2.fromOffset(30, 30),
		BackgroundColor3 = T.Amber,
		BorderSizePixel = 0,
		ZIndex = 11,
		Parent = row,
	}, { UIKit.Corner(15) })
	UIKit.Label({
		Size = UDim2.fromScale(1, 1),
		Text = tostring(step),
		FontFace = Theme.Display,
		TextSize = 18,
		TextColor3 = T.PanelSolid,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 12,
		Parent = badge,
	})
	local heading = UIKit.Label({
		Position = UDim2.fromOffset(42, 4),
		Size = UDim2.new(1, -42, 0, 22),
		FontFace = Theme.Bold,
		TextSize = 17,
		TextColor3 = T.Cream,
		ZIndex = 11,
		Parent = row,
	})
	Lang.Bind(heading, ("lobby.how%dTitle"):format(step))
	local line = UIKit.Label({
		Position = UDim2.fromOffset(42, 28),
		Size = UDim2.new(1, -42, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 15,
		TextColor3 = T.CreamDim,
		ZIndex = 11,
		Parent = row,
	})
	Lang.Bind(line, ("lobby.how%d"):format(step))
end

local tokensNote = UIKit.New("Frame", {
	Size = UDim2.new(1, -8, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = T.Panel,
	BackgroundTransparency = 0.2,
	BorderSizePixel = 0,
	LayoutOrder = 6,
	ZIndex = 11,
	Parent = howList,
}, { UIKit.Corner(10), UIKit.Padding(10) })
UIKit.New("UIStroke", { Color = T.Amber, Transparency = 0.4, Parent = tokensNote })
UIKit.New("Frame", {
	Position = UDim2.fromOffset(0, 2),
	Size = UDim2.fromOffset(18, 18),
	BackgroundColor3 = T.Amber,
	BorderSizePixel = 0,
	ZIndex = 11,
	Parent = tokensNote,
}, { UIKit.Corner(9) })
local tokensLine = UIKit.Label({
	Position = UDim2.fromOffset(28, 0),
	Size = UDim2.new(1, -28, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	TextSize = 15,
	TextColor3 = T.Cream,
	ZIndex = 11,
	Parent = tokensNote,
})
Lang.Bind(tokensLine, "lobby.howTokens")

local function toggleHow()
	togglePanel(howPanel)
end
howButton.Activated:Connect(toggleHow)

Lang.Changed:Connect(function()
	if recordsPanel.Visible then
		renderRecords()
	end
end)

-- Gamepad: X opens Records, Y opens How to play, L1 opens Classes, B closes whatever is open.
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not usingGamepad() then
		return
	end
	if input.KeyCode == Enum.KeyCode.ButtonX then
		toggleRecords()
	elseif input.KeyCode == Enum.KeyCode.ButtonY then
		toggleHow()
	elseif input.KeyCode == Enum.KeyCode.ButtonL1 then
		toggleClasses()
	elseif input.KeyCode == Enum.KeyCode.ButtonB and anyPanelOpen() then
		closePanels()
	end
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
local KIND_RANK = { info = 1, success = 2, warning = 3, error = 4 }
local order = 0

-- Concurrent cap only (design B0.5): 1 soft + 1 danger; touch = 1 total.
local function toast(text: string, kind: string?)
	local danger = (KIND_RANK[kind or "info"] or 1) >= 3
	local softs: { Frame } = {}
	local dangers: { Frame } = {}
	for _, child in toastHolder:GetChildren() do
		if child:IsA("Frame") then
			if child:GetAttribute("ToastDanger") == true then
				table.insert(dangers, child)
			else
				table.insert(softs, child)
			end
		end
	end
	local sameKind = if danger then dangers else softs
	for _, panel in sameKind do
		panel:Destroy()
	end
	if UIKit.IsTouch() then
		for _, panel in (if danger then softs else dangers) do
			panel:Destroy()
		end
	end
	order += 1
	local panel = UIKit.Panel({
		Size = UDim2.fromOffset(460, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
		Parent = toastHolder,
	})
	panel:SetAttribute("ToastDanger", danger)
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
	-- Fill with side margin, then cap to the HUD_SPEC width so narrow phones are not clipped.
	Size = UDim2.new(1, -20, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = T.PanelSolid,
	BackgroundTransparency = 0.1,
	BorderSizePixel = 0,
	Visible = false,
	Parent = screen,
}, { UIKit.Corner(12) })
UIKit.New("UISizeConstraint", {
	MaxSize = Vector2.new(if compact then 420 else 480, 10000),
	Parent = liftPanel,
})
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
