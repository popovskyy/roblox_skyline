--!strict
-- Rain on this client: streaks falling around the camera and the sound of rain, only outdoors
-- (on the roofs). Indoors you hear it muffled. Driven by workspace's "Raining" attribute (WeatherService).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local WeatherController = {}

local player = Players.LocalPlayer
local RAIN_SOUND = "rbxassetid://9112853287"

local rainPart: Part
local emitter: ParticleEmitter
local sound: Sound

local function outdoors(): boolean
	local zone = player:GetAttribute("Zone")
	return zone == nil or zone == "Roof" or zone == "NeighborRoof" or zone == "Outside"
end

local function update()
	local raining = workspace:GetAttribute("Raining") == true
	local outside = outdoors()
	emitter.Enabled = raining and outside
	local volume = if not raining then 0 elseif outside then 0.45 else 0.12
	if volume > 0 and not sound.IsPlaying then
		sound.Volume = 0
		sound:Play()
	end
	TweenService:Create(sound, TweenInfo.new(3), { Volume = volume }):Play()
	if volume == 0 then
		task.delay(3.1, function()
			if workspace:GetAttribute("Raining") ~= true then
				sound:Stop()
			end
		end)
	end
end

function WeatherController.Start()
	rainPart = Instance.new("Part")
	rainPart.Name = "RainEmitter"
	rainPart.Size = Vector3.new(80, 1, 80)
	rainPart.Transparency = 1
	rainPart.Anchored = true
	rainPart.CanCollide = false
	rainPart.CanQuery = false
	rainPart.CanTouch = false
	rainPart.Parent = workspace

	emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(190, 200, 210))
	emitter.LightEmission = 0.1
	emitter.Transparency = NumberSequence.new(0.55)
	emitter.Size = NumberSequence.new(0.12)
	emitter.Squash = NumberSequence.new(-3) -- long thin streaks
	emitter.Orientation = Enum.ParticleOrientation.VelocityParallel
	emitter.EmissionDirection = Enum.NormalId.Bottom
	emitter.Speed = NumberRange.new(70, 90)
	emitter.Lifetime = NumberRange.new(0.8, 1)
	emitter.Rate = 900
	emitter.Enabled = false
	emitter.Parent = rainPart

	sound = Instance.new("Sound")
	sound.Name = "Rain"
	sound.SoundId = RAIN_SOUND
	sound.Looped = true
	sound.Volume = 0
	sound.Parent = SoundService

	-- Keep the rain cloud above the camera.
	RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		if camera and emitter.Enabled then
			rainPart.CFrame = CFrame.new(camera.CFrame.Position + Vector3.new(0, 30, 0))
		end
	end)
	workspace:GetAttributeChangedSignal("Raining"):Connect(update)
	player:GetAttributeChangedSignal("Zone"):Connect(update)
	update()
end

return WeatherController
