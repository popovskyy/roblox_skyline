--!strict
-- Builds the grey-box prototype world from plain Parts into Workspace.GeneratedWorld.
-- Running it again reuses the existing folder instead of building a second copy.
--
-- Interactive parts live in GeneratedWorld.Interactables and carry an InteractType attribute.
-- Parts with UpgradeVisual = "<UpgradeId>" are shown ("Show") or hidden ("Hide") per player by the client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Shared.Theme)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Atmosphere = require(script.Parent.Atmosphere)
local Scenery = require(script.Parent.Scenery)

local World = GameConfig.World

export type WorldRefs = {
	root: Folder,
	interactables: Folder,
	storagePart: BasePart,
	generatorPart: BasePart,
	toxicZones: { BasePart },
	victoryZone: BasePart,
	workbench: BasePart,
	roofDropPosition: Vector3,
}

local WorldBuilder = {}

-- Stairwell footprint (hole in every slab except the bottom floor).
local HOLE_X = 9 -- half width of the stairwell; each lane is HOLE_X - 0.5 wide
local HOLE_MIN_Z = -15
local HOLE_MAX_Z = 15
local LANDING_Z = 9
local LANE_CENTER = (HOLE_X + 0.5) / 2
local LANE_WIDTH = HOLE_X - 0.5
local WALL_HEIGHT = World.FloorSpacing - World.SlabThickness

local COLORS = {
	concrete = Color3.fromRGB(120, 118, 115),
	darkConcrete = Color3.fromRGB(82, 80, 78),
	roof = Color3.fromRGB(96, 98, 100),
	metal = Color3.fromRGB(110, 115, 120),
	rust = Color3.fromRGB(130, 82, 52),
	rail = Color3.fromRGB(200, 170, 40),
	glass = Color3.fromRGB(150, 180, 190),
	rubble = Color3.fromRGB(105, 95, 85),
	toxic = Color3.fromRGB(110, 200, 60),
	wood = Color3.fromRGB(120, 90, 60),
	fabric = Color3.fromRGB(80, 90, 110),
	silhouette = Color3.fromRGB(45, 48, 55),
}

local function levelY(level: number): number
	return World.RoofY - level * World.FloorSpacing
end

local function block(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.Concrete
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- A part resting on the floor of the given level.
local function onFloor(
	parent: Instance,
	name: string,
	level: number,
	x: number,
	z: number,
	size: Vector3,
	color: Color3,
	material: Enum.Material?
): Part
	return block(parent, name, size, CFrame.new(x, levelY(level) + size.Y / 2, z), color, material)
end

-- Axis-aligned box between two corners on the floor of the given level.
local function wallBetween(
	parent: Instance,
	name: string,
	level: number,
	x1: number,
	z1: number,
	x2: number,
	z2: number,
	height: number,
	color: Color3?
): Part
	local thickness = 1
	local sx = math.max(math.abs(x2 - x1), thickness)
	local sz = math.max(math.abs(z2 - z1), thickness)
	return block(
		parent,
		name,
		Vector3.new(sx, height, sz),
		CFrame.new((x1 + x2) / 2, levelY(level) + height / 2, (z1 + z2) / 2),
		color or COLORS.concrete
	)
end

-- Text in the world is stored as a Locale key; each client relabels it in its own language.
-- An argument that starts with "@" is a key reference (e.g. "@upgrade.Bridge.name").
local function localized(key: string, arg: any?): string
	if type(arg) == "string" and string.sub(arg, 1, 1) == "@" then
		return Locale.T("en", key, { ref = string.sub(arg, 2) })
	end
	if arg ~= nil then
		return Locale.T("en", key, arg)
	end
	return Locale.T("en", key)
end

local function sign(parent: Instance, key: string, cframe: CFrame, size: Vector2, color: Color3?, arg: any?)
	local board =
		block(parent, "Sign", Vector3.new(size.X, size.Y, 0.3), cframe, Color3.fromRGB(30, 30, 30), Enum.Material.Metal)
	board.CanCollide = false
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.FontFace = Theme.Bold
	label.TextColor3 = color or Color3.fromRGB(255, 220, 80)
	label.Text = localized(key, arg)
	label:SetAttribute("TextKey", key)
	if arg ~= nil then
		label:SetAttribute("TextArg1", arg)
	end
	label.Parent = gui
end

local function addPrompt(
	part: BasePart,
	actionKey: string,
	objectKey: string,
	hold: number?,
	objectArg1: any?,
	objectArg2: any?
)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = Locale.T("en", actionKey)
	prompt:SetAttribute("ActionKey", actionKey)
	prompt:SetAttribute("ObjectKey", objectKey)
	prompt:SetAttribute("ObjectArg1", objectArg1)
	prompt:SetAttribute("ObjectArg2", objectArg2)
	local function arg(value: any): any
		if type(value) == "string" and string.sub(value, 1, 1) == "@" then
			return { ref = string.sub(value, 2) }
		end
		return value
	end
	if objectArg1 ~= nil then
		prompt.ObjectText = Locale.T("en", objectKey, arg(objectArg1), arg(objectArg2))
	else
		prompt.ObjectText = Locale.T("en", objectKey)
	end
	prompt.HoldDuration = hold or 0
	prompt.MaxActivationDistance = GameConfig.PromptActivationDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = part
	return prompt
end

local function pointLight(parent: BasePart, color: Color3, range: number, brightness: number, enabled: boolean)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Enabled = enabled
	light.Shadows = true
	light.Parent = parent
	return light
end

-- Slab with the stairwell hole cut out (built from four rectangles around it).
local function slab(parent: Instance, name: string, size: number, topY: number, withHole: boolean, color: Color3)
	local t = World.SlabThickness
	local y = topY - t / 2
	local half = size / 2
	if not withHole then
		block(parent, name, Vector3.new(size, t, size), CFrame.new(0, y, 0), color)
		return
	end
	block(parent, name .. "_W", Vector3.new(half - HOLE_X, t, size), CFrame.new(-(half + HOLE_X) / 2, y, 0), color)
	block(parent, name .. "_E", Vector3.new(half - HOLE_X, t, size), CFrame.new((half + HOLE_X) / 2, y, 0), color)
	block(
		parent,
		name .. "_S",
		Vector3.new(HOLE_X * 2, t, half + HOLE_MIN_Z),
		CFrame.new(0, y, (-half + HOLE_MIN_Z) / 2),
		color
	)
	block(
		parent,
		name .. "_N",
		Vector3.new(HOLE_X * 2, t, half - HOLE_MAX_Z),
		CFrame.new(0, y, (half + HOLE_MAX_Z) / 2),
		color
	)
end

-- A sloped walkway whose top surface runs exactly from a to b.
local function ramp(parent: Instance, name: string, a: Vector3, b: Vector3, width: number)
	local length = (b - a).Magnitude
	local frame = CFrame.lookAt((a + b) / 2, b) * CFrame.new(0, -0.5, 0)
	local part =
		block(parent, name, Vector3.new(width, 1, length + 0.6), frame, COLORS.metal, Enum.Material.DiamondPlate)
	return part
end

local function buildStairwell(parent: Folder)
	local stairs = Instance.new("Folder")
	stairs.Name = "Stairwell"
	stairs.Parent = parent

	local bottom = levelY(World.FloorCount)
	local top = World.RoofY
	local totalHeight = top - bottom

	-- Shaft walls on both sides and the far end, full height plus the roof hut.
	local hutHeight = 10
	local wallH = totalHeight + hutHeight
	local wallY = bottom + wallH / 2
	local wallLen = HOLE_MAX_Z - HOLE_MIN_Z + 1
	local wallZ = (HOLE_MIN_Z + HOLE_MAX_Z + 1) / 2
	block(
		stairs,
		"ShaftWall_W",
		Vector3.new(1, wallH, wallLen),
		CFrame.new(-HOLE_X - 0.5, wallY, wallZ),
		COLORS.darkConcrete
	)
	block(
		stairs,
		"ShaftWall_E",
		Vector3.new(1, wallH, wallLen),
		CFrame.new(HOLE_X + 0.5, wallY, wallZ),
		COLORS.darkConcrete
	)
	block(
		stairs,
		"ShaftWall_N",
		Vector3.new(HOLE_X * 2 + 2, wallH, 1),
		CFrame.new(0, wallY, HOLE_MAX_Z + 0.5),
		COLORS.darkConcrete
	)
	-- Divider between the down lane (west) and the up lane (east); doubles as a railing on the roof.
	local dividerH = totalHeight + 4
	block(
		stairs,
		"Divider",
		Vector3.new(1, dividerH, LANDING_Z - HOLE_MIN_Z),
		CFrame.new(0, bottom + dividerH / 2, (HOLE_MIN_Z + LANDING_Z) / 2),
		COLORS.darkConcrete
	)
	-- Roof hut cap and the railing in front of the open east lane on the roof.
	block(
		stairs,
		"HutRoof",
		Vector3.new(HOLE_X * 2 + 2, 1, wallLen + 2),
		CFrame.new(0, top + hutHeight + 0.5, wallZ - 1),
		COLORS.darkConcrete
	)
	block(
		stairs,
		"RoofLaneRail",
		Vector3.new(HOLE_X - 0.5, 4, 0.6),
		CFrame.new(LANE_CENTER, top + 2, HOLE_MIN_Z - 0.3),
		COLORS.rail,
		Enum.Material.Metal
	)

	for flight = 0, World.FloorCount - 1 do
		local upper = levelY(flight)
		local lower = levelY(flight + 1)
		local mid = upper - World.FloorSpacing / 2
		ramp(
			stairs,
			("Ramp%d_Down"):format(flight),
			Vector3.new(-LANE_CENTER, upper, HOLE_MIN_Z),
			Vector3.new(-LANE_CENTER, mid, LANDING_Z),
			LANE_WIDTH
		)
		block(
			stairs,
			("Landing%d"):format(flight),
			Vector3.new(HOLE_X * 2, 1, HOLE_MAX_Z - LANDING_Z),
			CFrame.new(0, mid - 0.5, (LANDING_Z + HOLE_MAX_Z) / 2),
			COLORS.metal,
			Enum.Material.DiamondPlate
		)
		ramp(
			stairs,
			("Ramp%d_Up"):format(flight),
			Vector3.new(LANE_CENTER, mid, LANDING_Z),
			Vector3.new(LANE_CENTER, lower, HOLE_MIN_Z),
			LANE_WIDTH
		)
		-- Floor number above each stairwell exit, so players always know where they are.
		local isBottom = flight + 1 == World.FloorCount
		sign(
			stairs,
			if isBottom then "sign.floor4" else "sign.floor",
			CFrame.new(0, lower + 13, HOLE_MIN_Z - 0.2),
			Vector2.new(10, 2),
			nil,
			if isBottom then nil else flight + 1
		)
	end
	sign(stairs, "sign.stairsDown", CFrame.new(-LANE_CENTER, top + 7, HOLE_MIN_Z - 0.2), Vector2.new(5.5, 1.5))
end

local function buildFloorShell(parent: Instance, level: number, lit: boolean)
	local floorY = levelY(level)
	local half = World.FloorSize / 2
	slab(parent, "Floor", World.FloorSize, floorY, level < World.FloorCount, COLORS.concrete)

	-- Outer walls: solid band, a band of unbreakable glass, solid band.
	local bands = {
		{ from = 0, to = 4, glass = false },
		{ from = 4, to = 14, glass = true },
		{ from = 14, to = WALL_HEIGHT, glass = false },
	}
	for _, band in bands do
		local h = band.to - band.from
		local y = floorY + band.from + h / 2
		local color = if band.glass then COLORS.glass else COLORS.darkConcrete
		local material = if band.glass then Enum.Material.Glass else Enum.Material.Concrete
		for _, side in { -1, 1 } do
			local px = block(
				parent,
				"OuterWall",
				Vector3.new(1, h, World.FloorSize),
				CFrame.new(side * (half + 0.5), y, 0),
				color,
				material
			)
			local pz = block(
				parent,
				"OuterWall",
				Vector3.new(World.FloorSize + 2, h, 1),
				CFrame.new(0, y, side * (half + 0.5)),
				color,
				material
			)
			if band.glass then
				px.Transparency = 0.55
				pz.Transparency = 0.55
			end
		end
	end

	-- Nature got in through the broken windows: grass in the cracks and ivy hanging from the ceiling.
	local green = Random.new(level * 101)
	for _ = 1, 4 + level * 2 do
		local x = green:NextNumber(-half + 4, half - 4)
		local z = green:NextNumber(-half + 4, half - 4)
		if math.abs(x) > HOLE_X + 3 or math.abs(z) > HOLE_MAX_Z + 3 then
			Scenery.Grass(
				parent,
				Vector3.new(x, floorY, z),
				Vector2.new(green:NextNumber(3, 7), green:NextNumber(3, 7)),
				green
			)
		end
	end
	for _ = 1, 3 + level do
		local side = green:NextInteger(1, 4)
		local along = green:NextNumber(-half + 5, half - 5)
		local inner = half - 0.2
		local top = floorY + WALL_HEIGHT - 0.2
		local pos, normal
		if side == 1 then
			pos, normal = Vector3.new(along, top, -inner), Vector3.new(0, 0, 1)
		elseif side == 2 then
			pos, normal = Vector3.new(along, top, inner), Vector3.new(0, 0, -1)
		elseif side == 3 then
			pos, normal = Vector3.new(-inner, top, along), Vector3.new(1, 0, 0)
		else
			pos, normal = Vector3.new(inner, top, along), Vector3.new(-1, 0, 0)
		end
		Scenery.Vine(parent, pos, green:NextNumber(5, 14), normal, green)
	end

	if lit then
		for _, pos in { Vector2.new(-22, -22), Vector2.new(22, -22), Vector2.new(-22, 22), Vector2.new(22, 22) } do
			local lamp = block(
				parent,
				"CeilingLamp",
				Vector3.new(3, 0.4, 1),
				CFrame.new(pos.X, floorY + WALL_HEIGHT - 0.3, pos.Y),
				Color3.fromRGB(255, 200, 140),
				Enum.Material.Neon
			)
			lamp.CanCollide = false
			pointLight(lamp, Color3.fromRGB(255, 190, 130), 26, 0.8, true)
		end
	end
end

local function nodeLook(itemId: string): (Vector3, Color3, Enum.Material, Enum.PartType)
	if itemId == "Scrap" then
		return Vector3.new(2.4, 1.6, 2.4), COLORS.rust, Enum.Material.CorrodedMetal, Enum.PartType.Block
	elseif itemId == "Electronics" then
		return Vector3.new(1.8, 1.2, 1.8), Color3.fromRGB(40, 160, 90), Enum.Material.Neon, Enum.PartType.Block
	elseif itemId == "Food" then
		return Vector3.new(1.4, 1.4, 1.4),
			Color3.fromRGB(230, 140, 40),
			Enum.Material.SmoothPlastic,
			Enum.PartType.Cylinder
	elseif itemId == "Medkit" then
		return Vector3.new(1.8, 1.2, 1.4),
			Color3.fromRGB(235, 235, 235),
			Enum.Material.SmoothPlastic,
			Enum.PartType.Block
	elseif itemId == "Cable" then
		return Vector3.new(1.2, 2.4, 2.4), Color3.fromRGB(25, 25, 25), Enum.Material.Rubber, Enum.PartType.Cylinder
	elseif itemId == "Motor" then
		return Vector3.new(2.2, 2, 2.2), Color3.fromRGB(60, 70, 85), Enum.Material.Metal, Enum.PartType.Block
	elseif itemId == "Flashlight" then
		return Vector3.new(0.8, 0.8, 1.8),
			Color3.fromRGB(240, 200, 40),
			Enum.Material.SmoothPlastic,
			Enum.PartType.Block
	end
	return Vector3.new(1.5, 1.5, 1.5), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, Enum.PartType.Block
end

type NodeOptions = {
	unique: boolean?,
	requiresUpgrade: string?,
	requiresRubble: string?,
}

local CRATE_LOOKS: { [string]: { body: Color3, trim: Color3, glow: boolean } } = {
	Common = { body = Color3.fromRGB(116, 84, 56), trim = Color3.fromRGB(90, 90, 90), glow = false },
	Rare = { body = Color3.fromRGB(52, 78, 120), trim = Color3.fromRGB(110, 170, 255), glow = false },
	Gold = { body = Color3.fromRGB(110, 80, 40), trim = Color3.fromRGB(255, 196, 60), glow = true },
	Diamond = { body = Color3.fromRGB(40, 60, 70), trim = Color3.fromRGB(110, 240, 255), glow = true },
}

-- Loot crate; the higher the tier, the brighter the trim. Opened per player, refilled on roof return.
local function lootCrate(
	parent: Instance,
	level: number,
	nodeId: string,
	tier: string,
	pos: Vector2,
	options: { requiresUpgrade: string?, requiresRubble: string? }?
)
	local x, z = pos.X, pos.Y
	local look = CRATE_LOOKS[tier]
	local crate = onFloor(parent, nodeId, level, x, z, Vector3.new(3.4, 2.2, 2.4), look.body, Enum.Material.WoodPlanks)
	if tier ~= "Common" then
		crate.Material = Enum.Material.Metal
	end
	crate:SetAttribute("InteractType", "LootChest")
	crate:SetAttribute("NodeId", nodeId)
	crate:SetAttribute("Tier", tier)
	if options then
		if options.requiresUpgrade then
			crate:SetAttribute("RequiresUpgrade", options.requiresUpgrade)
		end
		if options.requiresRubble then
			crate:SetAttribute("RequiresRubble", options.requiresRubble)
		end
	end
	local lid = block(
		crate,
		"Lid",
		Vector3.new(3.6, 0.5, 2.6),
		crate.CFrame * CFrame.new(0, 1.35, 0),
		look.body,
		crate.Material
	)
	lid.CanCollide = false
	for _, offset in { -1.2, 1.2 } do
		local band = block(
			crate,
			"Trim",
			Vector3.new(0.3, 2.35, 2.5),
			crate.CFrame * CFrame.new(offset, 0, 0),
			look.trim,
			if look.glow then Enum.Material.Neon else Enum.Material.Metal
		)
		band.CanCollide = false
	end
	if look.glow then
		pointLight(crate, look.trim, 12, 1.2, true)
	end
	addPrompt(crate, "prompt.open", "loot." .. tier, 0.6)
	return crate
end

local function resourceNode(
	parent: Instance,
	level: number,
	nodeId: string,
	itemId: string,
	amount: number,
	pos: Vector2,
	options: NodeOptions?
)
	local x, z = pos.X, pos.Y
	local size, color, material, shape = nodeLook(itemId)
	local part = onFloor(parent, nodeId, level, x, z, size, color, material)
	part.Shape = shape
	if shape == Enum.PartType.Cylinder then
		-- Cylinders lie along X; stand cans up, keep cable coils on their side.
		local y = levelY(level) + (if itemId == "Food" then size.X / 2 else size.Y / 2)
		part.CFrame = if itemId == "Food"
			then CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.pi / 2)
			else CFrame.new(x, y, z)
	end
	part:SetAttribute("InteractType", "Resource")
	part:SetAttribute("NodeId", nodeId)
	part:SetAttribute("ItemId", itemId)
	part:SetAttribute("Amount", amount)
	if options then
		if options.unique then
			part:SetAttribute("Unique", true)
		end
		if options.requiresUpgrade then
			part:SetAttribute("RequiresUpgrade", options.requiresUpgrade)
		end
		if options.requiresRubble then
			part:SetAttribute("RequiresRubble", options.requiresRubble)
		end
	end
	addPrompt(part, "prompt.collect", "prompt.itemAmount", 0.3, "@item." .. itemId .. ".name", amount)
	return part
end

type RubbleOptions = {
	requiresTool: string?,
	rewardItem: string?,
	requiresUpgrade: string?,
}

-- facing: +1 when players approach from -X, -1 when they approach from +X.
local function rubble(
	parent: Instance,
	level: number,
	rubbleId: string,
	cframe: CFrame,
	size: Vector3,
	facing: number,
	options: RubbleOptions?
)
	local floorY = levelY(level)
	local main = block(
		parent,
		rubbleId,
		size,
		cframe + Vector3.new(0, floorY + size.Y / 2, 0),
		COLORS.rubble,
		Enum.Material.Slate
	)
	main:SetAttribute("InteractType", "Rubble")
	main:SetAttribute("RubbleId", rubbleId)
	local needsTool = options and options.requiresTool
	if options then
		if options.requiresTool then
			main:SetAttribute("RequiresTool", options.requiresTool)
		end
		if options.rewardItem then
			main:SetAttribute("RewardItem", options.rewardItem)
		end
		if options.requiresUpgrade then
			main:SetAttribute("RequiresUpgrade", options.requiresUpgrade)
		end
	end
	-- A few loose chunks so it reads as a pile. They are children, so hiding the rubble hides them too.
	local rng = Random.new(#rubbleId * 7919)
	for i = 1, 5 do
		local chunk = block(
			main,
			"Chunk" .. i,
			Vector3.new(rng:NextNumber(1.5, 3), rng:NextNumber(1, 2.5), rng:NextNumber(1.5, 3)),
			main.CFrame
				* CFrame.new(rng:NextNumber(-1, 1), rng:NextNumber(-size.Y / 2, size.Y / 3), rng:NextNumber(-2, 2))
				* CFrame.Angles(rng:NextNumber(0, 1), rng:NextNumber(0, 3), rng:NextNumber(0, 1)),
			COLORS.rubble:Lerp(COLORS.darkConcrete, rng:NextNumber()),
			Enum.Material.Slate
		)
		chunk.CanCollide = false
	end
	if needsTool then
		sign(
			main,
			"sign.crowbar",
			main.CFrame * CFrame.new(-facing * (size.X / 2 + 0.2), 2, 0) * CFrame.Angles(0, facing * math.pi / 2, 0),
			Vector2.new(3, 1)
		)
	end
	addPrompt(main, if needsTool then "prompt.clearCrowbar" else "prompt.clear", "prompt.rubble", 1.2)
	return main
end

-- A small room in a corner with a doorway on its inner X side, blocked by rubble.
local function cornerRoom(
	parent: Instance,
	level: number,
	sx: number,
	sz: number,
	rubbleId: string,
	options: RubbleOptions?
)
	local half = World.FloorSize / 2
	local inner = 20
	local x = sx * inner
	local zNear = sz * inner
	local zFar = sz * half
	-- Wall facing the centre along X, with a 6-stud doorway.
	local doorFrom = sz * 25
	local doorTo = sz * 31
	wallBetween(parent, "RoomWall", level, x, zNear, x, doorFrom, WALL_HEIGHT)
	wallBetween(parent, "RoomWall", level, x, doorTo, x, zFar, WALL_HEIGHT)
	wallBetween(parent, "RoomWall", level, x, zNear, sx * half, zNear, WALL_HEIGHT)
	rubble(parent, level, rubbleId, CFrame.new(x, 0, sz * 28), Vector3.new(3, 10, 6.5), sx, options)
	-- Lintel over the doorway so the rubble is the only way in.
	block(
		parent,
		"Lintel",
		Vector3.new(1, WALL_HEIGHT - 10, 6),
		CFrame.new(x, levelY(level) + 10 + (WALL_HEIGHT - 10) / 2, sz * 28),
		COLORS.concrete
	)
end

local function crate(parent: Instance, level: number, x: number, z: number, size: number?)
	local s = size or 4
	onFloor(parent, "Crate", level, x, z, Vector3.new(s, s, s), COLORS.wood, Enum.Material.WoodPlanks)
end

local function pipe(parent: Instance, level: number, x: number, z: number, length: number, alongX: boolean)
	local y = levelY(level) + WALL_HEIGHT - 2
	local part =
		block(parent, "Pipe", Vector3.new(length, 1.6, 1.6), CFrame.new(x, y, z), COLORS.metal, Enum.Material.Metal)
	part.Shape = Enum.PartType.Cylinder
	if not alongX then
		part.CFrame = part.CFrame * CFrame.Angles(0, math.pi / 2, 0)
	end
	part.CanCollide = false
end

-- Random but sensible spots for items on a floor, rolled anew every server so nobody can learn the map.
-- Zones: "open" (anywhere walkable outside locked rooms), "toxic"/"safe" (east/west halves on floor 3),
-- "roomPP"/"roomNN" (inside the +x+z / -x-z corner rooms behind rubble).
local function makePlacer(level: number, floor: Folder, rooms: { string }): (zone: string) -> Vector2
	local rng = Random.new()
	local floorY = levelY(level)
	local edge = World.FloorSize / 2 - 4
	local taken: { Vector2 } = {}
	local boxes: { { center: Vector2, half: Vector2 } } = {}
	for _, d in floor:GetDescendants() do
		if d:IsA("BasePart") and d.CanCollide and d.Position.Y + d.Size.Y / 2 > floorY + 0.5 then
			local cf, size = d.CFrame, d.Size
			local ex = math.abs(cf.RightVector.X) * size.X
				+ math.abs(cf.UpVector.X) * size.Y
				+ math.abs(cf.LookVector.X) * size.Z
			local ez = math.abs(cf.RightVector.Z) * size.X
				+ math.abs(cf.UpVector.Z) * size.Y
				+ math.abs(cf.LookVector.Z) * size.Z
			table.insert(
				boxes,
				{ center = Vector2.new(d.Position.X, d.Position.Z), half = Vector2.new(ex / 2, ez / 2) }
			)
		end
	end

	local function inRoom(x: number, z: number, room: string): boolean
		local sx = if string.sub(room, 5, 5) == "P" then 1 else -1
		local sz = if string.sub(room, 6, 6) == "P" then 1 else -1
		return x * sx >= 21 and z * sz >= 21
	end

	local function fits(x: number, z: number, zone: string): boolean
		-- Keep the stairwell and its doorway clear.
		if math.abs(x) < HOLE_X + 3 and z > HOLE_MIN_Z - 6 and z < HOLE_MAX_Z + 3 then
			return false
		end
		if string.sub(zone, 1, 4) == "room" then
			if not inRoom(x, z, zone) or math.abs(x) > 32 or math.abs(z) > 32 then
				return false
			end
		else
			for _, room in rooms do
				if inRoom(x, z, room) then
					return false
				end
			end
			if zone == "toxic" and x < HOLE_X + 5 then
				return false
			elseif zone == "safe" and x > HOLE_X + 1 then
				return false
			end
		end
		for _, box in boxes do
			if math.abs(x - box.center.X) < box.half.X + 2.5 and math.abs(z - box.center.Y) < box.half.Y + 2.5 then
				return false
			end
		end
		for _, other in taken do
			if (other - Vector2.new(x, z)).Magnitude < 6 then
				return false
			end
		end
		return true
	end

	return function(zone: string): Vector2
		for _ = 1, 400 do
			local x = rng:NextNumber(-edge, edge)
			local z = rng:NextNumber(-edge, edge)
			if fits(x, z, zone) then
				local spot = Vector2.new(x, z)
				table.insert(taken, spot)
				return spot
			end
		end
		warn(("[WorldBuilder] no free spot for %s on floor %d"):format(zone, level))
		return Vector2.new(0, -30)
	end
end

local function buildFloor1(parent: Folder, interactables: Folder)
	local level = 1
	local floor = Instance.new("Folder")
	floor.Name = "Floor01_Technical"
	floor.Parent = parent
	buildFloorShell(floor, level, true)

	-- Two routes around the stairwell: a west corridor and an east hall.
	wallBetween(floor, "Wall", level, -20, -35, -20, -6, WALL_HEIGHT)
	wallBetween(floor, "Wall", level, -20, 6, -20, 35, WALL_HEIGHT)
	wallBetween(floor, "Wall", level, 12, -20, 35, -20, 10)
	cornerRoom(floor, level, 1, 1, "F1_Rubble", { rewardItem = "Crowbar" })
	for _, p in { { -28, -12 }, { 25, -30 }, { -30, 8 }, { 14, 25 } } do
		crate(floor, level, p[1], p[2])
	end
	pipe(floor, level, 0, -25, 60, true)
	pipe(floor, level, -28, 0, 60, false)

	-- Items land somewhere new every match.
	local at = makePlacer(level, floor, { "roomPP" })
	resourceNode(interactables, level, "F1_Scrap_1", "Scrap", 2, at("open"))
	resourceNode(interactables, level, "F1_Scrap_2", "Scrap", 1, at("open"))
	resourceNode(interactables, level, "F1_Scrap_3", "Scrap", 2, at("open"))
	resourceNode(interactables, level, "F1_Scrap_4", "Scrap", 1, at("open"))
	resourceNode(interactables, level, "F1_Scrap_5", "Scrap", 2, at("open"))
	resourceNode(interactables, level, "F1_Scrap_6", "Scrap", 1, at("open"))
	resourceNode(interactables, level, "F1_Elec_1", "Electronics", 1, at("open"))
	resourceNode(interactables, level, "F1_Elec_2", "Electronics", 2, at("roomPP"), { requiresRubble = "F1_Rubble" })
	resourceNode(interactables, level, "F1_Elec_3", "Electronics", 1, at("roomPP"), { requiresRubble = "F1_Rubble" })
	lootCrate(interactables, level, "F1_Crate_1", "Common", at("open"))
	lootCrate(interactables, level, "F1_Crate_2", "Common", at("open"))
end

local function buildFloor2(parent: Folder, interactables: Folder)
	local level = 2
	local floor = Instance.new("Folder")
	floor.Name = "Floor02_Residential"
	floor.Parent = parent
	buildFloorShell(floor, level, true)

	-- Apartment partitions with open doorways.
	wallBetween(floor, "Wall", level, -18, 10, -18, 24, WALL_HEIGHT)
	wallBetween(floor, "Wall", level, -35, 10, -26, 10, WALL_HEIGHT)
	wallBetween(floor, "Wall", level, 18, -35, 18, -24, WALL_HEIGHT)
	wallBetween(floor, "Wall", level, 18, -14, 18, -10, WALL_HEIGHT)
	wallBetween(floor, "Wall", level, 26, -10, 35, -10, WALL_HEIGHT)
	for _, p in { { -28, 18 }, { 28, -18 }, { -26, -28 } } do
		onFloor(floor, "Bed", level, p[1], p[2], Vector3.new(4, 1.5, 7), COLORS.fabric, Enum.Material.Fabric)
	end
	onFloor(floor, "Sofa", level, 12, 28, Vector3.new(8, 2.5, 3), COLORS.fabric, Enum.Material.Fabric)
	onFloor(floor, "Table", level, -10, -28, Vector3.new(5, 3, 3), COLORS.wood, Enum.Material.Wood)

	-- Items land somewhere new every match.
	local at = makePlacer(level, floor, {})
	resourceNode(interactables, level, "F2_Food_1", "Food", 1, at("open"))
	resourceNode(interactables, level, "F2_Food_2", "Food", 1, at("open"))
	resourceNode(interactables, level, "F2_Food_3", "Food", 1, at("open"))
	resourceNode(interactables, level, "F2_Food_4", "Food", 1, at("open"))
	resourceNode(interactables, level, "F2_Food_5", "Food", 1, at("open"))
	resourceNode(interactables, level, "F2_Medkit_1", "Medkit", 1, at("open"))
	resourceNode(interactables, level, "F2_Medkit_2", "Medkit", 1, at("open"))
	resourceNode(interactables, level, "F2_Scrap_1", "Scrap", 2, at("open"))
	resourceNode(interactables, level, "F2_Scrap_2", "Scrap", 1, at("open"))
	resourceNode(interactables, level, "F2_Scrap_3", "Scrap", 1, at("open"))
	resourceNode(interactables, level, "F2_Flashlight", "Flashlight", 1, at("open"), { unique = true })
	lootCrate(interactables, level, "F2_Crate_1", "Common", at("open"))
	lootCrate(interactables, level, "F2_Crate_2", "Common", at("open"))
	lootCrate(interactables, level, "F2_Crate_3", "Rare", at("open"))
end

local function buildFloor3(parent: Folder, interactables: Folder)
	local level = 3
	local floorY = levelY(level)
	local floor = Instance.new("Folder")
	floor.Name = "Floor03_Ventilation"
	floor.Parent = parent
	buildFloorShell(floor, level, false)

	-- Ventilation ducts on the ceiling and a few big fan boxes on the floor.
	pipe(floor, level, 20, -10, 30, false)
	pipe(floor, level, -20, 10, 30, false)
	for _, p in { { -26, -14 }, { 14, 12 }, { 26, -30 } } do
		onFloor(floor, "FanBox", level, p[1], p[2], Vector3.new(5, 4, 5), COLORS.metal, Enum.Material.Metal)
	end

	-- Toxic zone covers the east half; the stairwell and the west half stay safe for a retreat.
	local zoneMinX = HOLE_X + 3
	local half = World.FloorSize / 2
	local zoneSize = Vector3.new(half - zoneMinX, WALL_HEIGHT, World.FloorSize)
	local zone = block(
		floor,
		"ToxicZone",
		zoneSize,
		CFrame.new((zoneMinX + half) / 2, floorY + WALL_HEIGHT / 2, 0),
		COLORS.toxic,
		Enum.Material.SmoothPlastic
	)
	zone.Transparency = 0.88
	zone.CanCollide = false
	zone.CanQuery = false
	zone.CanTouch = false
	zone.CastShadow = false
	zone:SetAttribute("Hazard", "Toxic")
	local smoke = Instance.new("ParticleEmitter")
	smoke.Color = ColorSequence.new(COLORS.toxic)
	smoke.LightEmission = 0.3
	smoke.Size = NumberSequence.new(4, 8)
	smoke.Transparency = NumberSequence.new(0.6, 1)
	smoke.Rate = 12
	smoke.Lifetime = NumberRange.new(4, 6)
	smoke.Speed = NumberRange.new(0.5, 1.5)
	smoke.SpreadAngle = Vector2.new(180, 180)
	smoke.Parent = zone
	pointLight(zone, COLORS.toxic, 30, 0.4, true)
	-- Hazard stripes on the floor plus text signs, so danger is never shown by colour alone.
	local stripe = block(
		floor,
		"HazardStripe",
		Vector3.new(1, 0.1, World.FloorSize),
		CFrame.new(zoneMinX - 0.5, floorY + 0.05, 0),
		Color3.fromRGB(230, 200, 30),
		Enum.Material.SmoothPlastic
	)
	stripe.CanCollide = false
	for _, z in { -22, 0, 22 } do
		sign(
			floor,
			"sign.toxic",
			CFrame.new(zoneMinX - 0.4, floorY + 8, z) * CFrame.Angles(0, math.pi / 2, 0),
			Vector2.new(8, 2),
			Color3.fromRGB(140, 255, 90)
		)
	end

	-- Items land somewhere new every match.
	local at = makePlacer(level, floor, {})
	resourceNode(interactables, level, "F3_Elec_1", "Electronics", 2, at("toxic"))
	resourceNode(interactables, level, "F3_Elec_2", "Electronics", 2, at("toxic"))
	resourceNode(interactables, level, "F3_Elec_3", "Electronics", 2, at("toxic"))
	resourceNode(interactables, level, "F3_Elec_4", "Electronics", 1, at("safe"))
	resourceNode(interactables, level, "F3_Elec_5", "Electronics", 1, at("safe"))
	resourceNode(interactables, level, "F3_Scrap_1", "Scrap", 2, at("safe"))
	resourceNode(interactables, level, "F3_Scrap_2", "Scrap", 2, at("safe"))
	resourceNode(interactables, level, "F3_Scrap_3", "Scrap", 1, at("safe"))
	lootCrate(interactables, level, "F3_Crate_1", "Rare", at("safe"))
	lootCrate(interactables, level, "F3_Crate_2", "Gold", at("toxic"))
end

local function buildFloor4(parent: Folder, interactables: Folder)
	local level = 4
	local floorY = levelY(level)
	local floor = Instance.new("Folder")
	floor.Name = "Floor04_Rubble"
	floor.Parent = parent
	buildFloorShell(floor, level, false)

	-- Locked door at the stairwell exit; opens per player once their Generator is built.
	local gate = block(
		interactables,
		"Floor04_Gate",
		Vector3.new(HOLE_X * 2 + 2, 12, 1),
		CFrame.new(0, floorY + 6, HOLE_MIN_Z - 1),
		Color3.fromRGB(70, 60, 50),
		Enum.Material.CorrodedMetal
	)
	gate:SetAttribute("InteractType", "Gate")
	gate:SetAttribute("RequiresUpgrade", "Generator")
	gate:SetAttribute("UpgradeVisual", "Generator")
	gate:SetAttribute("VisualMode", "Hide")
	addPrompt(gate, "prompt.open", "prompt.gate")
	sign(gate, "sign.gate", gate.CFrame * CFrame.new(0, 3, 0.7) * CFrame.Angles(0, math.pi, 0), Vector2.new(10, 1.5))

	cornerRoom(floor, level, -1, -1, "F4_Rubble_A", { requiresTool = "Crowbar", requiresUpgrade = "Generator" })
	cornerRoom(floor, level, 1, 1, "F4_Rubble_B", { requiresTool = "Crowbar", requiresUpgrade = "Generator" })
	-- Loose debris that players walk around.
	local rng = Random.new(404)
	for _ = 1, 10 do
		local x = rng:NextNumber(-30, 30)
		local z = rng:NextNumber(-30, 30)
		if math.abs(x) > HOLE_X + 4 or math.abs(z) > 20 then
			local s = rng:NextNumber(2, 4)
			local chunk =
				onFloor(floor, "Debris", level, x, z, Vector3.new(s, s * 0.6, s), COLORS.rubble, Enum.Material.Slate)
			chunk.CFrame = chunk.CFrame * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0.2)
		end
	end
	-- Collapsed beam hanging through the ceiling.
	block(
		floor,
		"FallenBeam",
		Vector3.new(2, 2, 26),
		CFrame.new(-14, floorY + 8, 0) * CFrame.Angles(0.5, 0.3, 0),
		COLORS.rust,
		Enum.Material.CorrodedMetal
	).CanCollide =
		false

	local gen = { requiresUpgrade = "Generator" }
	-- Items land somewhere new every match.
	local at = makePlacer(level, floor, { "roomNN", "roomPP" })
	resourceNode(interactables, level, "F4_Cable_1", "Cable", 2, at("open"), gen)
	resourceNode(interactables, level, "F4_Cable_2", "Cable", 2, at("open"), gen)
	resourceNode(
		interactables,
		level,
		"F4_Motor_1",
		"Motor",
		1,
		at("roomNN"),
		{ requiresUpgrade = "Generator", requiresRubble = "F4_Rubble_A" }
	)
	resourceNode(
		interactables,
		level,
		"F4_Motor_2",
		"Motor",
		1,
		at("roomPP"),
		{ requiresUpgrade = "Generator", requiresRubble = "F4_Rubble_B" }
	)
	resourceNode(interactables, level, "F4_Scrap_1", "Scrap", 2, at("open"), gen)
	resourceNode(interactables, level, "F4_Scrap_2", "Scrap", 2, at("open"), gen)
	resourceNode(interactables, level, "F4_Scrap_3", "Scrap", 2, at("open"), gen)
	resourceNode(interactables, level, "F4_Scrap_4", "Scrap", 1, at("open"), gen)
	resourceNode(interactables, level, "F4_Elec_1", "Electronics", 2, at("open"), gen)
	resourceNode(interactables, level, "F4_Elec_2", "Electronics", 1, at("open"), gen)
	lootCrate(interactables, level, "F4_Crate_1", "Rare", at("open"), gen)
	lootCrate(interactables, level, "F4_Crate_2", "Gold", at("open"), gen)
	lootCrate(
		interactables,
		level,
		"F4_Crate_3",
		"Diamond",
		at("roomPP"),
		{ requiresUpgrade = "Generator", requiresRubble = "F4_Rubble_B" }
	)
end

-- Colour and material for Blender props, picked from the "<Prop>_<Part>_<Paint>" name suffix.
local PROP_PAINTS: { [string]: { color: Color3, material: Enum.Material } } = {
	Wood = { color = Color3.fromRGB(120, 80, 48), material = Enum.Material.WoodPlanks },
	Metal = { color = Color3.fromRGB(120, 124, 130), material = Enum.Material.Metal },
	Dark = { color = Color3.fromRGB(38, 40, 45), material = Enum.Material.Metal },
	Rust = { color = Color3.fromRGB(125, 65, 35), material = Enum.Material.CorrodedMetal },
	Yellow = { color = Color3.fromRGB(215, 160, 40), material = Enum.Material.Metal },
	Glow = { color = Color3.fromRGB(255, 150, 60), material = Enum.Material.Neon },
	Teal = { color = Color3.fromRGB(60, 130, 140), material = Enum.Material.Metal },
	Red = { color = Color3.fromRGB(180, 40, 35), material = Enum.Material.Metal },
}

-- Imported Blender models live in ReplicatedStorage.Models (see blender/README.md).
local function findPropModel(upgradeId: string): Instance?
	local models = ReplicatedStorage:FindFirstChild("Models")
	if not models then
		return nil
	end
	local found = models:FindFirstChild(upgradeId, true)
	if found and found:FindFirstChildWhichIsA("BasePart", true) then
		return found
	end
	return nil
end

-- Replaces the grey box with the Blender model when one has been imported.
-- The box stays as an invisible hitbox, so prompts and server checks do not change.
local function attachPropModel(visual: BasePart, upgradeId: string)
	local source = findPropModel(upgradeId)
	if not source then
		return
	end
	local model = Instance.new("Model")
	model.Name = upgradeId .. "_Model"
	for _, d in source:GetDescendants() do
		if d:IsA("BasePart") then
			local part = d:Clone()
			for _, child in part:GetChildren() do
				if not child:IsA("SpecialMesh") and not child:IsA("SurfaceAppearance") then
					child:Destroy()
				end
			end
			part.Anchored = true
			part.CanCollide = false
			part.CastShadow = true
			local paintName = string.match(d.Name, "_(%a+)$")
			local paint = paintName and PROP_PAINTS[paintName]
			if paint then
				part.Color = paint.color
				part.Material = paint.material
			end
			part:SetAttribute("UpgradeVisual", upgradeId)
			part:SetAttribute("VisualMode", "Show")
			part.Parent = model
		end
	end
	if not model:FindFirstChildWhichIsA("BasePart") then
		return
	end
	-- Fit the model into the hitbox footprint and stand it on the pad.
	local boxCFrame, boxSize = model:GetBoundingBox()
	local scale = math.min(visual.Size.X / boxSize.X, visual.Size.Y / boxSize.Y, visual.Size.Z / boxSize.Z)
	if scale > 0 and scale < math.huge then
		model.WorldPivot = boxCFrame
		model:ScaleTo(scale)
	end
	local _, fitted = model:GetBoundingBox()
	local bottom = visual.Position - Vector3.new(0, visual.Size.Y / 2, 0)
	model:PivotTo(CFrame.new(bottom + Vector3.new(0, fitted.Y / 2, 0)))
	model.Parent = visual
	visual.Transparency = 1
end

local function upgradePad(
	interactables: Folder,
	visuals: Folder,
	upgradeId: string,
	position: Vector3,
	visualSize: Vector3,
	visualColor: Color3
): (BasePart, BasePart)
	local pad = block(
		interactables,
		upgradeId .. "_Pad",
		Vector3.new(visualSize.X + 4, 0.4, visualSize.Z + 4),
		CFrame.new(position + Vector3.new(0, 0.2, 0)),
		Color3.fromRGB(60, 60, 64),
		Enum.Material.DiamondPlate
	)
	pad:SetAttribute("InteractType", "Upgrade")
	pad:SetAttribute("UpgradeId", upgradeId)
	addPrompt(pad, "prompt.build", "upgrade." .. upgradeId .. ".name", 0.5)

	local visual = block(
		visuals,
		upgradeId,
		visualSize,
		CFrame.new(position + Vector3.new(0, 0.4 + visualSize.Y / 2, 0)),
		visualColor,
		Enum.Material.Metal
	)
	visual:SetAttribute("UpgradeVisual", upgradeId)
	visual:SetAttribute("VisualMode", "Show")
	attachPropModel(visual, upgradeId)
	sign(
		visuals,
		"upgrade." .. upgradeId .. ".name",
		CFrame.new(position + Vector3.new(0, 0.4 + visualSize.Y + 1.5, 0)),
		Vector2.new(6, 1.2)
	)
	return pad, visual
end

local function buildRoof(parent: Folder, interactables: Folder)
	local roofY = World.RoofY
	local half = World.RoofSize / 2
	local roof = Instance.new("Folder")
	roof.Name = "RoofBase"
	roof.Parent = parent
	local visuals = Instance.new("Folder")
	visuals.Name = "UpgradeVisuals"
	visuals.Parent = roof

	slab(roof, "Roof", World.RoofSize, roofY, true, COLORS.roof)
	-- Railings on every edge, with a gap on the east side where the bridge starts.
	local railH = 4
	local gap = 5
	for _, side in { -1, 1 } do
		block(
			roof,
			"Railing",
			Vector3.new(World.RoofSize + 1, railH, 0.6),
			CFrame.new(0, roofY + railH / 2, side * half),
			COLORS.rail,
			Enum.Material.Metal
		)
	end
	block(
		roof,
		"Railing",
		Vector3.new(0.6, railH, World.RoofSize),
		CFrame.new(-half, roofY + railH / 2, 0),
		COLORS.rail,
		Enum.Material.Metal
	)
	local eastLen = half - gap
	for _, side in { -1, 1 } do
		block(
			roof,
			"Railing",
			Vector3.new(0.6, railH, eastLen),
			CFrame.new(half, roofY + railH / 2, side * (gap + eastLen / 2)),
			COLORS.rail,
			Enum.Material.Metal
		)
	end
	local barrier = block(
		visuals,
		"BridgeBarrier",
		Vector3.new(0.8, railH, gap * 2),
		CFrame.new(half, roofY + railH / 2, 0),
		Color3.fromRGB(200, 60, 40),
		Enum.Material.Metal
	)
	barrier:SetAttribute("UpgradeVisual", "Bridge")
	barrier:SetAttribute("VisualMode", "Hide")
	sign(
		visuals,
		"sign.bridgeBroken",
		CFrame.new(half - 0.5, roofY + railH + 1, 0) * CFrame.Angles(0, math.pi / 2, 0),
		Vector2.new(8, 1.5)
	)

	-- Spawn point and terminal.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "RoofSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(0, roofY + 0.5, -38)
	spawn.Color = Color3.fromRGB(70, 110, 160)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = roof

	-- Workbench for bandages and weapons.
	local bench = block(
		interactables,
		"Workbench",
		Vector3.new(6, 3, 3),
		CFrame.new(-26, roofY + 1.5, 14),
		COLORS.wood,
		Enum.Material.WoodPlanks
	)
	bench:SetAttribute("InteractType", "Workbench")
	block(
		bench,
		"Vice",
		Vector3.new(1, 1, 1.2),
		bench.CFrame * CFrame.new(2.2, 2, 0),
		COLORS.metal,
		Enum.Material.Metal
	).CanCollide =
		false
	block(
		bench,
		"Tools",
		Vector3.new(3, 0.3, 1.5),
		bench.CFrame * CFrame.new(-0.8, 1.65, 0.2),
		COLORS.rust,
		Enum.Material.CorrodedMetal
	).CanCollide =
		false
	sign(bench, "craft.title", bench.CFrame * CFrame.new(0, 3.2, -1.6), Vector2.new(5, 1.2))
	addPrompt(bench, "prompt.craft", "prompt.workbench")

	local terminal = block(
		interactables,
		"EmergencyTerminal",
		Vector3.new(3, 5, 1.5),
		CFrame.new(-10, roofY + 2.5, -30),
		Color3.fromRGB(50, 55, 60),
		Enum.Material.Metal
	)
	terminal:SetAttribute("InteractType", "Terminal")
	addPrompt(terminal, "prompt.read", "prompt.terminal")
	local screen = block(
		terminal,
		"Screen",
		Vector3.new(2.4, 1.6, 0.1),
		terminal.CFrame * CFrame.new(0, 1, -0.8),
		Color3.fromRGB(80, 220, 120),
		Enum.Material.Neon
	)
	screen.CanCollide = false
	pointLight(screen, Color3.fromRGB(80, 220, 120), 8, 1, true)

	-- Upgrade spots. The storage crate is also the storage interaction once built.
	local _, storageVisual = upgradePad(
		interactables,
		visuals,
		"StorageCrate",
		Vector3.new(-32, roofY, -15),
		Vector3.new(6, 4, 4),
		COLORS.wood
	)
	storageVisual.Parent = interactables
	storageVisual.Name = "StorageCrate"
	storageVisual:SetAttribute("InteractType", "Storage")
	addPrompt(storageVisual, "prompt.open", "ui.storage")
	upgradePad(
		interactables,
		visuals,
		"Generator",
		Vector3.new(32, roofY, -24),
		Vector3.new(6, 5, 4),
		Color3.fromRGB(180, 140, 40)
	)
	upgradePad(
		interactables,
		visuals,
		"AirFilter",
		Vector3.new(32, roofY, 18),
		Vector3.new(4, 7, 4),
		Color3.fromRGB(90, 130, 150)
	)
	upgradePad(
		interactables,
		visuals,
		"Bridge",
		Vector3.new(42, roofY, -12),
		Vector3.new(3, 3, 3),
		Color3.fromRGB(150, 150, 160)
	)

	-- Base lights: off until the player's Generator runs.
	for _, p in
		{
			Vector2.new(-40, -40),
			Vector2.new(40, -40),
			Vector2.new(-40, 40),
			Vector2.new(40, 40),
			Vector2.new(-20, 0),
			Vector2.new(20, 0),
		}
	do
		block(
			roof,
			"LampPost",
			Vector3.new(0.6, 9, 0.6),
			CFrame.new(p.X, roofY + 4.5, p.Y),
			COLORS.metal,
			Enum.Material.Metal
		)
		local bulb = block(
			roof,
			"LampBulb",
			Vector3.new(1.4, 1, 1.4),
			CFrame.new(p.X, roofY + 9.4, p.Y),
			Color3.fromRGB(90, 90, 80),
			Enum.Material.Glass
		)
		bulb.CanCollide = false
		bulb:SetAttribute("UpgradeLight", "Generator")
		pointLight(bulb, Color3.fromRGB(255, 220, 160), 34, 1.6, false)
	end

	-- Roof clutter that does not block walkways.
	local tank = block(
		roof,
		"WaterTank",
		Vector3.new(9, 10, 10),
		CFrame.new(-38, roofY + 4.5, 30) * CFrame.Angles(0, 0, math.pi / 2),
		COLORS.rust,
		Enum.Material.CorrodedMetal
	)
	tank.Shape = Enum.PartType.Cylinder
	for _, p in { { -20, 38 }, { 0, 40 }, { 20, 36 } } do
		onFloor(roof, "Vent", 0, p[1], p[2], Vector3.new(4, 3, 4), COLORS.metal, Enum.Material.Metal)
	end
	onFloor(roof, "Antenna", 0, 30, 44, Vector3.new(0.8, 25, 0.8), COLORS.metal, Enum.Material.Metal)

	-- Survivors' rooftop garden and plants creeping over the edges.
	local green = Random.new(396)
	for _, p in { { -42, -6 }, { -42, 12 }, { 10, 44 }, { -28, 42 } } do
		onFloor(roof, "Planter", 0, p[1], p[2], Vector3.new(6, 1.6, 6), COLORS.wood, Enum.Material.WoodPlanks)
		Scenery.Bush(roof, Vector3.new(p[1], roofY + 1.6, p[2]), 3.5, green)
	end
	Scenery.Tree(roof, Vector3.new(-44, roofY, -44), 16, green)
	Scenery.Tree(roof, Vector3.new(44, roofY, 44), 14, green)
	for _ = 1, 14 do
		local x = green:NextNumber(-46, 46)
		local z = green:NextNumber(-46, 46)
		-- Keep walkways, the stairwell and the build spots clear.
		if math.abs(x) > 12 and math.abs(z + 38) > 8 then
			Scenery.Grass(
				roof,
				Vector3.new(x, roofY, z),
				Vector2.new(green:NextNumber(4, 9), green:NextNumber(4, 9)),
				green
			)
		end
	end
	for _ = 1, 10 do
		local side = green:NextInteger(1, 4)
		local along = green:NextNumber(-45, 45)
		local edge = World.RoofSize / 2 + 0.4
		local pos, normal
		if side == 1 then
			pos, normal = Vector3.new(along, roofY, -edge), Vector3.new(0, 0, -1)
		elseif side == 2 then
			pos, normal = Vector3.new(along, roofY, edge), Vector3.new(0, 0, 1)
		elseif side == 3 then
			pos, normal = Vector3.new(-edge, roofY, along), Vector3.new(-1, 0, 0)
		else
			pos, normal = Vector3.new(edge, roofY, along), Vector3.new(1, 0, 0)
		end
		Scenery.Vine(roof, pos, green:NextNumber(8, 30), normal, green)
	end
end

local function buildNeighbor(parent: Folder)
	local roofY = World.RoofY
	local neighbor = Instance.new("Folder")
	neighbor.Name = "NeighborTower"
	neighbor.Parent = parent
	local cx = World.NeighborOffsetX
	local size = 60
	local bodyHeight = roofY - 20
	local bodyBottom = roofY - World.SlabThickness - bodyHeight
	block(
		neighbor,
		"TowerBody",
		Vector3.new(size, bodyHeight, size),
		CFrame.new(cx, bodyBottom + bodyHeight / 2, 0),
		COLORS.concrete
	).CastShadow =
		false
	Scenery.Dress(neighbor, Vector3.new(cx, bodyBottom, 0), size, size, bodyHeight, Random.new(150), false)
	local neighborGreen = Random.new(151)
	for _ = 1, 6 do
		Scenery.Grass(
			neighbor,
			Vector3.new(cx + neighborGreen:NextNumber(-24, 24), roofY, neighborGreen:NextNumber(-24, 24)),
			Vector2.new(neighborGreen:NextNumber(5, 10), neighborGreen:NextNumber(5, 10)),
			neighborGreen
		)
	end
	Scenery.Tree(neighbor, Vector3.new(cx + 18, roofY, 18), 15, neighborGreen)
	block(
		neighbor,
		"TowerRoof",
		Vector3.new(size, World.SlabThickness, size),
		CFrame.new(cx, roofY - World.SlabThickness / 2, 0),
		COLORS.roof
	)
	for _, side in { -1, 1 } do
		block(
			neighbor,
			"Railing",
			Vector3.new(size, 4, 0.6),
			CFrame.new(cx, roofY + 2, side * size / 2),
			COLORS.rail,
			Enum.Material.Metal
		)
	end
	block(
		neighbor,
		"Railing",
		Vector3.new(0.6, 4, size),
		CFrame.new(cx + size / 2, roofY + 2, 0),
		COLORS.rail,
		Enum.Material.Metal
	)
	sign(
		neighbor,
		"sign.tower2",
		CFrame.new(cx - size / 2 + 6, roofY + 9, 0) * CFrame.Angles(0, math.pi / 2, 0),
		Vector2.new(10, 3)
	)

	-- Broken bridge stubs on both towers; the full deck appears per player once built.
	local startX = World.RoofSize / 2
	local endX = cx - size / 2
	local length = endX - startX
	block(
		neighbor,
		"BridgeStub",
		Vector3.new(8, 1, 8),
		CFrame.new(startX + 4, roofY - 0.5, 0),
		COLORS.rust,
		Enum.Material.CorrodedMetal
	)
	block(
		neighbor,
		"BridgeStub",
		Vector3.new(8, 1, 8),
		CFrame.new(endX - 4, roofY - 0.5, 0),
		COLORS.rust,
		Enum.Material.CorrodedMetal
	)
	local deck = block(
		neighbor,
		"BridgeDeck",
		Vector3.new(length - 16, 1, 8),
		CFrame.new((startX + endX) / 2, roofY - 0.5, 0),
		COLORS.metal,
		Enum.Material.DiamondPlate
	)
	deck:SetAttribute("UpgradeVisual", "Bridge")
	deck:SetAttribute("VisualMode", "Show")
	for _, side in { -1, 1 } do
		local rail = block(
			deck,
			"DeckRail",
			Vector3.new(length - 16, 3, 0.5),
			deck.CFrame * CFrame.new(0, 2, side * 3.75),
			COLORS.rail,
			Enum.Material.Metal
		)
		rail:SetAttribute("UpgradeVisual", "Bridge")
		rail:SetAttribute("VisualMode", "Show")
	end

	local victory =
		block(neighbor, "VictoryZone", Vector3.new(size - 4, 12, size - 4), CFrame.new(cx, roofY + 6, 0), COLORS.toxic)
	victory.Transparency = 1
	victory.CanCollide = false
	victory.CanQuery = false
	victory.CanTouch = false

	-- Distant skyline: overgrown ruins all around, with a gap where the neighbour tower stands.
	Scenery.Skyline(neighbor, Vector3.zero, 16, 230, 420, 250, 470, 2026, { { Vector3.new(cx, 0, 0), 95 } })
end

local function collectRefs(root: Folder): WorldRefs
	local interactables = root:FindFirstChild("Interactables") :: Folder
	local roof = root:FindFirstChild("RoofBase") :: Folder
	local visuals = roof:FindFirstChild("UpgradeVisuals") :: Folder
	local neighbor = root:FindFirstChild("NeighborTower") :: Folder
	local toxicZones = {}
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("Hazard") == "Toxic" then
			table.insert(toxicZones, d)
		end
	end
	return {
		root = root,
		interactables = interactables,
		storagePart = interactables:FindFirstChild("StorageCrate") :: BasePart,
		generatorPart = visuals:FindFirstChild("Generator") :: BasePart,
		toxicZones = toxicZones,
		victoryZone = neighbor:FindFirstChild("VictoryZone") :: BasePart,
		roofDropPosition = Vector3.new(0, World.RoofY + 2, -28),
		workbench = interactables:FindFirstChild("Workbench") :: BasePart,
	}
end

-- Template places ship a SpawnLocation near the origin; players must only ever spawn on the roof.
local function disableOtherSpawns(root: Folder)
	for _, d in workspace:GetDescendants() do
		if d:IsA("SpawnLocation") and not d:IsDescendantOf(root) then
			d.Enabled = false
		end
	end
end

function WorldBuilder.Build(): WorldRefs
	local existing = workspace:FindFirstChild(World.FolderName)
	if existing and existing:IsA("Folder") then
		disableOtherSpawns(existing)
		return collectRefs(existing)
	end

	Atmosphere.Apply()
	local root = Instance.new("Folder")
	root.Name = World.FolderName
	local interactables = Instance.new("Folder")
	interactables.Name = "Interactables"
	interactables.Parent = root

	buildRoof(root, interactables)
	buildStairwell(root)
	buildFloor1(root, interactables)
	buildFloor2(root, interactables)
	buildFloor3(root, interactables)
	buildFloor4(root, interactables)
	buildNeighbor(root)

	-- Solid tower body under the bottom floor.
	local bottom = levelY(World.FloorCount) - World.SlabThickness
	local towerBody = block(
		root,
		"TowerBody",
		Vector3.new(World.FloorSize + 2, bottom, World.FloorSize + 2),
		CFrame.new(0, bottom / 2, 0),
		COLORS.concrete
	)
	towerBody.CastShadow = false
	Scenery.Dress(root, Vector3.zero, World.FloorSize + 2, World.FloorSize + 2, bottom, Random.new(1), false)

	root.Parent = workspace
	disableOtherSpawns(root)
	return collectRefs(root)
end

return WorldBuilder
