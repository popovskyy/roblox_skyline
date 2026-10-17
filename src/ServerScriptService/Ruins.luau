--!strict
-- Ruin details for the tower floors (The Last of Us / Days Gone look): broken ceiling edges with rebar,
-- the debris pile under a collapsed ceiling with dust and a shaft of light, shattered windows,
-- rubble heaps, puddles and cables hanging from the ceiling.
-- Everything is decoration: collision stays low and walkable, and holes are fenced by invisible walls.

local Ruins = {}

export type Rect = { minX: number, maxX: number, minZ: number, maxZ: number }

local CONCRETE = Color3.fromRGB(112, 108, 102)
local DARK = Color3.fromRGB(70, 67, 63)
local RUST = Color3.fromRGB(118, 70, 42)
local GLASS = Color3.fromRGB(150, 180, 190)
local WATER = Color3.fromRGB(32, 38, 40)

local function part(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	collide: boolean
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material
	p.CanCollide = collide
	p.CanQuery = collide
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function randomTilt(rng: Random, degrees: number): CFrame
	local r = math.rad(degrees)
	return CFrame.Angles(rng:NextNumber(-r, r), rng:NextNumber(0, math.pi * 2), rng:NextNumber(-r, r))
end

local function rebar(parent: Instance, from: Vector3, direction: Vector3, length: number)
	local bar = part(
		parent,
		"Rebar",
		Vector3.new(0.18, 0.18, length),
		CFrame.lookAt(from, from + direction) * CFrame.new(0, 0, -length / 2),
		RUST,
		Enum.Material.CorrodedMetal,
		false
	)
	bar.CastShadow = false
end

-- Rectangle `rect` of the slab whose top is at `topY` is gone. Fence it with invisible walls tall enough
-- that nobody falls through, and dress the edge with broken concrete and bent rebar.
function Ruins.HoleRim(parent: Instance, topY: number, thickness: number, rect: Rect, rng: Random)
	local folder = Instance.new("Folder")
	folder.Name = "CeilingHole"
	folder.Parent = parent
	local cx, cz = (rect.minX + rect.maxX) / 2, (rect.minZ + rect.maxZ) / 2
	local w, d = rect.maxX - rect.minX, rect.maxZ - rect.minZ
	local wallH = 14
	for _, side in { -1, 1 } do
		local x = part(
			folder,
			"HoleWall",
			Vector3.new(0.6, wallH, d + 1.2),
			CFrame.new(cx + side * (w / 2 + 0.3), topY + wallH / 2, cz),
			DARK,
			Enum.Material.SmoothPlastic,
			true
		)
		x.Transparency = 1
		x.CanQuery = false
		local z = part(
			folder,
			"HoleWall",
			Vector3.new(w + 1.2, wallH, 0.6),
			CFrame.new(cx, topY + wallH / 2, cz + side * (d / 2 + 0.3)),
			DARK,
			Enum.Material.SmoothPlastic,
			true
		)
		z.Transparency = 1
		z.CanQuery = false
	end
	-- Jagged lumps along every edge, partly hanging over the drop.
	local edges = {
		{
			a = Vector3.new(rect.minX, 0, rect.minZ),
			b = Vector3.new(rect.maxX, 0, rect.minZ),
			out = Vector3.new(0, 0, 1),
		},
		{
			a = Vector3.new(rect.minX, 0, rect.maxZ),
			b = Vector3.new(rect.maxX, 0, rect.maxZ),
			out = Vector3.new(0, 0, -1),
		},
		{
			a = Vector3.new(rect.minX, 0, rect.minZ),
			b = Vector3.new(rect.minX, 0, rect.maxZ),
			out = Vector3.new(1, 0, 0),
		},
		{
			a = Vector3.new(rect.maxX, 0, rect.minZ),
			b = Vector3.new(rect.maxX, 0, rect.maxZ),
			out = Vector3.new(-1, 0, 0),
		},
	}
	for _, edge in edges do
		local length = (edge.b - edge.a).Magnitude
		local count = math.max(2, math.floor(length / 2.2))
		for i = 1, count do
			local t = (i - 0.5) / count + rng:NextNumber(-0.08, 0.08)
			local at = edge.a:Lerp(edge.b, math.clamp(t, 0, 1)) + edge.out * rng:NextNumber(0.2, 1.1)
			local size = Vector3.new(rng:NextNumber(1, 2.4), thickness * rng:NextNumber(0.6, 1), rng:NextNumber(1, 2.2))
			local lump = part(
				folder,
				"BrokenEdge",
				size,
				CFrame.new(at.X, topY - size.Y / 2 - rng:NextNumber(0, 0.3), at.Z) * randomTilt(rng, 14),
				if rng:NextNumber() < 0.5 then CONCRETE else DARK,
				Enum.Material.Concrete,
				false
			)
			lump.CastShadow = true
			if rng:NextNumber() < 0.45 then
				local inward = -edge.out + Vector3.new(rng:NextNumber(-0.3, 0.3), rng:NextNumber(-0.6, -0.1), 0)
				rebar(folder, Vector3.new(at.X, topY - thickness / 2, at.Z), inward.Unit, rng:NextNumber(1.5, 3.2))
			end
		end
	end
end

-- What fell through the hole: tilted slab pieces, smaller rubble, dust drifting down and a shaft of light.
function Ruins.DebrisPile(parent: Instance, floorY: number, ceilingY: number, rect: Rect, rng: Random)
	local folder = Instance.new("Folder")
	folder.Name = "CollapsedCeiling"
	folder.Parent = parent
	local cx, cz = (rect.minX + rect.maxX) / 2, (rect.minZ + rect.maxZ) / 2
	local w, d = rect.maxX - rect.minX, rect.maxZ - rect.minZ
	-- Two or three big slab pieces leaning on each other, low enough to walk around.
	for i = 1, rng:NextInteger(2, 3) do
		local size = Vector3.new(w * rng:NextNumber(0.4, 0.6), 0.9, d * rng:NextNumber(0.4, 0.6))
		local offset = Vector3.new(rng:NextNumber(-w / 4, w / 4), 0, rng:NextNumber(-d / 4, d / 4))
		local tilt = CFrame.Angles(
			math.rad(rng:NextNumber(-22, 22)),
			math.rad(rng:NextNumber(0, 360)),
			math.rad(rng:NextNumber(10, 28))
		)
		local slabPart = part(
			folder,
			"FallenSlab",
			size,
			CFrame.new(cx + offset.X, floorY + 0.9 + i * 0.25, cz + offset.Z) * tilt,
			CONCRETE,
			Enum.Material.Concrete,
			true
		)
		slabPart.CanQuery = true
		rebar(
			folder,
			slabPart.Position,
			(slabPart.CFrame.RightVector + Vector3.new(0, 0.4, 0)).Unit,
			rng:NextNumber(1.5, 3)
		)
	end
	for _ = 1, 14 do
		local size = Vector3.new(rng:NextNumber(0.4, 1.3), rng:NextNumber(0.3, 0.9), rng:NextNumber(0.4, 1.3))
		local spread = Vector3.new(rng:NextNumber(-w * 0.75, w * 0.75), 0, rng:NextNumber(-d * 0.75, d * 0.75))
		part(
			folder,
			"Rubble",
			size,
			CFrame.new(cx + spread.X, floorY + size.Y / 2 - 0.1, cz + spread.Z) * randomTilt(rng, 25),
			if rng:NextNumber() < 0.6 then CONCRETE else DARK,
			Enum.Material.Concrete,
			false
		)
	end
	-- Dust and light falling from the floor above.
	local emitterPart = part(
		folder,
		"DustSource",
		Vector3.new(w, 0.2, d),
		CFrame.new(cx, ceilingY - 0.3, cz),
		CONCRETE,
		Enum.Material.SmoothPlastic,
		false
	)
	emitterPart.Transparency = 1
	emitterPart.CastShadow = false
	local dust = Instance.new("ParticleEmitter")
	dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
	dust.Color = ColorSequence.new(Color3.fromRGB(200, 190, 170))
	dust.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0.88),
		NumberSequenceKeypoint.new(1, 1),
	})
	dust.Size = NumberSequence.new(1.5, 3)
	dust.Rate = 3
	dust.Lifetime = NumberRange.new(5, 8)
	dust.Speed = NumberRange.new(1, 2)
	dust.EmissionDirection = Enum.NormalId.Bottom
	dust.LightInfluence = 1
	dust.Parent = emitterPart
	local shaft = Instance.new("SpotLight")
	shaft.Face = Enum.NormalId.Bottom
	shaft.Color = Color3.fromRGB(255, 214, 160)
	shaft.Angle = 70
	shaft.Range = 28
	shaft.Brightness = 1.6
	shaft.Shadows = false
	shaft.Parent = emitterPart
end

-- A window pane that is gone: the (invisible) glass still blocks the way out; shards stay in the frame
-- and glitter on the floor.
function Ruins.ShatteredPane(parent: Instance, pane: BasePart, floorY: number, inward: Vector3, rng: Random)
	pane.Transparency = 1
	pane.CastShadow = false
	local cf, size = pane.CFrame, pane.Size
	local along = if size.X > size.Z then cf.RightVector else cf.LookVector
	local length = math.max(size.X, size.Z)
	for _, edgeY in { size.Y / 2, -size.Y / 2 } do
		for _ = 1, rng:NextInteger(2, 4) do
			local h = rng:NextNumber(0.8, 3)
			local wedge = Instance.new("WedgePart")
			wedge.Name = "Shard"
			wedge.Anchored = true
			wedge.CanCollide = false
			wedge.CanQuery = false
			wedge.CanTouch = false
			wedge.CastShadow = false
			wedge.Size = Vector3.new(0.12, h, rng:NextNumber(0.8, 2.4))
			wedge.Color = GLASS
			wedge.Material = Enum.Material.Glass
			wedge.Transparency = 0.45
			local pos = cf.Position + along * rng:NextNumber(-length / 2 + 1, length / 2 - 1)
			local y = if edgeY > 0 then cf.Position.Y + edgeY - h / 2 else cf.Position.Y + edgeY + h / 2
			local facing = CFrame.lookAt(Vector3.new(pos.X, y, pos.Z), Vector3.new(pos.X, y, pos.Z) + along)
			-- Shards hang down from the top of the frame and stick up from the bottom.
			wedge.CFrame = facing * CFrame.Angles(0, math.pi / 2, if edgeY > 0 then math.pi else 0)
			wedge.Parent = parent
		end
	end
	for _ = 1, 6 do
		local bit = part(
			parent,
			"GlassBit",
			Vector3.new(rng:NextNumber(0.3, 0.9), 0.06, rng:NextNumber(0.3, 0.9)),
			CFrame.new(
				cf.Position.X + inward.X * rng:NextNumber(0.8, 3.5),
				floorY + 0.04,
				cf.Position.Z + inward.Z * rng:NextNumber(0.8, 3.5)
			)
				* CFrame.new(along * rng:NextNumber(-length / 2, length / 2))
				* CFrame.Angles(0, rng:NextNumber(0, 6.28), 0),
			GLASS,
			Enum.Material.Glass,
			false
		)
		bit.Transparency = 0.3
		bit.Reflectance = 0.2
		bit.CastShadow = false
	end
end

-- A low heap of broken concrete you can step over.
function Ruins.RubbleHeap(parent: Instance, floorY: number, pos: Vector2, rng: Random)
	local folder = Instance.new("Folder")
	folder.Name = "RubbleHeap"
	folder.Parent = parent
	for i = 1, rng:NextInteger(6, 10) do
		local size = Vector3.new(rng:NextNumber(0.5, 1.6), rng:NextNumber(0.3, 1), rng:NextNumber(0.5, 1.6))
		local r = rng:NextNumber(0, 2.2)
		local a = rng:NextNumber(0, math.pi * 2)
		part(
			folder,
			"Rubble",
			size,
			CFrame.new(
				pos.X + math.cos(a) * r,
				floorY + size.Y / 2 - 0.1 + (if r < 0.8 then 0.3 else 0),
				pos.Y + math.sin(a) * r
			) * randomTilt(rng, 25),
			if i % 3 == 0 then DARK else CONCRETE,
			Enum.Material.Concrete,
			false
		)
	end
	if rng:NextNumber() < 0.6 then
		rebar(
			folder,
			Vector3.new(pos.X, floorY + 0.4, pos.Y),
			Vector3.new(rng:NextNumber(-1, 1), 1.2, rng:NextNumber(-1, 1)).Unit,
			rng:NextNumber(1.5, 2.8)
		)
	end
end

-- Dark water collected on the floor.
function Ruins.Puddle(parent: Instance, floorY: number, pos: Vector2, rng: Random)
	local puddle = part(
		parent,
		"Puddle",
		Vector3.new(0.05, rng:NextNumber(3, 6), rng:NextNumber(3, 6)),
		CFrame.new(pos.X, floorY + 0.03, pos.Y) * CFrame.Angles(0, rng:NextNumber(0, 6.28), math.pi / 2),
		WATER,
		Enum.Material.Glass,
		false
	)
	puddle.Shape = Enum.PartType.Cylinder
	puddle.Reflectance = 0.25
	puddle.Transparency = 0.15
	puddle.CastShadow = false
end

-- A cable torn out of the ceiling, sagging down.
function Ruins.HangingCable(parent: Instance, ceilingY: number, pos: Vector2, rng: Random)
	local length = rng:NextNumber(4, 9)
	local top = Vector3.new(pos.X, ceilingY - 0.1, pos.Y)
	local bottom = top + Vector3.new(rng:NextNumber(-2, 2), -length, rng:NextNumber(-2, 2))
	local cable = part(
		parent,
		"HangingCable",
		Vector3.new(0.15, 0.15, (bottom - top).Magnitude),
		CFrame.lookAt((top + bottom) / 2, bottom),
		Color3.fromRGB(25, 25, 25),
		Enum.Material.Rubber,
		false
	)
	cable.CastShadow = false
end

-- Splits a slab into solid strips around rectangular holes (the stairwell and collapsed spots).
function Ruins.SlabStrips(half: number, holes: { Rect }): { Rect }
	local xs = { -half, half }
	local zs = { -half, half }
	for _, h in holes do
		table.insert(xs, math.clamp(h.minX, -half, half))
		table.insert(xs, math.clamp(h.maxX, -half, half))
		table.insert(zs, math.clamp(h.minZ, -half, half))
		table.insert(zs, math.clamp(h.maxZ, -half, half))
	end
	table.sort(xs)
	table.sort(zs)
	local function inHole(x: number, z: number): boolean
		for _, h in holes do
			if x > h.minX and x < h.maxX and z > h.minZ and z < h.maxZ then
				return true
			end
		end
		return false
	end
	local strips: { Rect } = {}
	for i = 1, #xs - 1 do
		local x0, x1 = xs[i], xs[i + 1]
		if x1 - x0 > 0.01 then
			local startZ: number? = nil
			for j = 1, #zs - 1 do
				local z0, z1 = zs[j], zs[j + 1]
				if z1 - z0 > 0.01 then
					local solid = not inHole((x0 + x1) / 2, (z0 + z1) / 2)
					if solid and not startZ then
						startZ = z0
					elseif not solid and startZ then
						table.insert(strips, { minX = x0, maxX = x1, minZ = startZ, maxZ = z0 })
						startZ = nil
					end
				end
			end
			if startZ then
				table.insert(strips, { minX = x0, maxX = x1, minZ = startZ, maxZ = half })
			end
		end
	end
	return strips
end

return Ruins
