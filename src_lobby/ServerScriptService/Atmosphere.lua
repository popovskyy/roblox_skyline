--!strict
-- Shared look: gloomy post-apoc (The Last of Us), not a bright botanical afternoon.
-- Lobby matches the tower grade so the elevator drop does not flip the lighting mood.

local Lighting = game:GetService("Lighting")

local Atmosphere = {}

function Atmosphere.Apply()
	Lighting.ClockTime = 17.2
	Lighting.GeographicLatitude = 35
	Lighting.Brightness = 1.6
	Lighting.ExposureCompensation = -0.15
	Lighting.Ambient = Color3.fromRGB(42, 44, 48)
	Lighting.OutdoorAmbient = Color3.fromRGB(88, 90, 96)
	Lighting.ColorShift_Top = Color3.fromRGB(180, 175, 165)
	Lighting.ColorShift_Bottom = Color3.fromRGB(40, 42, 48)
	Lighting.EnvironmentDiffuseScale = 0.35
	Lighting.EnvironmentSpecularScale = 0.2
	Lighting.ShadowSoftness = 0.45
	Lighting.GlobalShadows = true

	for _, child in Lighting:GetChildren() do
		if child:IsA("Atmosphere") or child:IsA("Sky") or child:IsA("PostEffect") then
			child:Destroy()
		end
	end

	local sky = Instance.new("Sky")
	sky.SunAngularSize = 8
	sky.MoonAngularSize = 0
	sky.StarCount = 0
	sky.Parent = Lighting

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.38
	atmosphere.Offset = 0.15
	atmosphere.Haze = 2.4
	atmosphere.Glare = 0.12
	atmosphere.Color = Color3.fromRGB(140, 138, 132)
	atmosphere.Decay = Color3.fromRGB(70, 72, 68)
	atmosphere.Parent = Lighting

	local terrain = workspace.Terrain
	local clouds = terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Cover = 0.78
	clouds.Density = 0.65
	clouds.Color = Color3.fromRGB(160, 160, 158)
	clouds.Parent = terrain

	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.02
	rays.Spread = 0.35
	rays.Parent = Lighting

	local grading = Instance.new("ColorCorrectionEffect")
	grading.TintColor = Color3.fromRGB(235, 232, 225)
	grading.Saturation = -0.12
	grading.Contrast = 0.08
	grading.Brightness = -0.04
	grading.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.12
	bloom.Size = 18
	bloom.Threshold = 2.2
	bloom.Parent = Lighting

	local blur = Instance.new("DepthOfFieldEffect")
	blur.FarIntensity = 0.15
	blur.FocusDistance = 40
	blur.InFocusRadius = 50
	blur.NearIntensity = 0
	blur.Parent = Lighting
end

return Atmosphere
