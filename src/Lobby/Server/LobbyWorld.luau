--!strict
-- Builds the lobby: a ruined plaza at the foot of the tower, four lifts, a leaderboard and a how-to-play board.
-- Text in the world carries a Locale key (TextKey attribute) so each client shows it in its own language.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Locale = require(ReplicatedStorage.Shared.Locale)
local PlacesConfig = require(ReplicatedStorage.Shared.PlacesConfig)

local LobbyWorld = {}

export type LiftRefs = { zone: BasePart, statusLabel: TextLabel }
export type Refs = {
	lifts: { [string]: LiftRefs },
	leaderboardRows: { TextLabel },
}

local COLORS = {
	ground = Color3.fromRGB(92, 88, 84),
	concrete = Color3.fromRGB(120, 116, 110),
	dark = Color3.fromRGB(45, 46, 52),
	metal = Color3.fromRGB(110, 115, 122),
	glow = Color3.fromRGB(255, 160, 70),
	rubble = Color3.fromRGB(100, 92, 84),
	silhouette = Color3.fromRGB(40, 42, 50),
}

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

local function textLabel(parent: Instance, key: string?, size: UDim2, position: UDim2, textSize: number?): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 225, 170)
	label.TextStrokeTransparency = 0.4
	label.TextWrapped = true
	if textSize then
		label.TextSize = textSize
	else
		label.TextScaled = true
	end
	if key then
		label.Text = Locale.T("en", key)
		label:SetAttribute("TextKey", key)
	else
		label.Text = ""
	end
	label.Parent = parent
	return label
end

local function board(parent: Instance, name: string, size: Vector2, cframe: CFrame): SurfaceGui
	local part = block(parent, name, Vector3.new(size.X, size.Y, 0.6), cframe, COLORS.dark, Enum.Material.Metal)
	local frame = block(
		parent,
		name .. "Frame",
		Vector3.new(size.X + 1, size.Y + 1, 0.4),
		cframe * CFrame.new(0, 0, 0.3),
		COLORS.metal,
		Enum.Material.Metal
	)
	frame.CanCollide = false
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0.2
	gui.Parent = part
	return gui
end

local function buildLift(parent: Instance, def: { id: string, capacity: number }, x: number, z: number): LiftRefs
	local folder = Instance.new("Folder")
	folder.Name = "Lift_" .. def.id
	folder.Parent = parent
	local solo = def.capacity == 1
	local accent = if solo then Color3.fromRGB(90, 200, 255) else COLORS.glow

	block(folder, "Floor", Vector3.new(10, 0.6, 10), CFrame.new(x, 0.3, z), COLORS.metal, Enum.Material.DiamondPlate)
	local edge = block(folder, "Edge", Vector3.new(10.4, 0.2, 10.4), CFrame.new(x, 0.05, z), accent, Enum.Material.Neon)
	edge.CanCollide = false
	-- Cabin: back and side walls, roof; the front faces the plaza.
	block(folder, "Back", Vector3.new(10, 12, 0.6), CFrame.new(x, 6, z + 5), COLORS.dark, Enum.Material.Metal)
	for _, side in { -1, 1 } do
		local wall = block(
			folder,
			"Side",
			Vector3.new(0.6, 12, 10),
			CFrame.new(x + side * 5, 6, z),
			COLORS.metal,
			Enum.Material.Glass
		)
		wall.Transparency = 0.5
	end
	block(folder, "Roof", Vector3.new(11, 0.8, 11), CFrame.new(x, 12.4, z), COLORS.dark, Enum.Material.Metal)
	local lamp = block(folder, "Lamp", Vector3.new(6, 0.2, 6), CFrame.new(x, 11.9, z), accent, Enum.Material.Neon)
	lamp.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = accent
	light.Range = 16
	light.Brightness = 1.5
	light.Parent = lamp
	-- Cables running up into the dark, so it reads as a lift shaft.
	for _, side in { -1, 1 } do
		local cable = block(
			folder,
			"Cable",
			Vector3.new(0.3, 60, 0.3),
			CFrame.new(x + side * 3, 42.8, z + 3),
			COLORS.dark,
			Enum.Material.Metal
		)
		cable.CanCollide = false
	end

	local zone = block(folder, "Zone", Vector3.new(9, 9, 9), CFrame.new(x, 5, z), accent)
	zone.Transparency = 1
	zone.CanCollide = false
	zone.CanQuery = false
	zone.CanTouch = false

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(260, 90)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 16, 0)
	billboard.LightInfluence = 0
	billboard.MaxDistance = 140
	billboard.Adornee = zone
	billboard.Parent = zone
	local title = textLabel(
		billboard,
		if solo then "lobby.liftSolo" else "lobby.liftGroup",
		UDim2.fromScale(1, 0.45),
		UDim2.new()
	)
	title.TextColor3 = accent
	local status = textLabel(billboard, nil, UDim2.fromScale(1, 0.55), UDim2.fromScale(0, 0.45))
	status.Font = Enum.Font.GothamBlack
	status.TextColor3 = Color3.new(1, 1, 1)
	return { zone = zone, statusLabel = status }
end

function LobbyWorld.Build(): Refs
	local root = Instance.new("Folder")
	root.Name = "LobbyWorld"

	-- Plaza and debris.
	block(root, "Ground", Vector3.new(240, 2, 240), CFrame.new(0, -1, 0), COLORS.ground, Enum.Material.Asphalt)
	block(root, "Plaza", Vector3.new(110, 0.4, 90), CFrame.new(0, 0.2, 5), COLORS.concrete, Enum.Material.Concrete)
	local rng = Random.new(77)
	for _ = 1, 26 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local dist = rng:NextNumber(62, 110)
		local s = rng:NextNumber(3, 9)
		local chunk = block(
			root,
			"Debris",
			Vector3.new(s, s * rng:NextNumber(0.4, 1), s * rng:NextNumber(0.6, 1.4)),
			CFrame.new(math.cos(angle) * dist, s * 0.3, math.sin(angle) * dist)
				* CFrame.Angles(0, rng:NextNumber(0, 3), rng:NextNumber(-0.3, 0.3)),
			COLORS.rubble,
			Enum.Material.Slate
		)
		chunk.CastShadow = true
	end

	-- The tower itself rises behind the lifts and disappears into the haze.
	block(root, "Tower", Vector3.new(130, 420, 40), CFrame.new(0, 210, 78), COLORS.silhouette, Enum.Material.Concrete)
	for i = 1, 30 do
		local window = block(
			root,
			"Window",
			Vector3.new(3, 4, 0.2),
			CFrame.new(rng:NextNumber(-60, 60), rng:NextNumber(20, 400), 57.9),
			COLORS.glow,
			Enum.Material.Neon
		)
		window.CanCollide = false
		window.Transparency = if i % 3 == 0 then 0 else 0.6
	end
	local skyline = Random.new(9)
	for i = 1, 12 do
		local angle = (i / 12) * math.pi * 2
		local dist = skyline:NextNumber(170, 260)
		local h = skyline:NextNumber(120, 320)
		local w = skyline:NextNumber(30, 60)
		block(
			root,
			"Skyline",
			Vector3.new(w, h, w),
			CFrame.new(math.cos(angle) * dist, h / 2, math.sin(angle) * dist),
			COLORS.silhouette
		).CastShadow =
			false
	end

	-- Lifts in a row in front of the tower: solo on the left, party lifts to the right.
	local lifts: { [string]: LiftRefs } = {}
	local count = #PlacesConfig.Lifts
	for i, def in PlacesConfig.Lifts do
		local x = (i - (count + 1) / 2) * 16
		lifts[def.id] = buildLift(root, def, x, 40)
	end

	-- Spawn facing the lifts.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(0, 0.5, -25)
	spawn.Color = Color3.fromRGB(70, 110, 160)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = root

	-- Title, hint, how to play, leaderboard.
	local titleGui = board(root, "TitleBoard", Vector2.new(40, 8), CFrame.new(0, 26, 57.5))
	textLabel(titleGui, "lobby.title", UDim2.fromScale(1, 0.62), UDim2.new()).Font = Enum.Font.GothamBlack
	textLabel(titleGui, "lobby.hint", UDim2.fromScale(1, 0.34), UDim2.fromScale(0, 0.64))

	local howGui =
		board(root, "HowToPlay", Vector2.new(16, 12), CFrame.new(46, 7, 0) * CFrame.Angles(0, math.pi / 2, 0))
	textLabel(howGui, "lobby.howTitle", UDim2.fromScale(1, 0.16), UDim2.fromScale(0, 0.02))
	local howBody = textLabel(howGui, "lobby.howBody", UDim2.fromScale(0.92, 0.78), UDim2.fromScale(0.04, 0.2))
	howBody.TextXAlignment = Enum.TextXAlignment.Left
	howBody.TextYAlignment = Enum.TextYAlignment.Top
	howBody.Font = Enum.Font.GothamMedium
	howBody.TextColor3 = Color3.fromRGB(235, 235, 235)

	local leadersGui =
		board(root, "Leaderboard", Vector2.new(16, 14), CFrame.new(-46, 8, 0) * CFrame.Angles(0, -math.pi / 2, 0))
	textLabel(leadersGui, "lobby.leaders", UDim2.fromScale(1, 0.13), UDim2.fromScale(0, 0.02))
	local rows = {}
	for i = 1, PlacesConfig.LeaderboardSize do
		local row =
			textLabel(leadersGui, nil, UDim2.fromScale(0.9, 0.08), UDim2.fromScale(0.05, 0.16 + (i - 1) * 0.083))
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Font = Enum.Font.GothamMedium
		row.TextColor3 = Color3.fromRGB(235, 235, 235)
		rows[i] = row
	end

	root.Parent = workspace
	return { lifts = lifts, leaderboardRows = rows }
end

return LobbyWorld
