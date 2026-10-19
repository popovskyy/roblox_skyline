--!strict
-- Post-apocalyptic set dressing shared by the lobby and the tower: ruined high-rises taken over by plants,
-- grass patches, bushes, trees and hanging vines. Plain Parts only, built once at server start.

local Scenery = {}

local PALETTE = {
	concrete = { Color3.fromRGB(150, 142, 128), Color3.fromRGB(128, 122, 112), Color3.fromRGB(112, 104, 96) },
	brick = Color3.fromRGB(122, 78, 58),
	window = Color3.fromRGB(38, 44, 48),
	lit = Color3.fromRGB(255, 196, 120),
	rust = Color3.fromRGB(124, 72, 44),
	-- Muted, dusty greens and dry browns: overgrown but dying, not a botanical garden.
	moss = Color3.fromRGB(78, 86, 54),
	leaf = { Color3.fromRGB(74, 82, 50), Color3.fromRGB(92, 92, 58), Color3.fromRGB(96, 84, 56) },
	grass = Color3.fromRGB(104, 100, 68),
	bark = Color3.fromRGB(70, 56, 44),
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
		-- Warm window glow without plastic Neon (city silhouette only).
		local lit = part(model, "Lit", size, CFrame.new(base + pos), PALETTE.lit, Enum.Material.SmoothPlastic)
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

	-- Nature taking it back: a green roof.
	Scenery.Grass(model, top, Vector2.new(width * 0.8, depth * 0.8), rng)
	if rng:NextNumber() < 0.5 then
		Scenery.Tree(
			model,
			top + Vector3.new(rng:NextNumber(-0.25, 0.25) * width, 0, rng:NextNumber(-0.25, 0.25) * depth),
			rng:NextNumber(10, 18),
			rng
		)
	end
end

-- A ring of ruins around `center`, skipping anything inside `keepClear` (a list of { center, radius }).
-- The city floor far below: cracked asphalt with dark street lines, so the skyline stands on something
-- instead of floating in the haze.
function Scenery.Ground(parent: Instance, center: Vector3, size: number, rng: Random)
	local folder = Instance.new("Folder")
	folder.Name = "CityGround"
	folder.Parent = parent
	local ground = part(
		folder,
		"Ground",
		Vector3.new(size, 4, size),
		CFrame.new(center - Vector3.new(0, 2, 0)),
		Color3.fromRGB(58, 56, 52),
		Enum.Material.Asphalt
	)
	ground.CastShadow = false
	-- A street grid.
	local spacing = 120
	for i = -math.floor(size / spacing / 2), math.floor(size / spacing / 2) do
		for _, alongX in { true, false } do
			local offset = i * spacing + rng:NextNumber(-10, 10)
			local street = part(
				folder,
				"Street",
				if alongX then Vector3.new(size, 0.2, 18) else Vector3.new(18, 0.2, size),
				CFrame.new(center + (if alongX then Vector3.new(0, 0.1, offset) else Vector3.new(offset, 0.1, 0))),
				Color3.fromRGB(40, 40, 40),
				Enum.Material.Asphalt
			)
			street.CanCollide = false
			street.CastShadow = false
		end
	end
	-- Wrecks and rubble scattered along the streets.
	for _ = 1, 60 do
		local s = rng:NextNumber(4, 12)
		local chunk = part(
			folder,
			"Wreck",
			Vector3.new(s, s * rng:NextNumber(0.3, 0.7), s * rng:NextNumber(0.5, 1.6)),
			CFrame.new(
				center
					+ Vector3.new(
						rng:NextNumber(-size / 2.2, size / 2.2),
						s * 0.2,
						rng:NextNumber(-size / 2.2, size / 2.2)
					)
			) * CFrame.Angles(0, rng:NextNumber(0, 3), rng:NextNumber(-0.2, 0.2)),
			if rng:NextNumber() < 0.5 then PALETTE.rust else PALETTE.concrete[3],
			Enum.Material.CorrodedMetal
		)
		chunk.CanCollide = false
		chunk.CastShadow = false
	end
	return folder
end

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
