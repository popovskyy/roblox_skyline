--!strict
-- Shared look of both places (lobby and tower): 99 Nights dread translated to the tower —
-- dark floors, cold fog, sparse warm pools; roof keeps a little outdoor breath.
-- HordeThreat: denser fog + orange dusk crush + emergency lamp flicker (HordeService).

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Atmosphere = {}

-- Dark floors (Ambient); roof/outdoors a touch brighter (OutdoorAmbient). Not sunny Studio default.
local BASE = {
	ClockTime = 17.4,
	Brightness = 1.15,
	ExposureCompensation = -0.35,
	Ambient = Color3.fromRGB(22, 24, 28),
	OutdoorAmbient = Color3.fromRGB(58, 56, 62),
	ColorShift_Top = Color3.fromRGB(160, 150, 140),
	ColorShift_Bottom = Color3.fromRGB(28, 30, 34),
	Density = 0.48,
	Haze = 2.8,
	Glare = 0.12,
	AtmoColor = Color3.fromRGB(110, 108, 105),
	Decay = Color3.fromRGB(48, 50, 55),
	Tint = Color3.fromRGB(210, 215, 220),
	Saturation = -0.18,
	Contrast = 0.14,
	GradeBrightness = -0.06,
}

-- Night fell: denser fog, colder crush, orange sky while the roof horde is active.
local HORDE = {
	ClockTime = 20.4,
	Brightness = 0.55,
	ExposureCompensation = -0.55,
	Ambient = Color3.fromRGB(14, 12, 16),
	OutdoorAmbient = Color3.fromRGB(72, 42, 28),
	ColorShift_Top = Color3.fromRGB(255, 110, 45),
	ColorShift_Bottom = Color3.fromRGB(28, 16, 12),
	Density = 0.72,
	Haze = 3.6,
	Glare = 0.4,
	AtmoColor = Color3.fromRGB(120, 70, 45),
	Decay = Color3.fromRGB(55, 30, 22),
	Tint = Color3.fromRGB(255, 175, 130),
	Saturation = -0.08,
	Contrast = 0.22,
	GradeBrightness = -0.1,
}

local hordeOn = false
local flickerGeneration = 0

local function tween(instance: Instance, seconds: number, goal: { [string]: any })
	TweenService:Create(instance, TweenInfo.new(seconds, Enum.EasingStyle.Sine), goal):Play()
end

local function applyLook(look: typeof(BASE), seconds: number)
	Lighting.ClockTime = look.ClockTime
	tween(Lighting, seconds, {
		Brightness = look.Brightness,
		ExposureCompensation = look.ExposureCompensation,
		Ambient = look.Ambient,
		OutdoorAmbient = look.OutdoorAmbient,
		ColorShift_Top = look.ColorShift_Top,
		ColorShift_Bottom = look.ColorShift_Bottom,
	})
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		tween(atmosphere, seconds, {
			Density = look.Density,
			Haze = look.Haze,
			Glare = look.Glare,
			Color = look.AtmoColor,
			Decay = look.Decay,
		})
	end
	local grading = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if grading then
		tween(grading, seconds, {
			TintColor = look.Tint,
			Saturation = look.Saturation,
			Contrast = look.Contrast,
			Brightness = look.GradeBrightness,
		})
	end
end

-- Emergency ExitLamps + warm StairLamps flicker while night has fallen (horde).
local function startEmergencyFlicker(gen: number)
	task.spawn(function()
		local rng = Random.new()
		while gen == flickerGeneration and hordeOn do
			local world = workspace:FindFirstChild("GeneratedWorld")
			if world then
				for _, d in world:GetDescendants() do
					if d:IsA("PointLight") then
						local parent = d.Parent
						if parent and parent:IsA("BasePart") then
							local name = parent.Name
							if name == "ExitLamp" or name == "StairLamp" then
								local base = d:GetAttribute("FlickerBase")
								if typeof(base) ~= "number" then
									base = d.Brightness
									d:SetAttribute("FlickerBase", base)
								end
								local baseN = base :: number
								if rng:NextNumber() < 0.35 then
									d.Brightness = baseN * rng:NextNumber(0.15, 0.55)
								else
									d.Brightness = baseN * rng:NextNumber(0.85, 1.05)
								end
							end
						end
					end
				end
			end
			task.wait(rng:NextNumber(0.08, 0.28))
		end
		-- Restore when flicker ends.
		local world = workspace:FindFirstChild("GeneratedWorld")
		if world then
			for _, d in world:GetDescendants() do
				if d:IsA("PointLight") then
					local base = d:GetAttribute("FlickerBase")
					if typeof(base) == "number" then
						d.Brightness = base
					end
				end
			end
		end
	end)
end

function Atmosphere.Apply()
	hordeOn = false
	flickerGeneration += 1
	Lighting.ClockTime = BASE.ClockTime
	Lighting.GeographicLatitude = 42
	Lighting.Brightness = BASE.Brightness
	Lighting.ExposureCompensation = BASE.ExposureCompensation
	-- Ambient = interiors (flashlight must matter). OutdoorAmbient = roof breath.
	Lighting.Ambient = BASE.Ambient
	Lighting.OutdoorAmbient = BASE.OutdoorAmbient
	Lighting.ColorShift_Top = BASE.ColorShift_Top
	Lighting.ColorShift_Bottom = BASE.ColorShift_Bottom
	Lighting.EnvironmentDiffuseScale = 0.18
	Lighting.EnvironmentSpecularScale = 0.12
	Lighting.ShadowSoftness = 0.55
	Lighting.GlobalShadows = true

	-- Replace whatever the template place shipped with.
	for _, child in Lighting:GetChildren() do
		if child:IsA("Atmosphere") or child:IsA("Sky") or child:IsA("PostEffect") then
			child:Destroy()
		end
	end

	local sky = Instance.new("Sky")
	sky.SunAngularSize = 6
	sky.MoonAngularSize = 0
	sky.StarCount = 0
	sky.Parent = Lighting

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = BASE.Density
	atmosphere.Offset = 0.22
	atmosphere.Haze = BASE.Haze
	atmosphere.Glare = BASE.Glare
	atmosphere.Color = BASE.AtmoColor
	atmosphere.Decay = BASE.Decay
	atmosphere.Parent = Lighting

	local terrain = workspace.Terrain
	local clouds = terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Cover = 0.78
	clouds.Density = 0.7
	clouds.Color = Color3.fromRGB(120, 122, 128)
	clouds.Parent = terrain

	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.02
	rays.Spread = 0.35
	rays.Parent = Lighting

	local grading = Instance.new("ColorCorrectionEffect")
	grading.TintColor = BASE.Tint
	grading.Saturation = BASE.Saturation
	grading.Contrast = BASE.Contrast
	grading.Brightness = BASE.GradeBrightness
	grading.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.22
	bloom.Size = 18
	bloom.Threshold = 1.9
	bloom.Parent = Lighting
end

-- Dark orange sky while the roof horde is pouring out. WeatherService skips clock/rain while this is on.
function Atmosphere.SetHordeThreat(active: boolean, seconds: number?)
	if active == hordeOn then
		return
	end
	hordeOn = active
	workspace:SetAttribute("HordeThreat", active)
	applyLook(if active then HORDE else BASE, seconds or 2.5)
	flickerGeneration += 1
	if active then
		startEmergencyFlicker(flickerGeneration)
	end
end

function Atmosphere.IsHordeThreat(): boolean
	return hordeOn
end

-- WeatherService restores haze to these when rain ends (must match BASE).
function Atmosphere.BaseHaze(): (number, number)
	return BASE.Density, BASE.Haze
end

return Atmosphere
