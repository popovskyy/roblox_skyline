--!strict
-- Client side of combat: what the held item does on a tap / click / R2 (Tool.Activated), the hold and
-- swing animations, the "you are down" screen, revive prompts and the workbench window.
-- Every decision (hits, damage, revives, crafting) is made by the server.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local Locale = require(ReplicatedStorage.Shared.Locale)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ClientState = require(script.Parent.ClientState)
local Lang = require(script.Parent.Lang)
local UIKit = require(script.Parent.UIKit)

local CombatController = {}

-- Set by ClientMain: shows a short message on screen.
CombatController.Hint = function(_text: string) end

local player = Players.LocalPlayer
local C = UIKit.Colors
local remotes: Folder

local function remote(name: string): RemoteEvent
	return remotes:FindFirstChild(name) :: RemoteEvent
end

-- Uploaded with scripts/build_animations.py.
local ANIMATIONS = {
	WeaponHold = "rbxassetid://85303283403730",
	WeaponSwing = "rbxassetid://106693888316440",
	ItemHold = "rbxassetid://113741024764678",
	ItemUse = "rbxassetid://73366190002807",
	Punch = "rbxassetid://129369444994134",
}

local tracks: { [string]: AnimationTrack } = {}

local function loadTracks(character: Model)
	table.clear(tracks)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end
	local animator = humanoid:WaitForChild("Animator", 10)
	if not animator or not animator:IsA("Animator") then
		return
	end
	for name, id in ANIMATIONS do
		local animation = Instance.new("Animation")
		animation.AnimationId = id
		local ok, track = pcall(function()
			return animator:LoadAnimation(animation)
		end)
		if ok and track then
			tracks[name] = track
		end
	end
end

local function play(name: string, fade: number?)
	local track = tracks[name]
	if track then
		track:Play(fade or 0.1)
	end
end

local function stop(name: string)
	local track = tracks[name]
	if track and track.IsPlaying then
		track:Stop(0.2)
	end
end

local lastSwing = 0

-- A tap on the world, a mouse click or R2 with the item in hand.
local function activate(tool: Tool)
	if player:GetAttribute("Downed") then
		return
	end
	local def = ItemDefinitions.Get(tool:GetAttribute("ItemId") or "")
	if not def then
		return
	end
	if def.weapon then
		local now = os.clock()
		if now - lastSwing < def.weapon.cooldown then
			return
		end
		lastSwing = now
		play("WeaponSwing", 0.05)
		remote(RemoteNames.Attack):FireServer()
	elseif def.use == "eat" or def.use == "heal" then
		play("ItemUse")
		remote(RemoteNames.UseItem):FireServer(def.id)
	elseif def.use == "light" then
		remote(RemoteNames.ToggleFlashlight):FireServer()
	end
end

-- Our own hotbar replaces the Roblox backpack bar.
local function hideDefaultBackpack()
	for _ = 1, 20 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
			-- No "Reset character": it would get a downed player up for free.
			StarterGui:SetCore("ResetButtonCallback", false)
		end)
		if ok then
			return
		end
		task.wait(0.5)
	end
end

-- Bare hands: the same tap / click / R2 throws a punch when nothing is held.
local function punch()
	local character = player.Character
	if not character or character:FindFirstChild("Held") or player:GetAttribute("Downed") then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	local now = os.clock()
	if now - lastSwing < GameConfig.Fists.cooldown then
		return
	end
	lastSwing = now
	play("Punch", 0.05)
	remote(RemoteNames.Attack):FireServer()
end

local function watchTool(character: Model)
	loadTracks(character)
	local function hook(child: Instance)
		if child:IsA("Tool") and child.Name == "Held" then
			local tool = child :: Tool
			tool.Activated:Connect(function()
				activate(tool)
			end)
			local weapon = tool:GetAttribute("Weapon") == true
			stop(if weapon then "ItemHold" else "WeaponHold")
			play(if weapon then "WeaponHold" else "ItemHold", 0.2)
		end
	end
	for _, child in character:GetChildren() do
		hook(child)
	end
	character.ChildAdded:Connect(hook)
	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child.Name == "Held" and not character:FindFirstChild("Held") then
			stop("WeaponHold")
			stop("ItemHold")
		end
	end)
end

-- Downed overlay -------------------------------------------------------------------------------------------
local downedFrame: Frame
local downedTimer: TextLabel

local function buildDowned(screen: ScreenGui)
	downedFrame = UIKit.New("Frame", {
		Name = "Downed",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(90, 0, 0),
		BackgroundTransparency = 0.6,
		Visible = false,
		ZIndex = 5,
		Parent = screen,
	})
	local title = UIKit.Label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.new(0.8, 0, 0, 70),
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = Theme.Display,
		TextSize = 56,
		TextColor3 = Color3.fromRGB(255, 120, 110),
		ZIndex = 6,
		Parent = downedFrame,
	})
	Lang.Bind(title, "downed.title")
	downedTimer = UIKit.Label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.4, 44),
		Size = UDim2.new(0.8, 0, 0, 30),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 20,
		ZIndex = 6,
		Parent = downedFrame,
	})
end

local function updateDowned()
	local down = player:GetAttribute("Downed") == true
	downedFrame.Visible = down
	downedTimer.Text = Lang.T("downed.waitTeam")
end

-- Workbench window ---------------------------------------------------------------------------------------
local craftPanel: Frame
local craftList: ScrollingFrame

local function renderCraft()
	for _, child in craftList:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local s = ClientState.Get() or {}
	for order, recipe in GameConfig.Recipes do
		local def = ItemDefinitions.Items[recipe.id]
		local affordable = true
		for itemId, amount in recipe.cost do
			local have = (s.inventory and s.inventory[itemId] or 0) + (s.storage and s.storage[itemId] or 0)
			if have < amount then
				affordable = false
			end
		end
		local row = UIKit.New("Frame", {
			Size = UDim2.new(1, -8, 0, 72),
			BackgroundColor3 = C.panelLight,
			BorderSizePixel = 0,
			LayoutOrder = order,
			Parent = craftList,
		}, { UIKit.Corner(8), UIKit.Padding(8) })
		UIKit.Label({
			Size = UDim2.fromOffset(56, 56),
			Text = def.icon,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = row,
		})
		UIKit.Label({
			Position = UDim2.fromOffset(66, 0),
			Size = UDim2.new(1, -200, 0, 28),
			Text = Lang.T("item." .. recipe.id .. ".name"),
			FontFace = Theme.Heading,
			TextSize = 22,
			Parent = row,
		})
		UIKit.Label({
			Position = UDim2.fromOffset(66, 28),
			Size = UDim2.new(1, -200, 0, 26),
			Text = Lang.T("prompt.needs", Locale.Cost(recipe.cost)),
			TextSize = 15,
			TextColor3 = if affordable then C.text else C.bad,
			Parent = row,
		})
		local button = UIKit.Button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromOffset(120, 48),
			Text = Lang.T("craft.button"),
			BackgroundColor3 = if affordable then Color3.fromRGB(60, 110, 60) else C.panel,
			TextColor3 = if affordable then C.text else C.muted,
			Parent = row,
		})
		button.Activated:Connect(function()
			remote(RemoteNames.Craft):FireServer(recipe.id)
		end)
	end
end

local function buildCraft(screen: ScreenGui)
	craftPanel = UIKit.Panel({
		Name = "Workbench",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 520, 0.86, 0),
		BackgroundTransparency = 0.05,
		Visible = false,
		Parent = screen,
	})
	-- Never taller than 360 and never off a short phone screen.
	UIKit.New("UISizeConstraint", { MaxSize = Vector2.new(520, 360), Parent = craftPanel })
	UIKit.Padding(14).Parent = craftPanel
	local title =
		UIKit.Label({ Size = UDim2.new(1, -44, 0, 30), FontFace = Theme.Display, TextSize = 26, Parent = craftPanel })
	Lang.Bind(title, "craft.title")
	local close = UIKit.Button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(36, 36),
		Text = "✕",
		Parent = craftPanel,
	})
	close.Activated:Connect(function()
		craftPanel.Visible = false
	end)
	craftList = UIKit.New("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 44),
		Size = UDim2.new(1, 0, 1, -44),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = craftPanel,
	})
	UIKit.New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = craftList })
end

function CombatController.OpenCraft()
	craftPanel.Visible = true
	renderCraft()
end

function CombatController.Start(remoteFolder: Folder)
	-- Unarmed attacks: a tap on the world (not a camera drag), a click or R2.
	UserInputService.TouchTapInWorld:Connect(function(_, processed)
		if not processed then
			punch()
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
			punch()
		end
	end)
	-- First time down the stairs: say how to fight.
	local hinted = false
	player:GetAttributeChangedSignal("Zone"):Connect(function()
		local zone = player:GetAttribute("Zone")
		if not hinted and type(zone) == "string" and string.sub(zone, 1, 5) == "Floor" then
			hinted = true
			local key = if UserInputService.TouchEnabled
				then "hint.attackTouch"
				elseif UserInputService.GamepadEnabled then "hint.attackPad"
				else "hint.attackPc"
			CombatController.Hint(Lang.T(key))
		end
	end)
	remotes = remoteFolder
	local screen = UIKit.Screen()
	task.spawn(hideDefaultBackpack)
	buildDowned(screen)
	buildCraft(screen)

	if player.Character then
		watchTool(player.Character)
	end
	player.CharacterAdded:Connect(watchTool)
	player:GetAttributeChangedSignal("Downed"):Connect(updateDowned)
	updateDowned()

	-- Revive prompts: translate them, and never show players their own.
	ProximityPromptService.PromptShown:Connect(function(prompt)
		if prompt:GetAttribute("ReviveUserId") == nil then
			return
		end
		if prompt:GetAttribute("ReviveUserId") == player.UserId then
			prompt.Enabled = false
			return
		end
		prompt.ActionText = Lang.T("revive.action")
	end)

	ClientState.Changed:Connect(function()
		if craftPanel.Visible then
			renderCraft()
		end
	end)
	Lang.Changed:Connect(function()
		updateDowned()
		if craftPanel.Visible then
			renderCraft()
		end
	end)

	-- Close the workbench window when walking away from it.
	task.spawn(function()
		while true do
			task.wait(0.5)
			if craftPanel.Visible then
				local world = workspace:FindFirstChild(GameConfig.World.FolderName)
				local interactables = world and world:FindFirstChild("Interactables")
				local bench = interactables and interactables:FindFirstChild("Workbench")
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if
					not bench
					or not root
					or ((bench :: BasePart).Position - (root :: BasePart).Position).Magnitude > 20
				then
					craftPanel.Visible = false
				end
			end
		end
	end)
end

return CombatController
