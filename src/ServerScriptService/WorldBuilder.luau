--!strict
-- Builds the grey-box prototype world from plain Parts into Workspace.GeneratedWorld.
-- Running it again reuses the existing folder instead of building a second copy.
--
-- Interactive parts live in GeneratedWorld.Interactables and carry an InteractType attribute.
-- Parts with UpgradeVisual = "<UpgradeId>" are shown ("Show") or hidden ("Hide") per player by the client.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local ItemDefinitions = require(ReplicatedStorage.Shared.ItemDefinitions)
local UpgradeDefinitions = require(ReplicatedStorage.Shared.UpgradeDefinitions)

local World = GameConfig.World

export type WorldRefs = {
	root: Folder,
	interactables: Folder,
	storagePart: BasePart,
	generatorPart: BasePart,
	toxicZones: { BasePart },
	victoryZone: BasePart,
	roofDropPosition: Vector3,
}

local WorldBuilder = {}

-- Stairwell footprint (hole in every slab except the bottom floor).
local HOLE_X = 6
local HOLE_MIN_Z = -15
local HOLE_MAX_Z = 15
local LANDING_Z = 9
local LANE_CENTER = 3.25
local LANE_WIDTH = 5.5
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

local function sign(parent: Instance, text: string, cframe: CFrame, size: Vector2, color: Color3?)
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
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = color or Color3.fromRGB(255, 220, 80)
	label.Text = text
	label.Parent = gui
end

local function addPrompt(part: BasePart, action: string, objectText: string, hold: number?)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = objectText
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
		local label = if flight + 1 == World.FloorCount
			then "4 ПОВЕРХ · РУЇНИ"
			else ("%d ПОВЕРХ"):format(flight + 1)
		sign(stairs, label, CFrame.new(0, lower + 13, HOLE_MIN_Z - 0.2), Vector2.new(10, 2))
	end
	sign(stairs, "СХОДИ ВНИЗ ↓", CFrame.new(-LANE_CENTER, top + 7, HOLE_MIN_Z - 0.2), Vector2.new(5.5, 1.5))
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

local function resourceNode(
	parent: Instance,
	level: number,
	nodeId: string,
	itemId: string,
	amount: number,
	x: number,
	z: number,
	options: NodeOptions?
)
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
	local def = ItemDefinitions.Items[itemId]
	addPrompt(part, "Зібрати", ("%s ×%d"):format(def.displayName, amount), 0.3)
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
			"ЛОМ",
			main.CFrame * CFrame.new(-facing * (size.X / 2 + 0.2), 2, 0) * CFrame.Angles(0, facing * math.pi / 2, 0),
			Vector2.new(3, 1)
		)
	end
	addPrompt(main, if needsTool then "Розібрати ломом" else "Розібрати", "Завал", 1.2)
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

	resourceNode(interactables, level, "F1_Scrap_1", "Scrap", 2, -28, -28)
	resourceNode(interactables, level, "F1_Scrap_2", "Scrap", 1, -28, 28)
	resourceNode(interactables, level, "F1_Scrap_3", "Scrap", 2, 25, -12)
	resourceNode(interactables, level, "F1_Scrap_4", "Scrap", 1, 10, -30)
	resourceNode(interactables, level, "F1_Scrap_5", "Scrap", 2, -12, 26)
	resourceNode(interactables, level, "F1_Scrap_6", "Scrap", 1, 30, 4)
	resourceNode(interactables, level, "F1_Elec_1", "Electronics", 1, -30, -2)
	resourceNode(interactables, level, "F1_Elec_2", "Electronics", 2, 30, 30, { requiresRubble = "F1_Rubble" })
	resourceNode(interactables, level, "F1_Elec_3", "Electronics", 1, 25, 33, { requiresRubble = "F1_Rubble" })
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

	resourceNode(interactables, level, "F2_Food_1", "Food", 1, -30, 30)
	resourceNode(interactables, level, "F2_Food_2", "Food", 1, -24, 14)
	resourceNode(interactables, level, "F2_Food_3", "Food", 1, 28, -28)
	resourceNode(interactables, level, "F2_Food_4", "Food", 1, 30, 25)
	resourceNode(interactables, level, "F2_Food_5", "Food", 1, -10, -24)
	resourceNode(interactables, level, "F2_Medkit_1", "Medkit", 1, 25, -22)
	resourceNode(interactables, level, "F2_Medkit_2", "Medkit", 1, -30, 22)
	resourceNode(interactables, level, "F2_Scrap_1", "Scrap", 2, 0, 30)
	resourceNode(interactables, level, "F2_Scrap_2", "Scrap", 1, -15, -30)
	resourceNode(interactables, level, "F2_Scrap_3", "Scrap", 1, 15, 22)
	resourceNode(interactables, level, "F2_Flashlight", "Flashlight", 1, 31, -31, { unique = true })
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
	local zoneMinX = 9
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
			"⚠ TOXIC AIR · ТОКСИЧНЕ ПОВІТРЯ",
			CFrame.new(zoneMinX - 0.4, floorY + 8, z) * CFrame.Angles(0, math.pi / 2, 0),
			Vector2.new(8, 2),
			Color3.fromRGB(140, 255, 90)
		)
	end

	resourceNode(interactables, level, "F3_Elec_1", "Electronics", 2, 20, -25)
	resourceNode(interactables, level, "F3_Elec_2", "Electronics", 2, 28, 0)
	resourceNode(interactables, level, "F3_Elec_3", "Electronics", 2, 20, 26)
	resourceNode(interactables, level, "F3_Elec_4", "Electronics", 1, -25, -26)
	resourceNode(interactables, level, "F3_Elec_5", "Electronics", 1, -28, 25)
	resourceNode(interactables, level, "F3_Scrap_1", "Scrap", 2, -15, -30)
	resourceNode(interactables, level, "F3_Scrap_2", "Scrap", 2, -30, 0)
	resourceNode(interactables, level, "F3_Scrap_3", "Scrap", 1, -10, 28)
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
	addPrompt(gate, "Відчинити", "Двері на 4 поверх")
	sign(
		gate,
		"ПОТРІБНЕ ЖИВЛЕННЯ · ГЕНЕРАТОР",
		gate.CFrame * CFrame.new(0, 3, 0.7) * CFrame.Angles(0, math.pi, 0),
		Vector2.new(10, 1.5)
	)

	cornerRoom(floor, level, -1, -1, "F4_Rubble_A", { requiresTool = "Crowbar", requiresUpgrade = "Generator" })
	cornerRoom(floor, level, 1, 1, "F4_Rubble_B", { requiresTool = "Crowbar", requiresUpgrade = "Generator" })
	-- Loose debris that players walk around.
	local rng = Random.new(404)
	for _ = 1, 10 do
		local x = rng:NextNumber(-30, 30)
		local z = rng:NextNumber(-30, 30)
		if math.abs(x) > 10 or math.abs(z) > 20 then
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
	resourceNode(interactables, level, "F4_Cable_1", "Cable", 2, -28, 22, gen)
	resourceNode(interactables, level, "F4_Cable_2", "Cable", 2, 28, -24, gen)
	resourceNode(
		interactables,
		level,
		"F4_Motor_1",
		"Motor",
		1,
		-30,
		-30,
		{ requiresUpgrade = "Generator", requiresRubble = "F4_Rubble_A" }
	)
	resourceNode(
		interactables,
		level,
		"F4_Motor_2",
		"Motor",
		1,
		30,
		30,
		{ requiresUpgrade = "Generator", requiresRubble = "F4_Rubble_B" }
	)
	resourceNode(interactables, level, "F4_Scrap_1", "Scrap", 2, 0, -30, gen)
	resourceNode(interactables, level, "F4_Scrap_2", "Scrap", 2, -12, 30, gen)
	resourceNode(interactables, level, "F4_Scrap_3", "Scrap", 2, 30, 0, gen)
	resourceNode(interactables, level, "F4_Scrap_4", "Scrap", 1, -30, 2, gen)
	resourceNode(interactables, level, "F4_Elec_1", "Electronics", 2, 15, -30, gen)
	resourceNode(interactables, level, "F4_Elec_2", "Electronics", 1, -16, 14, gen)
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
	local def = UpgradeDefinitions.Upgrades[upgradeId]
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
	addPrompt(pad, "Збудувати", def.displayName, 0.5)

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
		def.displayName,
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
		"МІСТ ЗРУЙНОВАНО",
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

	-- Translucent windbreak around the spawn and a hologram title above it.
	local glassColor = Color3.fromRGB(170, 210, 230)
	for _, panel in
		{
			{ CFrame.new(-6, roofY + 3.5, -44), Vector3.new(8, 7, 0.4) },
			{ CFrame.new(6, roofY + 3.5, -44), Vector3.new(8, 7, 0.4) },
			{ CFrame.new(-10.5, roofY + 3.5, -39) * CFrame.Angles(0, math.rad(70), 0), Vector3.new(8, 7, 0.4) },
			{ CFrame.new(10.5, roofY + 3.5, -39) * CFrame.Angles(0, math.rad(-70), 0), Vector3.new(8, 7, 0.4) },
		}
	do
		local glass = block(roof, "Windbreak", panel[2], panel[1], glassColor, Enum.Material.Glass)
		glass.Transparency = 0.6
		glass.CastShadow = false
		block(
			roof,
			"WindbreakFrame",
			Vector3.new(panel[2].X, 0.4, 0.6),
			panel[1] * CFrame.new(0, 3.5, 0),
			COLORS.metal,
			Enum.Material.Metal
		)
	end

	local holo = block(
		roof,
		"HoloTitle",
		Vector3.new(14, 3.5, 0.1),
		CFrame.new(0, roofY + 9, -42),
		Color3.fromRGB(90, 200, 255),
		Enum.Material.ForceField
	)
	holo.Transparency = 0.5
	holo.CanCollide = false
	holo.CastShadow = false
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.LightInfluence = 0
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.Parent = holo
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.Font = Enum.Font.GothamBlack
		label.TextColor3 = Color3.fromRGB(150, 230, 255)
		label.TextTransparency = 0.15
		label.Text = "SKYLINE ZERO"
		label.Parent = gui
	end
	pointLight(holo, Color3.fromRGB(90, 200, 255), 16, 1, true)

	-- Hologram markers floating over each build spot so new players see where to go.
	for _, marker in
		{ Vector3.new(-32, 0, -15), Vector3.new(32, 0, -24), Vector3.new(32, 0, 18), Vector3.new(42, 0, -12) }
	do
		local ring = block(
			roof,
			"HoloMarker",
			Vector3.new(0.2, 9, 9),
			CFrame.new(marker.X, roofY + 0.3, marker.Z) * CFrame.Angles(0, 0, math.pi / 2),
			Color3.fromRGB(90, 200, 255),
			Enum.Material.ForceField
		)
		ring.Shape = Enum.PartType.Cylinder
		ring.Transparency = 0.4
		ring.CanCollide = false
		ring.CastShadow = false
	end

	local terminal = block(
		interactables,
		"EmergencyTerminal",
		Vector3.new(3, 5, 1.5),
		CFrame.new(-10, roofY + 2.5, -30),
		Color3.fromRGB(50, 55, 60),
		Enum.Material.Metal
	)
	terminal:SetAttribute("InteractType", "Terminal")
	addPrompt(terminal, "Прочитати", "Аварійний термінал")
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
	addPrompt(storageVisual, "Відкрити", "Сховище")
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
end

local function buildNeighbor(parent: Folder)
	local roofY = World.RoofY
	local neighbor = Instance.new("Folder")
	neighbor.Name = "NeighborTower"
	neighbor.Parent = parent
	local cx = World.NeighborOffsetX
	local size = 60
	local bodyHeight = roofY - 20
	block(
		neighbor,
		"TowerBody",
		Vector3.new(size, bodyHeight, size),
		CFrame.new(cx, roofY - World.SlabThickness - bodyHeight / 2, 0),
		COLORS.silhouette
	)
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
		"ВЕЖА 2",
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

	-- Distant skyline so the roof does not float in an empty sky.
	local rng = Random.new(2026)
	for i = 1, 14 do
		local angle = (i / 14) * math.pi * 2
		local dist = rng:NextNumber(230, 420)
		local h = rng:NextNumber(250, 480)
		local w = rng:NextNumber(40, 80)
		local x = math.cos(angle) * dist
		local z = math.sin(angle) * dist
		if math.abs(x - cx) > 60 or math.abs(z) > 60 then
			local building =
				block(neighbor, "Skyline", Vector3.new(w, h, w), CFrame.new(x, h / 2, z), COLORS.silhouette)
			building.CastShadow = false
			-- Every third ruin is still burning: a glowing top and a column of smoke.
			if i % 3 == 0 then
				local fire = block(
					building,
					"Fire",
					Vector3.new(w * 0.6, 2, w * 0.6),
					CFrame.new(x, h + 1, z),
					Color3.fromRGB(255, 110, 30),
					Enum.Material.Neon
				)
				fire.CanCollide = false
				local smoke = Instance.new("ParticleEmitter")
				smoke.Color = ColorSequence.new(Color3.fromRGB(60, 45, 40))
				smoke.Size = NumberSequence.new(14, 40)
				smoke.Transparency = NumberSequence.new(0.3, 1)
				smoke.Lifetime = NumberRange.new(10, 14)
				smoke.Rate = 4
				smoke.Speed = NumberRange.new(10, 16)
				smoke.Acceleration = Vector3.new(6, 0, 0)
				smoke.EmissionDirection = Enum.NormalId.Top
				smoke.Parent = fire
			end
		end
	end
end

-- Apocalyptic sunset: low orange sun, thick rust-coloured haze, warm colour grading.
local function setupLighting()
	Lighting.ClockTime = 17.6
	Lighting.GeographicLatitude = 20
	Lighting.Brightness = 1.8
	Lighting.Ambient = Color3.fromRGB(30, 24, 22)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 95, 65)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 150, 80)
	Lighting.EnvironmentDiffuseScale = 0.3
	Lighting.EnvironmentSpecularScale = 0.3
	Lighting.GlobalShadows = true

	-- Replace whatever the template place shipped with.
	for _, child in Lighting:GetChildren() do
		if child:IsA("Atmosphere") or child:IsA("Sky") or child:IsA("PostEffect") then
			child:Destroy()
		end
	end

	local sky = Instance.new("Sky")
	sky.SunAngularSize = 18
	sky.MoonAngularSize = 0
	sky.StarCount = 0
	sky.Parent = Lighting

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.42
	atmosphere.Offset = 0.15
	atmosphere.Haze = 2.6
	atmosphere.Glare = 0.6
	atmosphere.Color = Color3.fromRGB(255, 140, 60)
	atmosphere.Decay = Color3.fromRGB(140, 55, 25)
	atmosphere.Parent = Lighting

	local grading = Instance.new("ColorCorrectionEffect")
	grading.TintColor = Color3.fromRGB(255, 225, 200)
	grading.Saturation = -0.1
	grading.Contrast = 0.12
	grading.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.6
	bloom.Size = 30
	bloom.Threshold = 1.6
	bloom.Parent = Lighting
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

	setupLighting()
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
		COLORS.silhouette
	)
	towerBody.CastShadow = false

	root.Parent = workspace
	disableOtherSpawns(root)
	return collectRefs(root)
end

return WorldBuilder
