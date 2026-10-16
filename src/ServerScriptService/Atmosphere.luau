--!strict
-- Shared look of both places (lobby and tower): sky, clouds, haze and colour grading.

local Lighting = game:GetService("Lighting")

local Atmosphere = {}

-- Apocalyptic sunset: a low burning sun behind layers of lit clouds, rust-coloured haze in the distance
-- and a warm, slightly desaturated grade. Everything here is engine lighting, so it costs no assets.
function Atmosphere.Apply()
	Lighting.ClockTime = 17.75
	Lighting.GeographicLatitude = 35
	Lighting.Brightness = 2.4
	Lighting.ExposureCompensation = 0.15
	Lighting.Ambient = Color3.fromRGB(34, 26, 24)
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 86, 66)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 160, 95)
	Lighting.ColorShift_Bottom = Color3.fromRGB(70, 40, 60)
	Lighting.EnvironmentDiffuseScale = 0.45
	Lighting.EnvironmentSpecularScale = 0.35
	Lighting.ShadowSoftness = 0.25
	Lighting.GlobalShadows = true

	-- Replace whatever the template place shipped with.
	for _, child in Lighting:GetChildren() do
		if child:IsA("Atmosphere") or child:IsA("Sky") or child:IsA("PostEffect") then
			child:Destroy()
		end
	end

	local sky = Instance.new("Sky")
	sky.SunAngularSize = 14
	sky.MoonAngularSize = 0
	sky.StarCount = 0
	sky.CelestialBodiesShown = true
	sky.Parent = Lighting

	-- Thin haze near the ground, thicker towards the horizon: keeps the base readable and the skyline moody.
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.32
	atmosphere.Haze = 1.9
	atmosphere.Glare = 0.45
	atmosphere.Color = Color3.fromRGB(214, 128, 78)
	atmosphere.Decay = Color3.fromRGB(96, 52, 58)
	atmosphere.Parent = Lighting

	-- Volumetric clouds lit orange by the setting sun.
	local terrain = workspace.Terrain
	local clouds = terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Cover = 0.62
	clouds.Density = 0.55
	clouds.Color = Color3.fromRGB(255, 176, 128)
	clouds.Parent = terrain

	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.08
	rays.Spread = 0.6
	rays.Parent = Lighting

	local grading = Instance.new("ColorCorrectionEffect")
	grading.TintColor = Color3.fromRGB(255, 236, 222)
	grading.Saturation = -0.05
	grading.Contrast = 0.14
	grading.Brightness = 0.02
	grading.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.5
	bloom.Size = 28
	bloom.Threshold = 1.4
	bloom.Parent = Lighting
end

return Atmosphere
