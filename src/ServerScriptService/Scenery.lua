--!strict
-- Post-apocalyptic set dressing shared by the lobby and the tower: ruined high-rises taken over by plants,
-- grass patches, bushes, trees and hanging vines. Plain Parts only, built once at server start.

local Scenery = {}

local PALETTE = {
	concrete = { Color3.fromRGB(130, 124, 112), Color3.fromRGB(110, 106, 98), Color3.fromRGB(96, 90, 84) },
	brick = Color3.fromRGB(122, 78, 58),
	window = Color3.fromRGB(28, 32, 36),
	lit = Color3.fromRGB(200, 150, 80),
	rust = Color3.fromRGB(124, 72, 44),
	moss = Color3.fromRGB(70, 82, 48),
	-- Desaturated foliage — post-apoc grey-green, not a summer park.
	leaf = { Color3.fromRGB(62, 78, 48), Color3.fromRGB(74, 86, 52), Color3.fromRGB(54, 68, 42) },
	grass = Color3.fromRGB(72, 84, 52),
	bark = Color3.fromRGB(70, 58, 46),
	ground = Color3.fromRGB(52, 50, 46),
}

local function part(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function pick<T>(rng: Random, list: { T }): T
	return list[rng:NextInteger(1, #list)]
end

-- Ivy hanging down a wall from `top`, `length` studs long, on a face whose outward normal is `normal`.
function Scenery.Vine(parent: Instance, top: Vector3, length: number, normal: Vector3, rng: Random)
	local width = rng:NextNumber(1.5, 4)
	local strand = part(
		parent,
		"Vine",
		Vector3.new(width, length, 0.3),
		CFrame.lookAt(top - Vector3.new(0, length / 2, 0) + normal * 0.25, top - Vector3.new(0, length / 2, 0) + normal),
		pick(rng, PALETTE.leaf),
		Enum.Material.Grass
	)
	strand.CanCollide = false
	strand.CastShadow = false
	return strand
end

-- Low patch of overgrown grass lying on a surface.
function Scenery.Grass(parent: Instance, center: Vector3, size: Vector2, rng: Random)
	local patch = part(
		parent,
		"Grass",
		Vector3.new(size.X, 0.25, size.Y),
		CFrame.new(center + Vector3.new(0, 0.125, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
		PALETTE.grass:Lerp(pick(rng, PALETTE.leaf), rng:NextNumber()),
		Enum.Material.Grass
	)
	patch.CanCollide = false
	patch.CastShadow = false
	return patch
end

function Scenery.Bush(parent: Instance, base: Vector3, size: number, rng: Random)
	for i = 1, 3 do
		local s = size * rng:NextNumber(0.6, 1)
		local ball = part(
			parent,
			"Bush",
			Vector3.new(s, s * 0.8, s),
			CFrame.new(
				base + Vector3.new(rng:NextNumber(-size, size) * 0.4, s * 0.35, rng:NextNumber(-size, size) * 0.4)
			),
			pick(rng, PALETTE.leaf),
			Enum.Material.Grass
		)
		ball.Shape = Enum.PartType.Ball
		ball.CanCollide = i == 1
	end
end

function Scenery.Tree(parent: Instance, base: Vector3, height: number, rng: Random)
	local trunk = part(
		parent,
		"Trunk",
		Vector3.new(height * 0.08, height * 0.6, height * 0.08),
		CFrame.new(base + Vector3.new(0, height * 0.3, 0))
			* CFrame.Angles(rng:NextNumber(-0.08, 0.08), 0, rng:NextNumber(-0.08, 0.08)),
		PALETTE.bark,
		Enum.Material.Wood
	)
	trunk.CastShadow = true
	for _ = 1, 4 do
		local s = height * rng:NextNumber(0.35, 0.5)
		local crown = part(
			parent,
			"Leaves",
			Vector3.new(s, s * 0.85, s),
			CFrame.new(
				base
					+ Vector3.new(
						rng:NextNumber(-1, 1) * s * 0.4,
						height * rng:NextNumber(0.62, 0.85),
						rng:NextNumber(-1, 1) * s * 0.4
					)
			),
			pick(rng, PALETTE.leaf),
			Enum.Material.Grass
		)
		crown.Shape = Enum.PartType.Ball
		crown.CanCollide = false
	end
end

-- A ruined high-rise: window bands, a few lit windows, a broken crown, rooftop junk and plants growing over it.
function Scenery.Building(parent: Instance, base: Vector3, width: number, depth: number, height: number, rng: Random)
	local model = Instance.new("Model")
	model.Name = "Ruin"
	model.Parent = parent
	-- Footing plate so the tower reads as grounded when looking down from the playable roof.
	local footing = part(
		model,
		"Ground",
		Vector3.new(width * 1.55, 6, depth * 1.55),
		CFrame.new(base + Vector3.new(0, -3, 0)),
		PALETTE.ground,
		Enum.Material.Asphalt
	)
	footing.CastShadow = false
	local body = part(
		model,
		"Body",
		Vector3.new(width, height, depth),
		CFrame.new(base + Vector3.new(0, height / 2, 0)),
		if rng:NextNumber() < 0.25 then PALETTE.brick else pick(rng, PALETTE.concrete),
		Enum.Material.Concrete
	)
	body.CastShadow = false
	Scenery.Dress(model, base, width, depth, height, rng, true)
	return model
end

-- Window bands, lit windows, ivy and (optionally) a broken crown with a green roof around an existing box
-- whose bottom centre is `base`. Used for skyline ruins and for the bodies of the two playable towers.
function Scenery.Dress(
	model: Instance,
	base: Vector3,
	width: number,
	depth: number,
	height: number,
	rng: Random,
	withCrown: boolean
)
	local bodyColor = pick(rng, PALETTE.concrete)
	-- Window bands wrap all four sides in one part each.
	local floorHeight = rng:NextNumber(10, 14)
	local y = 8
	while y < height - 10 do
		local band = part(
			model,
			"Windows",
			Vector3.new(width + 0.4, floorHeight * 0.45, depth + 0.4),
			CFrame.new(base + Vector3.new(0, y, 0)),
			PALETTE.window,
			Enum.Material.Glass
		)
		band.CastShadow = false
		y += floorHeight
	end
	for _ = 1, rng:NextInteger(3, 8) do
		local side = rng:NextInteger(0, 3)
		local h = rng:NextNumber(10, height - 12)
		local offset = rng:NextNumber(-0.4, 0.4)
		local pos, size
		if side < 2 then
			pos = Vector3.new(offset * width, h, (side * 2 - 1) * (depth / 2 + 0.25))
			size = Vector3.new(3, 3, 0.2)
		else
			pos = Vector3.new((side * 2 - 5) * (width / 2 + 0.25), h, offset * depth)
			size = Vector3.new(0.2, 3, 3)
		end
		local lit = part(model, "Lit", size, CFrame.new(base + pos), PALETTE.lit, Enum.Material.Neon)
		lit.CanCollide = false
		lit.CastShadow = false
	end

	-- Ivy down the walls.
	local normals = {
		{ Vector3.new(0, 0, -1), Vector3.new(0, 0, -depth / 2) },
		{ Vector3.new(0, 0, 1), Vector3.new(0, 0, depth / 2) },
		{ Vector3.new(-1, 0, 0), Vector3.new(-width / 2, 0, 0) },
		{ Vector3.new(1, 0, 0), Vector3.new(width / 2, 0, 0) },
	}
	for _ = 1, rng:NextInteger(3, 7) do
		local face = normals[rng:NextInteger(1, 4)]
		local along = Vector3.new(face[1].Z, 0, face[1].X) * rng:NextNumber(-0.4, 0.4) * math.max(width, depth)
		local length = rng:NextNumber(height * 0.15, height * 0.6)
		local startY = rng:NextNumber(length, height)
		Scenery.Vine(model, base + face[2] + along + Vector3.new(0, startY, 0) + face[1] * 0.3, length, face[1], rng)
	end
	if not withCrown then
		return
	end

	-- Broken crown: slabs knocked askew and a leaning rooftop tank.
	local top = base + Vector3.new(0, height, 0)
	for _ = 1, rng:NextInteger(2, 4) do
		local s =
			Vector3.new(width * rng:NextNumber(0.25, 0.5), rng:NextNumber(3, 8), depth * rng:NextNumber(0.25, 0.5))
		part(
			model,
			"Crown",
			s,
			CFrame.new(
				top + Vector3.new(rng:NextNumber(-0.3, 0.3) * width, s.Y / 2 - 1, rng:NextNumber(-0.3, 0.3) * depth)
			) * CFrame.Angles(rng:NextNumber(-0.2, 0.2), rng:NextNumber(0, 1), rng:NextNumber(-0.2, 0.2)),
			bodyColor:Lerp(Color3.new(0, 0, 0), 0.15),
			Enum.Material.Concrete
		).CastShadow =
			false
	end
	if rng:NextNumber() < 0.6 then
		local tank = part(
			model,
			"Tank",
			Vector3.new(8, 7, 7),
			CFrame.new(top + Vector3.new(rng:NextNumber(-0.3, 0.3) * width, 4.5, rng:NextNumber(-0.3, 0.3) * depth))
				* CFrame.Angles(0, 0, math.pi / 2 + rng:NextNumber(-0.15, 0.15)),
			PALETTE.rust,
			Enum.Material.CorrodedMetal
		)
		tank.Shape = Enum.PartType.Cylinder
		tank.CastShadow = false
	end

	-- Sparse moss / debris on the crown — not a full green roof.
	if rng:NextNumber() < 0.45 then
		Scenery.Grass(model, top, Vector2.new(width * 0.28, depth * 0.28), rng)
	end
	if rng:NextNumber() < 0.35 then
		part(
			model,
			"RoofJunk",
			Vector3.new(rng:NextNumber(4, 9), rng:NextNumber(2, 4), rng:NextNumber(3, 7)),
			CFrame.new(top + Vector3.new(rng:NextNumber(-0.2, 0.2) * width, 2, rng:NextNumber(-0.2, 0.2) * depth))
				* CFrame.Angles(0, rng:NextNumber(0, 1), rng:NextNumber(-0.1, 0.1)),
			PALETTE.rust,
			Enum.Material.CorrodedMetal
		).CastShadow = false
	end
end

-- A ring of ruins around `center`, skipping anything inside `keepClear` (a list of { center, radius }).
function Scenery.Skyline(
	parent: Instance,
	center: Vector3,
	count: number,
	minDistance: number,
	maxDistance: number,
	minHeight: number,
	maxHeight: number,
	seed: number,
	keepClear: { { Vector3 | number } }?
)
	local folder = Instance.new("Folder")
	folder.Name = "Skyline"
	folder.Parent = parent
	local rng = Random.new(seed)
	-- City ground disk under the ring so distant towers sit on something when viewed from above.
	local ground = part(
		folder,
		"CityGround",
		Vector3.new(maxDistance * 2.4, 8, maxDistance * 2.4),
		CFrame.new(center + Vector3.new(0, -4, 0)),
		PALETTE.ground,
		Enum.Material.Asphalt
	)
	ground.CastShadow = false
	for i = 1, count do
		local angle = (i / count) * math.pi * 2 + rng:NextNumber(-0.15, 0.15)
		local distance = rng:NextNumber(minDistance, maxDistance)
		local pos = center + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
		local clear = true
		if keepClear then
			for _, zone in keepClear do
				local zc = zone[1] :: Vector3
				local zr = zone[2] :: number
				if (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(zc.X, 0, zc.Z)).Magnitude < zr then
					clear = false
				end
			end
		end
		if clear then
			Scenery.Building(
				folder,
				pos,
				rng:NextNumber(36, 70),
				rng:NextNumber(36, 70),
				rng:NextNumber(minHeight, maxHeight),
				rng
			)
		end
	end
	return folder
end

return Scenery
