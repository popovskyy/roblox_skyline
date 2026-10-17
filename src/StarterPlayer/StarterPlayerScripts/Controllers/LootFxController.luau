--!strict
-- Loot crate effects, all local to this client:
--  * rarity you can spot from afar (rare: faint blue glow; gold: glow, sparkles, a quiet chime;
--    diamond: teal glow, a light beam to the ceiling and a low hum), off once you emptied the crate;
--  * the opening hold: the crate shakes and a rising sound plays;
--  * the opening itself: a lucky upgrade flash, the lid pops, a burst in the rarity colour, a camera
--    shake, the items fountain out, land with a beam and their name, then fly into your hands;
--  * a banner for everyone when somebody opens a gold or diamond crate.
-- The server has already rolled the tier and the contents and given the items; this only shows it.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local SoundConfig = require(ReplicatedStorage.Shared:WaitForChild("SoundConfig"))
local Theme = require(ReplicatedStorage.Shared.Theme)
local ClientState = require(script.Parent.ClientState)
local InventoryController = require(script.Parent.InventoryController)
local Lang = require(script.Parent.Lang)
local UIKit = require(script.Parent.UIKit)

local LootFxController = {}

local player = Players.LocalPlayer
local Loot = GameConfig.Loot

local TIER_COLORS = Theme.Rarity
local DIAMOND_TOP = Color3.fromRGB(190, 120, 255)
local SPARKLES = "rbxasset://textures/particles/sparkles_main.dds"
-- Gold/Diamond must read clearly louder than Commons (§10.5); Common/Rare stay restrained.
local SHAKE_STRENGTH: { [string]: number } = { Common = 0.15, Rare = 0.2, Gold = 0.75, Diamond = 1.1 }
local BANNER_SECONDS: { [string]: number } = { Gold = 5.0, Diamond = 5.5 }
local BANNER_VOLUME: { [string]: number } = { Gold = 0.85, Diamond = 1.0 }
local OPEN_BURST: { [string]: number } = { Common = 20, Rare = 35, Gold = 70, Diamond = 95 }

type CrateFx = {
	crate: BasePart,
	tier: string,
	lights: { Light },
	emitters: { ParticleEmitter },
	beams: { Beam },
	hum: Sound?,
	chime: Sound?,
	active: boolean,
}

local crates: { [BasePart]: CrateFx } = {}

local function soundId(name: string): string
	local ids = SoundConfig.Sounds[name]
	return if ids then "rbxassetid://" .. tostring(ids[math.random(1, #ids)]) else ""
end

local function makeSound(name: string, parent: Instance, volume: number, range: number?): Sound
	local sound = Instance.new("Sound")
	sound.SoundId = soundId(name)
	sound.Volume = volume
	if range then
		sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.RollOffMinDistance = 6
		sound.RollOffMaxDistance = range
	end
	sound.Parent = parent
	return sound
end

local function playOnce(name: string, parent: Instance?, volume: number)
	local sound = makeSound(name, parent or SoundService, volume, if parent then 60 else nil)
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	task.delay(10, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

local function sparkles(parent: Attachment, color: Color3, rate: number): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = SPARKLES
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 1
	emitter.Rate = rate
	emitter.Lifetime = NumberRange.new(1, 1.8)
	emitter.Speed = NumberRange.new(0.6, 1.6)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new(0.2)
	emitter.Parent = parent
	return emitter
end

-- Builds the from-afar look of one crate.
local function setupCrate(crate: BasePart)
	local tier = crate:GetAttribute("Tier")
	if type(tier) ~= "string" or crates[crate] then
		return
	end
	local color = TIER_COLORS[tier] or TIER_COLORS.Common
	local fx: CrateFx = {
		crate = crate,
		tier = tier,
		lights = {},
		emitters = {},
		beams = {},
		active = true,
	}
	local top = Instance.new("Attachment")
	top.Name = "LootTop"
	top.Position = Vector3.new(0, crate.Size.Y / 2 + 0.6, 0)
	top.Parent = crate
	local function light(brightness: number, range: number)
		local l = Instance.new("PointLight")
		l.Color = color
		l.Brightness = brightness
		l.Range = range
		l.Shadows = false
		l.Parent = top
		table.insert(fx.lights, l)
	end
	if tier == "Rare" then
		light(0.7, 9)
	elseif tier == "Gold" then
		light(1.4, 13)
		table.insert(fx.emitters, sparkles(top, color, 4))
		fx.chime = makeSound("LootChime", crate, 0.22, 35)
	elseif tier == "Diamond" then
		light(1.8, 15)
		table.insert(fx.emitters, sparkles(top, color, 5))
		local sky = Instance.new("Attachment")
		sky.Position = Vector3.new(0, 18, 0)
		sky.Parent = crate
		local beam = Instance.new("Beam")
		beam.Attachment0 = top
		beam.Attachment1 = sky
		beam.Color = ColorSequence.new(color, DIAMOND_TOP)
		beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
		beam.LightEmission = 1
		beam.Width0 = 1.6
		beam.Width1 = 0.5
		beam.FaceCamera = true
		beam.Parent = crate
		table.insert(fx.beams, beam)
		local hum = makeSound("LootHum", crate, 0.3, 45)
		hum.Looped = true
		hum:Play()
		fx.hum = hum
	end
	crates[crate] = fx
end

local function setActive(fx: CrateFx, active: boolean)
	if fx.active == active then
		return
	end
	fx.active = active
	for _, l in fx.lights do
		l.Enabled = active
	end
	for _, e in fx.emitters do
		e.Enabled = active
	end
	for _, b in fx.beams do
		b.Enabled = active
	end
	if fx.hum then
		if active then
			fx.hum:Play()
		else
			fx.hum:Stop()
		end
	end
end

local function hasItem(s: { [string]: any }, itemId: string): boolean
	return s.inventory ~= nil and (s.inventory[itemId] or 0) > 0
end

local function onState(s: { [string]: any })
	local depleted = s.depletedNodes or {}
	local hasKey = hasItem(s, "Key")
	for crate, fx in crates do
		local nodeId = crate:GetAttribute("NodeId")
		setActive(fx, not (type(nodeId) == "string" and depleted[nodeId] == true))
		-- A key opens a locked crate in a normal hold; without one it is the long crowbar break-in.
		if crate:GetAttribute("Locked") == true then
			local prompt = crate:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.HoldDuration = if hasKey then Loot.HoldSeconds else Loot.BreakInSeconds
			end
		end
	end
end

-- The opening hold: the crate (and its lid and trim) rattles harder and harder.
local shaking: { crate: BasePart, parts: { [BasePart]: CFrame }, conn: RBXScriptConnection, rise: Sound }? = nil

local function stopShake()
	local current = shaking
	if not current then
		return
	end
	shaking = nil
	current.conn:Disconnect()
	current.rise:Stop()
	current.rise:Destroy()
	for part, cframe in current.parts do
		part.CFrame = cframe
	end
end

local function startShake(crate: BasePart, hold: number)
	stopShake()
	local parts: { [BasePart]: CFrame } = { [crate] = crate.CFrame }
	for _, d in crate:GetDescendants() do
		if d:IsA("BasePart") then
			parts[d] = d.CFrame
		end
	end
	local center = crate.CFrame
	local started = os.clock()
	local rise = makeSound("LootRise", crate, 0.45, 40)
	rise.PlaybackSpeed = math.clamp(2.5 / math.max(hold, 0.5), 0.6, 1.6)
	rise:Play()
	local conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - started
		local strength = math.min(t / math.max(hold, 0.1), 1)
		local angle = math.rad(2.2) * strength * math.sin(t * 46)
		local wobble = center * CFrame.Angles(angle * 0.4, 0, angle) * center:Inverse()
		for part, cframe in parts do
			part.CFrame = wobble * cframe
		end
	end)
	shaking = { crate = crate, parts = parts, conn = conn, rise = rise }
end

-- Camera shake that fades out.
local function shakeCamera(strength: number, seconds: number)
	local name = "LootShake" .. tostring(os.clock())
	local started = os.clock()
	RunService:BindToRenderStep(name, Enum.RenderPriority.Camera.Value + 1, function()
		local t = os.clock() - started
		if t > seconds then
			RunService:UnbindFromRenderStep(name)
			return
		end
		local camera = workspace.CurrentCamera
		local fade = 1 - t / seconds
		local s = strength * fade
		camera.CFrame *= CFrame.new((math.random() - 0.5) * s, (math.random() - 0.5) * s, 0) * CFrame.Angles(
			0,
			0,
			math.rad((math.random() - 0.5) * s * 3)
		)
	end)
end

local function burst(crate: BasePart, color: Color3, count: number)
	local at = Instance.new("Attachment")
	at.Position = Vector3.new(0, crate.Size.Y / 2 + 0.4, 0)
	at.Parent = crate
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = SPARKLES
	emitter.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
	emitter.LightEmission = 1
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.5, 1.1)
	emitter.Speed = NumberRange.new(10, 22)
	emitter.SpreadAngle = Vector2.new(55, 55)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Drag = 4
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	emitter.Parent = at
	emitter:Emit(count)
	local flash = Instance.new("PointLight")
	flash.Color = color
	flash.Brightness = 8
	flash.Range = 18
	flash.Parent = at
	TweenService:Create(flash, TweenInfo.new(0.7), { Brightness = 0 }):Play()
	task.delay(2, function()
		at:Destroy()
	end)
end

local function popLid(crate: BasePart)
	local lid = crate:FindFirstChild("Lid")
	if not lid or not lid:IsA("BasePart") then
		return
	end
	local original = lid.CFrame
	local open = original * CFrame.new(0, 1.2, 0.9) * CFrame.Angles(math.rad(-75), 0, 0)
	TweenService:Create(lid, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = open })
		:Play()
	task.delay(3.5, function()
		if lid.Parent then
			lid.CFrame = original
		end
	end)
end

-- Lucky roll: the crate flips to the better tier's colour with a flash and a ding.
local function upgradeFlash(crate: BasePart, tier: string)
	local color = TIER_COLORS[tier] or TIER_COLORS.Common
	for _, d in crate:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "Trim" then
			d.Color = color
			d.Material = Enum.Material.Neon
		end
	end
	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.new(1, 1, 1)
	highlight.OutlineColor = color
	highlight.FillTransparency = 0
	highlight.Parent = crate
	TweenService:Create(highlight, TweenInfo.new(0.45), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
	task.delay(0.5, function()
		highlight:Destroy()
	end)
	playOnce("LootUpgrade", crate, 0.7)
end

local function iconFor(parent: Instance, def: ItemDefinitions.ItemDef): GuiObject
	if def.iconImage then
		return UIKit.New("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = def.iconImage,
			ImageColor3 = def.iconTint or Color3.new(1, 1, 1),
			Parent = parent,
		})
	end
	return UIKit.Label({
		Size = UDim2.fromScale(1, 1),
		Text = def.icon,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = parent,
	})
end

-- One item flying out of the crate, landing, then going to the player.
local function fountainItem(crate: BasePart, def: ItemDefinitions.ItemDef, amount: number, tier: string)
	local color = TIER_COLORS[tier] or TIER_COLORS.Common
	local part = Instance.new("Part")
	part.Name = "LootDrop"
	part.Size = Vector3.new(0.9, 0.9, 0.9)
	part.Transparency = 1
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CFrame = crate.CFrame * CFrame.new(0, crate.Size.Y / 2 + 1.2, 0)
	part.Parent = workspace
	local sideways = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5)
	sideways = if sideways.Magnitude > 0.01 then sideways.Unit else Vector3.xAxis
	part.AssemblyLinearVelocity = sideways * (5 + math.random() * 5) + Vector3.new(0, 24 + math.random() * 6, 0)

	local billboard = UIKit.New("BillboardGui", {
		Size = UDim2.fromScale(2.4, 2.4),
		AlwaysOnTop = true,
		LightInfluence = 0,
		Parent = part,
	})
	local icon = iconFor(billboard, def)
	TweenService:Create(icon, TweenInfo.new(0.9, Enum.EasingStyle.Linear), { Rotation = 360 }):Play()

	task.delay(0.95, function()
		if not part.Parent then
			return
		end
		-- Landed: hold still, show a short rarity beam and the name.
		part.Anchored = true
		part.CanCollide = false
		icon.Rotation = 0
		local base = Instance.new("Attachment")
		base.Parent = part
		local up = Instance.new("Attachment")
		up.Position = Vector3.new(0, 5, 0)
		up.Parent = part
		local beam = Instance.new("Beam")
		beam.Attachment0 = base
		beam.Attachment1 = up
		beam.Color = ColorSequence.new(color)
		beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		beam.LightEmission = 1
		beam.Width0 = 0.35
		beam.Width1 = 0.1
		beam.FaceCamera = true
		beam.Parent = part
		local label = UIKit.New("BillboardGui", {
			Size = UDim2.fromOffset(180, 28),
			StudsOffset = Vector3.new(0, 1.9, 0),
			AlwaysOnTop = true,
			LightInfluence = 0,
			Parent = part,
		})
		UIKit.Label({
			Size = UDim2.fromScale(1, 1),
			Text = (if amount > 1 then ("%d× "):format(amount) else "") .. Lang.ItemWithRarity(def.id),
			TextXAlignment = Enum.TextXAlignment.Center,
			FontFace = Theme.Display,
			TextSize = 20,
			TextColor3 = color,
			TextStrokeTransparency = 0.3,
			Parent = label,
		})

		-- Magnet: flies to the player once they are close, or after a moment anyway.
		local landed = os.clock()
		local conn: RBXScriptConnection
		conn = RunService.Heartbeat:Connect(function()
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not root or not root:IsA("BasePart") then
				return
			end
			local distance = (root.Position - part.Position).Magnitude
			if distance > 9 and os.clock() - landed < 2.4 then
				return
			end
			conn:Disconnect()
			beam.Enabled = false
			label.Enabled = false
			local tween = TweenService:Create(
				part,
				TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ CFrame = root.CFrame }
			)
			tween:Play()
			tween.Completed:Once(function()
				part:Destroy()
				playOnce("Pickup", nil, 0.35)
				if def.resource then
					InventoryController.FlashPouch(def.id, amount)
				end
			end)
		end)
	end)
	task.delay(8, function()
		if part.Parent then
			part:Destroy()
		end
	end)
end

-- Top-of-screen banner: "<Name> opened a GOLD chest!"
local bannerLabel: TextLabel? = nil
local bannerToken = 0
local function banner(): TextLabel
	if bannerLabel then
		return bannerLabel
	end
	local label = UIKit.Label({
		Name = "LootBanner",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 70),
		Size = UDim2.new(0.9, 0, 0, 44),
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = Theme.Display,
		TextSize = 32,
		TextStrokeTransparency = 0.2,
		Visible = false,
		ZIndex = 8,
		Parent = UIKit.Screen(),
	})
	bannerLabel = label
	return label
end

local function showBanner(name: string, tier: string)
	local label = banner()
	bannerToken += 1
	local token = bannerToken
	label.Text = Lang.T("loot.banner." .. tier, name)
	label.TextColor3 = TIER_COLORS[tier] or TIER_COLORS.Gold
	label.TextTransparency = 1
	label.TextStrokeTransparency = 1
	label.Visible = true
	TweenService:Create(label, TweenInfo.new(0.3), { TextTransparency = 0, TextStrokeTransparency = 0.2 }):Play()
	-- Banner SFX only here; open ding for Gold/Diamond is played once in onLootOpened (opener).
	playOnce("LootBanner", nil, BANNER_VOLUME[tier] or 0.5)
	local hold = BANNER_SECONDS[tier] or 3.5
	task.delay(hold, function()
		if bannerToken == token then
			TweenService:Create(label, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

local function onLootOpened(
	crate: Instance,
	tier: string,
	final: string,
	userId: number,
	name: string,
	loot: { [string]: number }
)
	local mine = userId == player.UserId
	if typeof(crate) == "Instance" and crate:IsA("BasePart") then
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local distance = if root and root:IsA("BasePart") then (root.Position - crate.Position).Magnitude else math.huge
		if mine or distance < 60 then
			task.spawn(function()
				if mine then
					stopShake()
					if final ~= tier then
						upgradeFlash(crate, final)
						task.wait(0.3)
					end
				end
				local color = TIER_COLORS[final] or TIER_COLORS.Common
				local rank = table.find(Loot.TierOrder, final) or 1
				popLid(crate)
				burst(crate, color, OPEN_BURST[final] or (20 + rank * 15))
				local strength = SHAKE_STRENGTH[final] or 0.2
				local shakeSeconds = if final == "Diamond"
					then 0.7
					elseif final == "Gold" then 0.55
					else 0.35 + rank * 0.08
				shakeCamera(if mine then strength else strength * 0.4, shakeSeconds)
				if mine and (final == "Gold" or final == "Diamond") then
					playOnce("LootUpgrade", crate, if final == "Diamond" then 0.9 else 0.65)
				end
				if mine and type(loot) == "table" then
					local index = 0
					for _, itemId in ItemDefinitions.Order do
						local amount = loot[itemId]
						local def = ItemDefinitions.Get(itemId)
						if def and type(amount) == "number" and amount > 0 then
							task.delay(index * 0.12, fountainItem, crate, def, amount, final)
							index += 1
						end
					end
				end
			end)
		end
	end
	if final == "Gold" or final == "Diamond" then
		showBanner(name, final)
	end
end

function LootFxController.Start(remotes: Folder)
	task.spawn(function()
		local world = workspace:WaitForChild(GameConfig.World.FolderName, 60)
		local interactables = world and world:WaitForChild("Interactables", 60)
		if not interactables then
			return
		end
		local function consider(d: Instance)
			if d:IsA("BasePart") and d:GetAttribute("InteractType") == "LootChest" then
				setupCrate(d)
			end
		end
		for _, d in interactables:GetDescendants() do
			consider(d)
		end
		interactables.DescendantAdded:Connect(consider)
		local s = ClientState.Get()
		if s then
			onState(s)
		end
		-- The gold crates chime now and then while they are still full.
		while true do
			task.wait(math.random(5, 9))
			for _, fx in crates do
				if fx.active and fx.chime then
					fx.chime.SoundId = soundId("LootChime")
					fx.chime:Play()
				end
			end
		end
	end)
	ClientState.Changed:Connect(onState)

	ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
		local crate = prompt.Parent
		if crate and crate:IsA("BasePart") and crate:GetAttribute("InteractType") == "LootChest" then
			startShake(crate, prompt.HoldDuration)
		end
	end)
	ProximityPromptService.PromptButtonHoldEnded:Connect(function()
		task.delay(0.15, stopShake)
	end)
	local lootOpened = remotes:WaitForChild(RemoteNames.LootOpened) :: RemoteEvent
	lootOpened.OnClientEvent:Connect(onLootOpened)
end

return LootFxController
