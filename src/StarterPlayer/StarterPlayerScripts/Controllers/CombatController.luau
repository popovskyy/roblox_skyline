--!strict
-- Client side of combat: what the held item does on a tap / click / R2 (attackInput), the hold and
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

-- Uploaded with scripts/build_animations.py. Priorities are set here too so they never depend on the
-- uploaded asset: the swings must beat the hold poses and the default walk/idle.
local ANIMATIONS: { [string]: { id: string, priority: Enum.AnimationPriority } } = {
	WeaponHold = { id = "rbxassetid://85303283403730", priority = Enum.AnimationPriority.Action },
	WeaponSwing = { id = "rbxassetid://106693888316440", priority = Enum.AnimationPriority.Action4 },
	ItemHold = { id = "rbxassetid://113741024764678", priority = Enum.AnimationPriority.Action },
	ItemUse = { id = "rbxassetid://73366190002807", priority = Enum.AnimationPriority.Action4 },
	Punch = { id = "rbxassetid://129369444994134", priority = Enum.AnimationPriority.Action4 },
}

local tracks: { [string]: AnimationTrack } = {}
local tracksAnimator: Animator? = nil

-- The local character's Animator, only once the character is in the Workspace: LoadAnimation fails
-- before that (it happens right after CharacterAdded, and for longer on slow phones and tablets).
local function currentAnimator(): Animator?
	local character = player.Character
	if not character or not character:IsDescendantOf(workspace) then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if animator and animator:IsA("Animator") then
		return animator
	end
	return nil
end

-- Loads whatever is missing for the current Animator; safe to call again and again.
local function ensureTracks(): boolean
	local animator = currentAnimator()
	if not animator then
		return false
	end
	if tracksAnimator ~= animator then
		table.clear(tracks)
		tracksAnimator = animator
	end
	local all = true
	for name, spec in ANIMATIONS do
		if not tracks[name] then
			local animation = Instance.new("Animation")
			animation.Name = name
			animation.AnimationId = spec.id
			local ok, track = pcall(function()
				return animator:LoadAnimation(animation)
			end)
			if ok and track then
				-- Keep the instance parented so a slow mobile download is not cancelled by GC.
				animation.Parent = animator
				track.Priority = spec.priority
				track.Looped = name ~= "WeaponSwing" and name ~= "Punch" and name ~= "ItemUse"
				tracks[name] = track
			else
				all = false
			end
		end
	end
	return all
end

-- Waits for the new character to be in the Workspace with its Animator, then loads every track.
local function loadTracks(character: Model)
	table.clear(tracks)
	tracksAnimator = nil
	for _ = 1, 40 do
		if player.Character ~= character then
			return
		end
		if ensureTracks() then
			return
		end
		task.wait(0.25)
	end
end

local function play(name: string, fade: number?)
	local track = tracks[name]
	if not track or tracksAnimator ~= currentAnimator() then
		ensureTracks()
		track = tracks[name]
	end
	if not track then
		return
	end
	local spec = ANIMATIONS[name]
	local oneShot = name == "WeaponSwing" or name == "Punch" or name == "ItemUse"
	if spec then
		-- Re-apply at play time. A looping hold or the default walk/tool pose (always on while
		-- the thumbstick is down) covers a swing whose priority was left at the asset default.
		track.Priority = spec.priority
		track.Looped = not oneShot
	end
	local function start(playing: AnimationTrack)
		-- Play() does nothing if this track is already playing, so a second tap shows no swing.
		if oneShot and playing.IsPlaying then
			playing:Stop(0)
		end
		playing:Play(fade or 0.1, 1, 1)
		if oneShot then
			playing:AdjustWeight(1, 0)
		end
	end
	start(track)
	-- On a phone Play() before the clip has downloaded is ignored and never retried.
	if oneShot and track.Length == 0 then
		local playing = track
		task.spawn(function()
			for _ = 1, 25 do
				if tracks[name] ~= playing or playing.Length > 0 then
					break
				end
				task.wait(0.1)
			end
			if tracks[name] == playing and playing.Length > 0 then
				if spec then
					playing.Priority = spec.priority
				end
				start(playing)
			end
		end)
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

-- Every attack input (tap, click, R2) lands here: use what is in hand, or punch.
-- The held Tool is ManualActivationOnly, so Roblox never fires its own Activated on top of this.
local lastUse = 0
local function attackInput()
	local character = player.Character
	local held = character and character:FindFirstChild("Held")
	if held and held:IsA("Tool") then
		local now = os.clock()
		if now - lastUse < 0.25 then
			return
		end
		lastUse = now
		activate(held)
	else
		punch()
	end
end

local function watchTool(character: Model)
	loadTracks(character)
	local function hook(child: Instance)
		if child:IsA("Tool") and child.Name == "Held" then
			local tool = child :: Tool
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

-- Downed screen (docs/design/HUD_SPEC.md, section 7) ---------------------------------------------------------------
-- Grey world, red edges, "YOU'RE DOWN", and every teammate with distance and whether they carry a bandage.
local downedFrame: Frame
local downedList: Frame
local downedGrade: ColorCorrectionEffect? = nil
local downedToken = 0

local function buildDowned(_screen: ScreenGui)
	local T = Theme.Colors
	local compact = UIKit.IsTouch()
	downedFrame = UIKit.New("Frame", {
		Name = "Downed",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 5,
		Parent = UIKit.FullScreen(),
	})
	for _, e in
		{
			{ UDim2.fromScale(1, 0.3), UDim2.fromScale(0, 0), 90 },
			{ UDim2.fromScale(1, 0.3), UDim2.fromScale(0, 0.7), -90 },
			{ UDim2.fromScale(0.22, 1), UDim2.fromScale(0, 0), 0 },
			{ UDim2.fromScale(0.22, 1), UDim2.fromScale(0.78, 0), 180 },
		}
	do
		local edge = UIKit.New("Frame", {
			Size = e[1],
			Position = e[2],
			BackgroundColor3 = T.Danger,
			BorderSizePixel = 0,
			ZIndex = 5,
			Parent = downedFrame,
		})
		UIKit.New("UIGradient", { Rotation = e[3], Transparency = NumberSequence.new(0.45, 1), Parent = edge })
	end
	local title = UIKit.Label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 92),
		Size = UDim2.new(0.9, 0, 0, if compact then 46 else 64),
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = Theme.Display,
		TextSize = if compact then 40 else 56,
		TextColor3 = T.DangerText,
		ZIndex = 6,
		Parent = downedFrame,
	})
	Lang.Bind(title, "downed.title")
	local sub = UIKit.Label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, if compact then 140 else 160),
		Size = UDim2.new(0.9, 0, 0, 24),
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = Theme.Semi,
		TextSize = 17,
		TextColor3 = T.Cream,
		ZIndex = 6,
		Parent = downedFrame,
	})
	Lang.Bind(sub, "downed.sub")
	downedList = UIKit.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, if compact then 172 else 198),
		Size = UDim2.fromOffset(340, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 6,
		Parent = downedFrame,
	}, { UIKit.Corner(10) })
	UIKit.Padding(10).Parent = downedList
	UIKit.New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = downedList })
end

local function renderTeammates()
	local T = Theme.Colors
	for _, child in downedList:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local any = false
	for i, other in Players:GetPlayers() do
		if other ~= player then
			any = true
			local root = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
			local meters = if root
					and myRoot
					and root:IsA("BasePart")
					and myRoot:IsA("BasePart")
				then math.floor((root.Position - myRoot.Position).Magnitude * 0.28 + 0.5)
				else nil
			local hasBandage = other:GetAttribute("HasBandage") == true
			local row = UIKit.New("Frame", {
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1,
				LayoutOrder = i,
				ZIndex = 6,
				Parent = downedList,
			})
			UIKit.Label({
				Size = UDim2.fromScale(0.5, 1),
				Text = other.DisplayName .. (if meters then "  ·  " .. Lang.T("downed.meters", meters) else ""),
				FontFace = Theme.Bold,
				TextSize = 16,
				TextColor3 = T.Cream,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 6,
				Parent = row,
			})
			UIKit.Label({
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.fromScale(0.5, 1),
				Text = Lang.T(if hasBandage then "downed.hasBandage" else "downed.noBandage"),
				TextXAlignment = Enum.TextXAlignment.Right,
				TextSize = 15,
				TextColor3 = if hasBandage then T.Hunger else T.CreamDim,
				ZIndex = 6,
				Parent = row,
			})
		end
	end
	downedList.Visible = any
end

local function updateDowned()
	local down = player:GetAttribute("Downed") == true and player:GetAttribute("MatchOver") ~= true
	downedFrame.Visible = down
	downedToken += 1
	local token = downedToken
	if down then
		if not downedGrade then
			local grade = Instance.new("ColorCorrectionEffect")
			grade.Name = "DownedGrade"
			grade.Saturation = -0.6
			grade.Contrast = 0.1
			grade.Parent = game:GetService("Lighting")
			downedGrade = grade
		end
		task.spawn(function()
			while downedToken == token do
				renderTeammates()
				task.wait(0.5)
			end
		end)
	elseif downedGrade then
		downedGrade:Destroy()
		downedGrade = nil
	end
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
			TextColor3 = if def.rarity then Theme.Rarity[def.rarity] else C.text,
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
		Text = "X",
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

-- A finger tap on a phone or tablet jitters by tens of pixels. The old 14px test, on the full
-- Vector3 (touch Position.Z is not a pixel), classed every hit as a camera drag, so attackInput
-- never ran and the swing never played. Mouse and R2 do not go through this test.
local function tapSlop(): number
	local camera = workspace.CurrentCamera
	local height = if camera then camera.ViewportSize.Y else 800
	return math.clamp(height * 0.06, 40, 96)
end

local function touchTravel(from: Vector3, toPos: Vector3): number
	local dx = toPos.X - from.X
	local dy = toPos.Y - from.Y
	return math.sqrt(dx * dx + dy * dy)
end

function CombatController.Start(remoteFolder: Folder)
	-- Phones download clips slower than Studio. Preload so the first tap is not a silent Play().
	task.spawn(function()
		local ContentProvider = game:GetService("ContentProvider")
		local assets: { Instance } = {}
		for _, spec in ANIMATIONS do
			local animation = Instance.new("Animation")
			animation.AnimationId = spec.id
			table.insert(assets, animation)
		end
		pcall(function()
			ContentProvider:PreloadAsync(assets)
		end)
	end)
	-- Attack input (weapon, item or fist): a tap on the world, a click or R2.
	-- Phones: a short tap that barely moves (not a camera drag). Tracked by hand because TouchTapInWorld
	-- does not fire reliably next to the touch controls. The held Tool stays ManualActivationOnly.
	local touches: { [InputObject]: { at: Vector3, started: number, moved: number } } = {}
	UserInputService.InputBegan:Connect(function(input, processed)
		if input.UserInputType == Enum.UserInputType.Touch and not processed then
			touches[input] = { at = input.Position, started = os.clock(), moved = 0 }
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		local start = touches[input]
		if not start then
			return
		end
		local dist = touchTravel(start.at, input.Position)
		if dist > start.moved then
			start.moved = dist
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		local start = touches[input]
		if not start then
			return
		end
		touches[input] = nil
		local dist = math.max(start.moved, touchTravel(start.at, input.Position))
		if os.clock() - start.started <= 0.5 and dist <= tapSlop() then
			attackInput()
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
			attackInput()
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
		task.spawn(watchTool, player.Character)
	end
	player.CharacterAdded:Connect(watchTool)
	player:GetAttributeChangedSignal("Downed"):Connect(updateDowned)
	player:GetAttributeChangedSignal("MatchOver"):Connect(updateDowned)
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
