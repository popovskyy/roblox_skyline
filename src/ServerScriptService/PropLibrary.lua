--!strict
-- Blender props in the game. Model assets uploaded through Open Cloud (scripts/upload_model.sh) are
-- loaded once at server start with InsertService; an imported RoofProps.rbxm in ReplicatedStorage.Models
-- works too. Every mesh is named "<Prop>_<Part>_<Paint>"; the paint picks colour and material.
-- If a prop is missing the world still builds, just without that prop.

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PropLibrary = {}

-- Uploaded model assets (see scripts/upload_model.sh).
local ASSETS: { [string]: number } = {
	InteriorProps = 76157686296384,
	Weapons = 126001413949023,
}

local PAINTS: { [string]: { color: Color3, material: Enum.Material } } = {
	Wood = { color = Color3.fromRGB(120, 80, 48), material = Enum.Material.WoodPlanks },
	Metal = { color = Color3.fromRGB(120, 124, 130), material = Enum.Material.Metal },
	Dark = { color = Color3.fromRGB(38, 40, 45), material = Enum.Material.Metal },
	Rust = { color = Color3.fromRGB(125, 65, 35), material = Enum.Material.CorrodedMetal },
	Yellow = { color = Color3.fromRGB(215, 160, 40), material = Enum.Material.Metal },
	Glow = { color = Color3.fromRGB(255, 150, 60), material = Enum.Material.Neon },
	Teal = { color = Color3.fromRGB(60, 120, 120), material = Enum.Material.Metal },
	Red = { color = Color3.fromRGB(170, 45, 38), material = Enum.Material.Metal },
	Fabric = { color = Color3.fromRGB(84, 90, 62), material = Enum.Material.Fabric },
	Cloth = { color = Color3.fromRGB(150, 138, 114), material = Enum.Material.Fabric },
	White = { color = Color3.fromRGB(196, 192, 178), material = Enum.Material.SmoothPlastic },
	Cardboard = { color = Color3.fromRGB(150, 112, 70), material = Enum.Material.Cardboard },
	Concrete = { color = Color3.fromRGB(128, 122, 112), material = Enum.Material.Concrete },
	Moss = { color = Color3.fromRGB(80, 104, 46), material = Enum.Material.Grass },
	Glass = { color = Color3.fromRGB(120, 140, 140), material = Enum.Material.Glass },
}

local library: Folder? = nil

-- Loads the uploaded assets into ReplicatedStorage.Models. Call before building the world.
function PropLibrary.Load()
	local models = ReplicatedStorage:FindFirstChild("Models")
	if not models then
		local folder = Instance.new("Folder")
		folder.Name = "Models"
		folder.Parent = ReplicatedStorage
		models = folder
	end
	for name, assetId in ASSETS do
		local ok, result = pcall(function()
			return InsertService:LoadAsset(assetId)
		end)
		if ok and result then
			result.Name = name
			result.Parent = models
		else
			warn(("[PropLibrary] could not load %s (%d): %s"):format(name, assetId, tostring(result)))
		end
	end
	library = models :: Folder
end

-- The meshes of one prop: either everything under a node named after it, or every part named "<Prop>_...".
local function partsOf(propName: string): { BasePart }
	local parts: { BasePart } = {}
	local root = library or ReplicatedStorage:FindFirstChild("Models")
	if not root then
		return parts
	end
	local node = root:FindFirstChild(propName, true)
	if node and not node:IsA("BasePart") then
		for _, d in node:GetDescendants() do
			if d:IsA("BasePart") then
				table.insert(parts, d)
			end
		end
		if #parts > 0 then
			return parts
		end
	end
	local prefix = propName .. "_"
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") and string.sub(d.Name, 1, #prefix) == prefix then
			table.insert(parts, d)
		end
	end
	return parts
end

function PropLibrary.Has(propName: string): boolean
	return #partsOf(propName) > 0
end

-- An unscaled, coloured copy of a prop's meshes (anchored, colliding unless told otherwise).
function PropLibrary.Raw(propName: string, collide: boolean?): Model?
	local sources = partsOf(propName)
	if #sources == 0 then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = propName
	for _, source in sources do
		local part = source:Clone()
		for _, child in part:GetChildren() do
			if not child:IsA("SpecialMesh") and not child:IsA("SurfaceAppearance") then
				child:Destroy()
			end
		end
		part.Anchored = true
		part.CanCollide = collide ~= false
		part.CastShadow = true
		local paintName = string.match(source.Name, "_(%a+)$")
		local paint = paintName and PAINTS[paintName]
		if paint then
			part.Color = paint.color
			part.Material = paint.material
			if paintName == "Glow" then
				part.CanCollide = false
			end
		end
		part.Parent = model
	end
	return model
end

-- Builds a coloured copy of a prop, scaled to fit inside `fit` (studs), standing with its bottom centre
-- at `base` and turned by `yaw` degrees. Returns nil when the prop is not available.
function PropLibrary.Place(
	parent: Instance,
	propName: string,
	base: Vector3,
	fit: Vector3,
	yaw: number?,
	collide: boolean?
): Model?
	local model = PropLibrary.Raw(propName, collide)
	if not model then
		return nil
	end
	local boxCFrame, boxSize = model:GetBoundingBox()
	local scale = math.min(fit.X / boxSize.X, fit.Y / boxSize.Y, fit.Z / boxSize.Z)
	if scale > 0 and scale < math.huge then
		model.WorldPivot = boxCFrame
		model:ScaleTo(scale)
	end
	local _, fitted = model:GetBoundingBox()
	model:PivotTo(CFrame.new(base + Vector3.new(0, fitted.Y / 2, 0)) * CFrame.Angles(0, math.rad(yaw or 0), 0))
	model.Parent = parent
	return model
end

-- Paint lookup for other builders (roof structures use the same names).
function PropLibrary.Paint(paintName: string): { color: Color3, material: Enum.Material }?
	return PAINTS[paintName]
end

return PropLibrary
