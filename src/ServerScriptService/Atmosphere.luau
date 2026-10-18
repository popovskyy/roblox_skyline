--!strict
-- Shared look of both places (lobby and tower), in the spirit of The Last of Us: a quiet, ruined city under
-- a heavy sky. Muted colours, grey-brown haze, soft light; the tower adds day/night and rain (WeatherService).
-- HordeThreat darkens / oranges the sky while roof zombies climb out (HordeService).

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Atmosphere = {}

-- Brighter than before (owner: "too dark"); values from the polish spec, section 5.
local BASE = {
	ClockTime = 15.5,
	Brightness = 2.6,
	ExposureCompensation = 0.15,
	Ambient = Color3.fromRGB(78, 74, 66),
	OutdoorAmbient = Color3.fromRGB(160, 152, 134),
	ColorShift_Top = Color3.fromRGB(255, 226, 180),
	ColorShift_Bottom = Color3.fromRGB(60, 70, 50),
	Density = 0.3,
	Haze = 2,
	Glare = 0.35,
	AtmoColor = Color3.fromRGB(199, 190, 170),
	Decay = Color3.fromRGB(92, 94, 86),
	Tint = Color3.fromRGB(255, 246, 230),
	Saturation = -0.05,
	Contrast = 0.1,
	GradeBrightness = 0.03,
}

-- Orange dusk crush while the roof horde is active.
local HORDE = {
	ClockTime = 19.2,
	Brightness = 1.35,
	ExposureCompensation = -0.25,
	Ambient = Color3.fromRGB(42, 28, 22),
	OutdoorAmbient = Color3.fromRGB(110, 70, 45),
	ColorShift_Top = Color3.fromRGB(255, 140, 60),
	ColorShift_Bottom = Color3.fromRGB(40, 25, 18),
	Density = 0.42,
	Haze = 2.4,
	Glare = 0.55,
	AtmoColor = Color3.fromRGB(160, 100, 70),
	Decay = Color3.fromRGB(70, 40, 30),
	Tint = Color3.fromRGB(255, 190, 150),
	Saturation = -0.05,
	Contrast = 0.18,
	GradeBrightness = -0.04,
}

local hordeOn = false

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

function Atmosphere.Apply()
	hordeOn = false
	Lighting.ClockTime = BASE.ClockTime
	Lighting.GeographicLatitude = 30
	Lighting.Brightness = BASE.Brightness
	Lighting.ExposureCompensation = BASE.ExposureCompensation
	-- Ambient decides how dark the interiors are: dim enough for the flashlight to matter, never pitch black.
	Lighting.Ambient = BASE.Ambient
	Lighting.OutdoorAmbient = BASE.OutdoorAmbient
	Lighting.ColorShift_Top = BASE.ColorShift_Top
	Lighting.ColorShift_Bottom = BASE.ColorShift_Bottom
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.35
	Lighting.ShadowSoftness = 0.3
	Lighting.GlobalShadows = true

	-- Replace whatever the template place shipped with.
	for _, child in Lighting:GetChildren() do
		if child:IsA("Atmosphere") or child:IsA("Sky") or child:IsA("PostEffect") then
			child:Destroy()
		end
	end

	local sky = Instance.new("Sky")
	sky.SunAngularSize = 12
	sky.MoonAngularSize = 0
	sky.StarCount = 0
	sky.Parent = Lighting

	-- Light haze near the player, thicker towards the horizon so the ruins fade into a warm green-grey.
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = BASE.Density
	atmosphere.Offset = 0.3
	atmosphere.Haze = BASE.Haze
	atmosphere.Glare = BASE.Glare
	atmosphere.Color = BASE.AtmoColor
	atmosphere.Decay = BASE.Decay
	atmosphere.Parent = Lighting

	-- Broken cloud cover lit by the afternoon sun.
	local terrain = workspace.Terrain
	local clouds = terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Cover = 0.6
	clouds.Density = 0.5
	clouds.Color = Color3.fromRGB(214, 210, 204)
	clouds.Parent = terrain

	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.06
	rays.Spread = 0.5
	rays.Parent = Lighting

	local grading = Instance.new("ColorCorrectionEffect")
	grading.TintColor = BASE.Tint
	grading.Saturation = BASE.Saturation
	grading.Contrast = BASE.Contrast
	grading.Brightness = BASE.GradeBrightness
	grading.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.35
	bloom.Size = 24
	bloom.Threshold = 1.6
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
end

function Atmosphere.IsHordeThreat(): boolean
	return hordeOn
end

return Atmosphere
