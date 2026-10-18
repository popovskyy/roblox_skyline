--!strict
-- How a hit feels (docs: POLISH_SPEC section 4), all on this client:
--  * you hit a zombie: it flashes white, a few sparks fly, a hit marker blinks in the centre, the camera
--    kicks a little (stronger on a kill, amber marker);
--  * a zombie hits you: the screen edge on that side flashes red with a wedge arrow pointing at it, and
--    the camera jolts.
-- Camera shake is skipped when the player turned on reduced motion in the Roblox settings.

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local Theme = require(ReplicatedStorage.Shared.Theme)
local UIKit = require(script.Parent.UIKit)

local HitFeedbackController = {}

local T = Theme.Colors

local marker: Frame
local edges: { [string]: Frame } = {}
local wedge: Frame

local function reducedMotion(): boolean
	local ok, value = pcall(function()
		return (GuiService :: any).ReducedMotionEnabled
	end)
	return ok and value == true
end

-- A short camera shake: random offsets that fade out over `seconds`.
local function shake(studs: number, seconds: number)
	if reducedMotion() then
		return
	end
	local name = "SkylineHitShake" .. tostring(os.clock())
	local started = os.clock()
	RunService:BindToRenderStep(name, Enum.RenderPriority.Camera.Value + 1, function()
		local t = os.clock() - started
		if t >= seconds then
			RunService:UnbindFromRenderStep(name)
			return
		end
		local s = studs * (1 - t / seconds)
		local camera = workspace.CurrentCamera
		camera.CFrame *= CFrame.new((math.random() - 0.5) * s, (math.random() - 0.5) * s, 0)
	end)
end

local function flash(model: Model, seconds: number)
	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.new(1, 1, 1)
	highlight.FillTransparency = 0.3
	highlight.OutlineTransparency = 1
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = model
	task.delay(seconds, function()
		highlight:Destroy()
	end)
end

local function sparks(at: Vector3)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.one * 0.2
	part.CFrame = CFrame.new(at + Vector3.new(0, 1, 0))
	part.Parent = workspace
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 236, 200))
	emitter.LightEmission = 1
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.15, 0.25)
	emitter.Speed = NumberRange.new(10, 18)
	emitter.SpreadAngle = Vector2.new(70, 70)
	emitter.Size = NumberSequence.new(0.35, 0)
	emitter.Parent = part
	emitter:Emit(8)
	task.delay(0.5, function()
		part:Destroy()
	end)
end

local markerToken = 0
local function showMarker(killed: boolean)
	markerToken += 1
	local token = markerToken
	local size = if killed then 28 else 22
	marker.Size = UDim2.fromOffset(size, size)
	for _, bar in marker:GetChildren() do
		if bar:IsA("Frame") then
			bar.BackgroundColor3 = if killed then T.Amber else T.Cream
			bar.BackgroundTransparency = 0
		end
	end
	marker.Visible = true
	task.delay(0.15, function()
		if markerToken == token then
			marker.Visible = false
		end
	end)
end

local function onHit(model: any, killed: boolean, at: any)
	if typeof(model) == "Instance" and model:IsA("Model") then
		flash(model, if killed then 0.12 else 0.08)
	end
	if typeof(at) == "Vector3" then
		sparks(at)
	end
	showMarker(killed == true)
	shake(if killed then 0.55 else 0.4, if killed then 0.2 else 0.12)
end

-- Which screen edge a world point is on, relative to where the camera looks.
local function sideOf(from: Vector3): (string, number)
	local camera = workspace.CurrentCamera
	local flat = Vector3.new(from.X - camera.CFrame.Position.X, 0, from.Z - camera.CFrame.Position.Z)
	local look = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
	if flat.Magnitude < 0.1 or look.Magnitude < 0.1 then
		return "bottom", 180
	end
	flat, look = flat.Unit, look.Unit
	local angle = math.deg(math.atan2(look:Cross(flat).Y, look:Dot(flat)))
	-- angle: 0 = in front, 90 = to the left, -90 = right, ±180 = behind.
	if math.abs(angle) <= 45 then
		return "top", 0
	elseif math.abs(angle) >= 135 then
		return "bottom", 180
	elseif angle > 0 then
		return "left", -90
	end
	return "right", 90
end

local function onHurt(from: any)
	if typeof(from) ~= "Vector3" then
		return
	end
	local side, rotation = sideOf(from)
	for name, edge in edges do
		local strong = name == side
		edge.Visible = true
		local gradient = edge:FindFirstChildOfClass("UIGradient")
		if gradient then
			gradient.Transparency = NumberSequence.new(if strong then 0.25 else 0.7, 1)
		end
		task.delay(0.35, function()
			edge.Visible = false
		end)
	end
	-- The wedge arrow sits on that side, pointing at the zombie.
	local positions = {
		top = UDim2.new(0.5, 0, 0, 60),
		bottom = UDim2.new(0.5, 0, 1, -60),
		left = UDim2.new(0, 60, 0.5, 0),
		right = UDim2.new(1, -60, 0.5, 0),
	}
	wedge.Position = positions[side]
	wedge.Rotation = rotation
	wedge.Visible = true
	wedge.BackgroundTransparency = 0
	TweenService:Create(wedge, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
	task.delay(0.36, function()
		wedge.Visible = false
	end)
	shake(0.5, 0.2)
end

function HitFeedbackController.Start(remotes: Folder)
	local screen = UIKit.FullScreen()
	-- Hit marker: four short bars around the centre.
	marker = UIKit.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(22, 22),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 20,
		Parent = screen,
	})
	for _, angle in { 45, 135, 225, 315 } do
		local rad = math.rad(angle)
		UIKit.New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5 + math.cos(rad) * 0.45, 0.5 + math.sin(rad) * 0.45),
			Size = UDim2.new(0.4, 0, 0, 3),
			Rotation = angle,
			BackgroundColor3 = T.Cream,
			BorderSizePixel = 0,
			ZIndex = 20,
			Parent = marker,
		})
	end
	-- Red edges (one per side) and the wedge.
	local specs = {
		top = { UDim2.fromScale(1, 0.25), UDim2.fromScale(0, 0), 90 },
		bottom = { UDim2.fromScale(1, 0.25), UDim2.fromScale(0, 0.75), -90 },
		left = { UDim2.fromScale(0.2, 1), UDim2.fromScale(0, 0), 0 },
		right = { UDim2.fromScale(0.2, 1), UDim2.fromScale(0.8, 0), 180 },
	}
	for name, spec in specs do
		local edge = UIKit.New("Frame", {
			Size = spec[1],
			Position = spec[2],
			BackgroundColor3 = T.Danger,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 4,
			Parent = screen,
		})
		UIKit.New("UIGradient", { Rotation = spec[3], Transparency = NumberSequence.new(0.5, 1), Parent = edge })
		edges[name] = edge
	end
	wedge = UIKit.New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(26, 36),
		BackgroundColor3 = T.Danger,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 21,
		Parent = screen,
	}, { UIKit.Corner(6) })

	local hit = remotes:WaitForChild(RemoteNames.HitFeedback) :: RemoteEvent
	hit.OnClientEvent:Connect(onHit)
	local hurt = remotes:WaitForChild(RemoteNames.Hurt) :: RemoteEvent
	hurt.OnClientEvent:Connect(onHurt)
end

return HitFeedbackController
