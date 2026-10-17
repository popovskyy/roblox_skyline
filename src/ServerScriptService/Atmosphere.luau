--!strict
-- Shared look of both places (lobby and tower), in the spirit of The Last of Us: a quiet, ruined city under
-- a heavy sky. Muted colours, grey-brown haze, soft light; the tower adds day/night and rain (WeatherService).

local Lighting = game:GetService("Lighting")

local Atmosphere = {}

function Atmosphere.Apply()
	Lighting.ClockTime = 16.4
	Lighting.GeographicLatitude = 30
	Lighting.Brightness = 2.4
	Lighting.ExposureCompensation = 0.15
	-- Ambient decides how dark the interiors are: dim enough for the flashlight to matter, never pitch black.
	Lighting.Ambient = Color3.fromRGB(62, 59, 54)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 144, 128)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 226, 180)
	Lighting.ColorShift_Bottom = Color3.fromRGB(60, 70, 50)
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
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.3
	atmosphere.Haze = 1.6
	atmosphere.Glare = 0.35
	atmosphere.Color = Color3.fromRGB(176, 170, 156)
	atmosphere.Decay = Color3.fromRGB(92, 94, 86)
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
	grading.TintColor = Color3.fromRGB(244, 240, 232)
	grading.Saturation = -0.12
	grading.Contrast = 0.1
	grading.Brightness = 0.03
	grading.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.35
	bloom.Size = 24
	bloom.Threshold = 1.6
	bloom.Parent = Lighting
end

return Atmosphere
