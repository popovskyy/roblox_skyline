--!strict
-- Client side of combat: swing input, the "you are down" screen, revive prompts and the workbench window.
-- Every decision (hits, damage, revives, crafting) is made by the server.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local Locale = require(ReplicatedStorage.Shared.Locale)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ClientState = require(script.Parent.ClientState)
local Lang = require(script.Parent.Lang)
local UIKit = require(script.Parent.UIKit)

local CombatController = {}

local player = Players.LocalPlayer
local C = UIKit.Colors
local remotes: Folder

local function remote(name: string): RemoteEvent
	return remotes:FindFirstChild(name) :: RemoteEvent
end

-- R15 ToolSlash — local play for instant mobile feedback; server also plays for replication.
local SLASH_ANIM_ID = "rbxassetid://522635514"
local localSlash: AnimationTrack? = nil

local function playLocalSlash()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	if not localSlash or localSlash.Parent == nil then
		local anim = Instance.new("Animation")
		anim.AnimationId = SLASH_ANIM_ID
		localSlash = animator:LoadAnimation(anim)
		localSlash.Priority = Enum.AnimationPriority.Action
		localSlash.Looped = false
	end
	localSlash:Play(0.05, 1, 1.15)
end

local function attack()
	playLocalSlash()
	remote(RemoteNames.Attack):FireServer()
end

-- Our own hotbar replaces the Roblox backpack bar.
local function hideDefaultBackpack()
	for _ = 1, 20 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
		if ok then
			return
		end
		task.wait(0.5)
	end
end

local function watchTool(character: Model)
	local function hook(child: Instance)
		if child:IsA("Tool") and child.Name == "Weapon" then
			child.Activated:Connect(attack)
		end
	end
	for _, child in character:GetChildren() do
		hook(child)
	end
	character.ChildAdded:Connect(hook)
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
	-- Soft token sink: Bandage for tokens (shown after scrap recipes).
	local tokenCost = GameConfig.Tokens.BandageCost or 15
	local tokens = s.tokens or 0
	local canToken = tokens >= tokenCost
	local tokenRow = UIKit.New("Frame", {
		Size = UDim2.new(1, -8, 0, 72),
		BackgroundColor3 = C.panelLight,
		BorderSizePixel = 0,
		LayoutOrder = 90,
		Parent = craftList,
	}, { UIKit.Corner(8), UIKit.Padding(8) })
	UIKit.Label({
		Size = UDim2.fromOffset(56, 56),
		Text = ItemDefinitions.Items.Bandage.icon,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = tokenRow,
	})
	UIKit.Label({
		Position = UDim2.fromOffset(66, 0),
		Size = UDim2.new(1, -200, 0, 28),
		Text = Lang.T("craft.tokenBandage"),
		FontFace = Theme.Heading,
		TextSize = 22,
		Parent = tokenRow,
	})
	UIKit.Label({
		Position = UDim2.fromOffset(66, 28),
		Size = UDim2.new(1, -200, 0, 26),
		Text = Lang.T("craft.tokenCost", tokenCost) .. ("  ·  %d"):format(tokens),
		TextSize = 15,
		TextColor3 = if canToken then C.text else C.bad,
		Parent = tokenRow,
	})
	local tokenBtn = UIKit.Button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(120, 48),
		Text = Lang.T("craft.button"),
		BackgroundColor3 = if canToken then Color3.fromRGB(60, 110, 60) else C.panel,
		TextColor3 = if canToken then C.text else C.muted,
		Parent = tokenRow,
	})
	tokenBtn.Activated:Connect(function()
		remote(RemoteNames.Craft):FireServer("BandageToken")
	end)
end

local function buildCraft(screen: ScreenGui)
	craftPanel = UIKit.Panel({
		Name = "Workbench",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(520, 360),
		BackgroundTransparency = 0.05,
		Visible = false,
		Parent = screen,
	})
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
	remotes = remoteFolder
	local screen = UIKit.Screen()
	task.spawn(hideDefaultBackpack)
	buildDowned(screen)
	buildCraft(screen)

	if player.Character then
		watchTool(player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		localSlash = nil
		watchTool(character)
	end)
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

	-- A big hit button for touch screens (tapping the world also swings).
	if UserInputService.TouchEnabled then
		local hit = UIKit.Button({
			Name = "AttackButton",
			AnchorPoint = Vector2.new(1, 1),
			-- Left of the jump button, above the hotbar's right end.
			Position = UDim2.new(1, -118, 1, -16),
			Size = UDim2.fromOffset(84, 84),
			Text = "",
			TextSize = 20,
			BackgroundColor3 = Color3.fromRGB(150, 60, 50),
			Parent = screen,
		})
		-- Round button, only while a weapon is in hand.
		local corner = hit:FindFirstChildOfClass("UICorner")
		if corner then
			corner.CornerRadius = UDim.new(1, 0)
		end
		Lang.Bind(hit, "ui.attack")
		hit.Activated:Connect(attack)
		local function updateHit()
			hit.Visible = player:GetAttribute("Equipped") ~= nil
		end
		player:GetAttributeChangedSignal("Equipped"):Connect(updateHit)
		updateHit()
	end

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
