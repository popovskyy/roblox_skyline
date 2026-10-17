--!strict
-- Lightweight day/night cycle + rain. Does not fight Atmosphere.Apply's base grade; only nudges ClockTime
-- and toggles a rain particle emitter above the roof.

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local WeatherService = {}

local rainPart: BasePart? = nil
local emitter: ParticleEmitter? = nil
local raining = false
local cycleSeconds = 0
-- Full day loop ~12 real minutes (design: readable day→dusk→night→dawn).
local DAY_LENGTH = 720

local function ensureRain()
	if rainPart and rainPart.Parent then
		return
	end
	local world = workspace:FindFirstChild(GameConfig.World.FolderName)
	if not world then
		return
	end
	local part = Instance.new("Part")
	part.Name = "WeatherRain"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Transparency = 1
	part.Size = Vector3.new(GameConfig.World.FloorSize + 80, 1, GameConfig.World.FloorSize + 80)
	part.Position = Vector3.new(0, GameConfig.World.RoofY + 60, 0)
	part.Parent = world

	local pe = Instance.new("ParticleEmitter")
	pe.Name = "Rain"
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pe.Rate = 0
	pe.Lifetime = NumberRange.new(0.8, 1.2)
	pe.Speed = NumberRange.new(60, 90)
	pe.SpreadAngle = Vector2.new(4, 4)
	pe.Rotation = NumberRange.new(0, 0)
	pe.RotSpeed = NumberRange.new(0, 0)
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 0.05),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0.7),
	})
	pe.Color = ColorSequence.new(Color3.fromRGB(170, 180, 190))
	pe.Acceleration = Vector3.new(0, -40, 0)
	pe.LightEmission = 0
	pe.Enabled = true
	pe.Parent = part

	rainPart = part
	emitter = pe
end

local function setRain(on: boolean)
	raining = on
	ensureRain()
	if emitter then
		emitter.Rate = if on then 450 else 0
	end
end

function WeatherService.Start()
	ensureRain()
	-- Start mid-afternoon dry; rain only at dusk/night so tutorial plate stays readable.
	cycleSeconds = DAY_LENGTH * 0.35
	setRain(false)
	local lastBrightnessBucket = ""

	RunService.Heartbeat:Connect(function(dt)
		cycleSeconds = (cycleSeconds + dt) % DAY_LENGTH
		local t = cycleSeconds / DAY_LENGTH
		-- 0 = dawn (~6), 0.25 = noon, 0.5 = dusk, 0.75 = night
		local clock = (t * 24 + 6) % 24
		Lighting.ClockTime = clock

		local isNight = clock < 6 or clock > 19
		local isDusk = clock > 16 and clock < 20
		if isNight or isDusk then
			if not raining then
				setRain(true)
			end
		elseif clock > 8 and clock < 15 then
			if raining and math.noise(cycleSeconds * 0.01) > 0.35 then
				setRain(false)
			end
		end

		-- Only retarget Brightness when the day bucket changes — avoids fighting Atmosphere every frame.
		local bucket = if isNight then "night" elseif isDusk then "dusk" else "day"
		if bucket ~= lastBrightnessBucket then
			lastBrightnessBucket = bucket
			Lighting.Brightness = if isNight then 0.7 elseif isDusk then 1.2 else 1.6
			Lighting.ExposureCompensation = if isNight then -0.35 elseif isDusk then -0.2 else -0.15
		end
	end)
end

return WeatherService
