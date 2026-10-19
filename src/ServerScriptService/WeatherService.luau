--!strict
-- Time of day and rain, the same for everyone in the server. The clock runs from late afternoon through dusk
-- and night to morning; now and then it rains for a few minutes (clouds thicken, haze closes in).
-- Clients draw the rain itself and play its sound (WeatherController) from workspace's "Raining" attribute.
-- HordeThreat owns Lighting while active — do not fight Atmosphere's night crush.

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Atmosphere = require(script.Parent.Atmosphere)

local WeatherService = {}

local DAY_MINUTES = 24 -- one full day in real minutes
local START_CLOCK = 17.4
local RAIN_GAP = { 150, 330 } -- seconds between showers
local RAIN_LENGTH = { 70, 160 }

local function tween(instance: Instance, seconds: number, goal: { [string]: any })
	TweenService:Create(instance, TweenInfo.new(seconds, Enum.EasingStyle.Sine), goal):Play()
end

local function hordeThreat(): boolean
	return workspace:GetAttribute("HordeThreat") == true
end

local function setRain(on: boolean)
	workspace:SetAttribute("Raining", on)
	-- Horde sky owns Lighting while active; do not fight the orange dusk.
	if hordeThreat() then
		return
	end
	local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
	if clouds then
		tween(clouds, 20, { Cover = if on then 0.92 else 0.78, Density = if on then 0.9 else 0.7 })
	end
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		local baseDensity, baseHaze = Atmosphere.BaseHaze()
		tween(atmosphere, 20, {
			Density = if on then math.min(0.62, baseDensity + 0.1) else baseDensity,
			Haze = if on then baseHaze + 0.5 else baseHaze,
		})
	end
end

function WeatherService.Start()
	Lighting.ClockTime = START_CLOCK
	local perSecond = 24 / (DAY_MINUTES * 60)
	task.spawn(function()
		while true do
			task.wait(1)
			if not hordeThreat() then
				Lighting.ClockTime = (Lighting.ClockTime + perSecond) % 24
			end
		end
	end)
	task.spawn(function()
		local rng = Random.new()
		while true do
			task.wait(rng:NextNumber(RAIN_GAP[1], RAIN_GAP[2]))
			setRain(true)
			task.wait(rng:NextNumber(RAIN_LENGTH[1], RAIN_LENGTH[2]))
			setRain(false)
		end
	end)
end

return WeatherService
