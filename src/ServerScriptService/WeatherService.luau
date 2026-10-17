--!strict
-- Time of day and rain, the same for everyone in the server. The clock runs from afternoon through dusk
-- and night to morning; now and then it rains for a few minutes (clouds thicken, haze closes in).
-- Clients draw the rain itself and play its sound (WeatherController) from workspace's "Raining" attribute.
-- Plain module with no requires, so it can never stop the world from being built.

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local WeatherService = {}

local DAY_MINUTES = 24 -- one full day in real minutes
local START_CLOCK = 15.5
local RAIN_GAP = { 150, 330 } -- seconds between showers
local RAIN_LENGTH = { 70, 160 }

local function tween(instance: Instance, seconds: number, goal: { [string]: any })
	TweenService:Create(instance, TweenInfo.new(seconds, Enum.EasingStyle.Sine), goal):Play()
end

local function setRain(on: boolean)
	workspace:SetAttribute("Raining", on)
	local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
	if clouds then
		tween(clouds, 20, { Cover = if on then 0.9 else 0.6, Density = if on then 0.85 else 0.5 })
	end
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		tween(atmosphere, 20, { Density = if on then 0.4 else 0.3, Haze = if on then 2.6 else 1.8 })
	end
end

function WeatherService.Start()
	Lighting.ClockTime = START_CLOCK
	local perSecond = 24 / (DAY_MINUTES * 60)
	task.spawn(function()
		while true do
			task.wait(1)
			Lighting.ClockTime = (Lighting.ClockTime + perSecond) % 24
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
