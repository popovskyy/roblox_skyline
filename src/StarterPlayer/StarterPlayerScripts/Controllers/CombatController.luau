--!strict
-- Client side of combat: what the held item does on a tap / click / R2 (attackInput), the hold and
-- swing animations, the "you are down" screen, revive prompts and the workbench window.
-- Every decision (hits, damage, revives, crafting) is made by the server.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local Theme = require(ReplicatedStorage.Shared.Theme)
local ClientState = require(script.Parent.ClientState)
local IntroController = require(script.Parent.IntroController)
local Lang = require(script.Parent.Lang)
local QuantityPicker = require(script.Parent.QuantityPicker)
local UIKit = require(script.Parent.UIKit)

local CombatController = {}

-- Set by ClientMain: shows a short message; false if intro soft-silence dropped it.
CombatController.Hint = function(_text: string): boolean
	return false
end

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
		track.Priority = spec.priority
		track.Looped = not oneShot
	end
	if oneShot and track.IsPlaying then
		track:Stop(0)
	end
	track:Play(fade or 0.1, 1, 1)
	if oneShot then
		track:AdjustWeight(1, 0)
	end
end

local function stop(name: string)
	local track = tracks[name]
	if track and track.IsPlaying then
		track:Stop(0.2)
	end
end

-- Touch devices often never download custom AnimationTracks (or Play is ignored while Length==0).
-- Drive the arm with Motor6D.Transform so a swing is always visible locally; keep asset clips on PC.
local swingToken = 0
local swingConn: RBXScriptConnection? = nil

local function findMotor(motorName: string): Motor6D?
	local character = player.Character
	if not character then
		return nil
	end
	local motor = character:FindFirstChild(motorName, true)
	if motor and motor:IsA("Motor6D") then
		return motor
	end
	return nil
end

local function restoreHoldPose()
	local character = player.Character
	local held = character and character:FindFirstChild("Held")
	if held and held:IsA("Tool") then
		local weapon = held:GetAttribute("Weapon") == true
		play(if weapon then "WeaponHold" else "ItemHold", 0.15)
	end
end

local function proceduralSwing(kind: "weapon" | "punch")
	local shoulder = findMotor("RightShoulder")
	local elbow = findMotor("RightElbow")
	local waist = findMotor("Waist")
	if not shoulder then
		return
	end
	-- Hold clips overwrite Transform every frame; pause them for the one-shot.
	stop("WeaponHold")
	stop("ItemHold")
	if swingConn then
		swingConn:Disconnect()
		swingConn = nil
	end
	swingToken += 1
	local token = swingToken
	local duration = if kind == "punch" then 0.28 else 0.38
	local started = os.clock()
	-- Keyframes: t ∈ [0,1] → shoulder / elbow / waist Transform (joint space).
	local windupS = if kind == "punch"
		then CFrame.Angles(math.rad(50), 0, math.rad(20))
		else CFrame.Angles(math.rad(95), math.rad(15), math.rad(35))
	local strikeS = if kind == "punch"
		then CFrame.Angles(math.rad(85), math.rad(10), math.rad(-8))
		else CFrame.Angles(math.rad(55), math.rad(40), math.rad(-15))
	local windupE = CFrame.Angles(math.rad(70), 0, 0)
	local strikeE = CFrame.Angles(math.rad(8), 0, 0)
	local windupW = CFrame.Angles(0, math.rad(-22), 0)
	local strikeW = CFrame.Angles(math.rad(-8), math.rad(28), 0)

	local function lerpCf(a: CFrame, b: CFrame, alpha: number): CFrame
		return a:Lerp(b, alpha)
	end

	-- Stepped runs after the Animator has posed the joints for this frame, so these Transforms are the
	-- ones that get drawn. (Writing them in RenderStepped was overwritten by the idle/walk clips, which
	-- is why tablet players never saw their own swing.)
	swingConn = RunService.Stepped:Connect(function()
		if token ~= swingToken then
			return
		end
		local t = (os.clock() - started) / duration
		if t >= 1 or not shoulder.Parent then
			shoulder.Transform = CFrame.new()
			if elbow then
				elbow.Transform = CFrame.new()
			end
			if waist then
				waist.Transform = CFrame.new()
			end
			if swingConn then
				swingConn:Disconnect()
				swingConn = nil
			end
			restoreHoldPose()
			return
		end
		local shoulderCf: CFrame
		local elbowCf: CFrame
		local waistCf: CFrame
		if t < 0.35 then
			local a = t / 0.35
			shoulderCf = lerpCf(CFrame.new(), windupS, a)
			elbowCf = lerpCf(CFrame.new(), windupE, a)
			waistCf = lerpCf(CFrame.new(), windupW, a)
		elseif t < 0.55 then
			local a = (t - 0.35) / 0.2
			shoulderCf = lerpCf(windupS, strikeS, a)
			elbowCf = lerpCf(windupE, strikeE, a)
			waistCf = lerpCf(windupW, strikeW, a)
		else
			local a = (t - 0.55) / 0.45
			shoulderCf = lerpCf(strikeS, CFrame.new(), a)
			elbowCf = lerpCf(strikeE, CFrame.new(), a)
			waistCf = lerpCf(strikeW, CFrame.new(), a)
		end
		shoulder.Transform = shoulderCf
		if elbow then
			elbow.Transform = elbowCf
		end
		if waist then
			waist.Transform = waistCf
		end
	end)
end

local function playSwing(name: "WeaponSwing" | "Punch")
	-- The server plays the swing clip on our character for everyone (CombatService.playSwing), so the
	-- client does not play its own copy. Touch devices also get the procedural arm swing locally, which
	-- shows at once even if the clip is slow to load there.
	if UserInputService.TouchEnabled then
		proceduralSwing(if name == "Punch" then "punch" else "weapon")
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
		playSwing("WeaponSwing")
		remote(RemoteNames.Attack):FireServer()
	elseif def.use == "eat" or def.use == "heal" then
		play("ItemUse")
		remote(RemoteNames.UseItem):FireServer(def.id)
	elseif def.use == "light" then
		remote(RemoteNames.ToggleFlashlight):FireServer()
	end
end

-- Our own hotbar / vitals replace Roblox defaults. The default Health bar sat top-right as a
-- yellow meter (looked like a second "weight" next to the menu) and confused players.
local function hideDefaultCoreGui()
	for _ = 1, 20 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
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
	playSwing("Punch")
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
		-- How many the team can pay for right now (weapons: one).
		local canMake = 10
		-- Each ingredient as "have/need", green when there is enough (backpack + chest + teammates on
		-- the roof, the same pool the server spends from), red when not.
		local parts = {}
		for _, itemId in ItemDefinitions.Order do
			local amount = recipe.cost[itemId]
			if amount then
				local have = (s.inventory and s.inventory[itemId] or 0)
					+ (s.storage and s.storage[itemId] or 0)
					+ (s.teamPool and s.teamPool[itemId] or 0)
				canMake = math.min(canMake, math.floor(have / amount))
				local color = if have >= amount then "#9FD18B" else "#FF9C8F"
				table.insert(
					parts,
					('<font color="%s">%s %d/%d</font>'):format(
						color,
						Lang.T("item." .. itemId .. ".name"),
						math.min(have, amount),
						amount
					)
				)
			end
		end
		if def.weapon then
			canMake = math.min(canMake, 1)
		end
		local affordable = canMake > 0
		local row = UIKit.New("Frame", {
			Size = UDim2.new(1, -8, 0, 72),
			BackgroundColor3 = C.panelLight,
			BorderSizePixel = 0,
			LayoutOrder = order,
			Parent = craftList,
		}, { UIKit.Corner(8), UIKit.Padding(8) })
		if def.iconImage then
			UIKit.New("ImageLabel", {
				Size = UDim2.fromOffset(56, 56),
				BackgroundTransparency = 1,
				Image = def.iconImage,
				ImageColor3 = def.iconTint or Color3.new(1, 1, 1),
				ScaleType = Enum.ScaleType.Fit,
				Parent = row,
			})
		else
			UIKit.Label({
				Size = UDim2.fromOffset(56, 56),
				Text = def.icon,
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Center,
				Parent = row,
			})
		end
		UIKit.Label({
			Position = UDim2.fromOffset(66, 0),
			Size = UDim2.new(1, -200, 0, 28),
			Text = Lang.ItemWithRarity(recipe.id),
			FontFace = Theme.Heading,
			TextSize = 22,
			TextColor3 = if def.rarity then Theme.Rarity[def.rarity] else C.text,
			Parent = row,
		})
		UIKit.Label({
			Position = UDim2.fromOffset(66, 28),
			Size = UDim2.new(1, -200, 0, 20),
			Text = table.concat(parts, "  ·  "),
			RichText = true,
			TextSize = 15,
			TextColor3 = C.text,
			Parent = row,
		})
		UIKit.Label({
			Position = UDim2.fromOffset(66, 48),
			Size = UDim2.new(1, -200, 0, 16),
			Text = Lang.T("craft.pool"),
			TextSize = 13,
			TextColor3 = C.muted,
			Parent = row,
		})
		local button = UIKit.Button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromOffset(120, 48),
			Text = Lang.T("craft.button"),
			BackgroundColor3 = if affordable then Color3.fromRGB(60, 110, 60) else C.panel,
			TextColor3 = if affordable then C.text else C.muted,
			AutoButtonColor = affordable,
			Parent = row,
		})
		button.Activated:Connect(function()
			if not affordable then
				return
			end
			if canMake > 1 then
				QuantityPicker.Open(
					Lang.T("qty.craft", Lang.T("item." .. recipe.id .. ".name")),
					def.iconImage,
					canMake,
					function(n)
						remote(RemoteNames.Craft):FireServer(recipe.id, n)
					end
				)
			else
				remote(RemoteNames.Craft):FireServer(recipe.id, 1)
			end
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
-- Tablets: larger viewport + finger travel; allow a wider band than phones.
local function tapSlop(): number
	local camera = workspace.CurrentCamera
	local size = if camera then camera.ViewportSize else Vector2.new(800, 800)
	local base = math.max(size.X, size.Y) * 0.055
	return math.clamp(base, 48, 160)
end

local function touchTravel(from: Vector3, toPos: Vector3): number
	local dx = toPos.X - from.X
	local dy = toPos.Y - from.Y
	return math.sqrt(dx * dx + dy * dy)
end

-- True when this screen point sits on a tappable GUI (jump, hotbar, menu). Camera/world taps
-- that Roblox still marks processed (common on tablets) must still count as attacks.
local function touchOnGuiButton(screenPos: Vector3): boolean
	local gui = player:FindFirstChildOfClass("PlayerGui")
	if not gui then
		return false
	end
	local objects = gui:GetGuiObjectsAtPosition(screenPos.X, screenPos.Y)
	for _, obj in objects do
		if obj:IsA("GuiButton") or obj:IsA("TextBox") then
			return true
		end
	end
	return false
end

local function buildAttackButton(screen: ScreenGui)
	-- Dedicated Hit control: world-tap heuristics kept failing on tablets (processed Touch, camera drag).
	if not UserInputService.TouchEnabled then
		return
	end
	local T = Theme.Colors
	local holder = UIKit.New("Frame", {
		Name = "AttackButton",
		AnchorPoint = Vector2.new(1, 1),
		-- Left of the interact button (InteractionController at -111); clear of the jump pad.
		Position = UDim2.new(1, -190, 1, -42),
		Size = UDim2.fromOffset(72, 72),
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = screen,
	})
	local button = UIKit.New("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = T.Panel,
		BackgroundTransparency = 0.15,
		Text = "",
		AutoButtonColor = false,
		Active = true,
		Parent = holder,
	}, { UIKit.Corner(36) })
	UIKit.New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = T.Danger,
		Thickness = 3,
		Parent = button,
	})
	local label = UIKit.Label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.85, 0.45),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = Theme.Bold,
		TextSize = 18,
		TextColor3 = T.Cream,
		ZIndex = 5,
		Parent = button,
	})
	Lang.Bind(label, "ui.attack")
	local function refresh()
		holder.Visible = player:GetAttribute("Downed") ~= true and player:GetAttribute("MatchOver") ~= true
	end
	button.Activated:Connect(function()
		attackInput()
	end)
	player:GetAttributeChangedSignal("Downed"):Connect(refresh)
	player:GetAttributeChangedSignal("MatchOver"):Connect(refresh)
	refresh()
end

function CombatController.Start(remoteFolder: Folder)
	-- PC still uses uploaded clips; preload only when not on touch.
	if not UserInputService.TouchEnabled then
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
	end
	-- Secondary: short world taps (phones). Tablets rely on the Hit button above.
	local touches: { [InputObject]: { at: Vector3, started: number, moved: number } } = {}
	UserInputService.InputBegan:Connect(function(input, processed)
		if input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if processed and touchOnGuiButton(input.Position) then
			return
		end
		touches[input] = { at = input.Position, started = os.clock(), moved = 0 }
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
		if os.clock() - start.started <= 0.55 and dist <= tapSlop() then
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
	-- First time down the stairs: say how to fight. Do not mark done if intro soft-silence
	-- drops the toast (otherwise Floor entry during silence loses the tip for the match).
	local hinted = false
	local function tryAttackHint()
		if hinted then
			return
		end
		local zone = player:GetAttribute("Zone")
		if type(zone) ~= "string" or string.sub(zone, 1, 5) ~= "Floor" then
			return
		end
		if IntroController.BlocksSoftToasts() then
			return
		end
		local key = if UserInputService.TouchEnabled
			then "hint.attackTouch"
			elseif UserInputService.GamepadEnabled then "hint.attackPad"
			else "hint.attackPc"
		if CombatController.Hint(Lang.T(key)) then
			hinted = true
		end
	end
	player:GetAttributeChangedSignal("Zone"):Connect(tryAttackHint)
	task.spawn(function()
		while not hinted and player.Parent do
			tryAttackHint()
			task.wait(0.4)
		end
	end)
	remotes = remoteFolder
	local screen = UIKit.Screen()
	task.spawn(hideDefaultCoreGui)
	buildDowned(screen)
	buildCraft(screen)
	buildAttackButton(screen)

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
