--!strict
-- One mid-floor blackout per match: ceiling / stair / window lights die for a few seconds on floor 2 or 3.
-- Green ExitLamps stay on so phones stay readable. Staggered before the roof horde. Server owns lights;
-- clients only get toasts (and hear the SFX).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local HazardService = require(script.Parent.HazardService)
local Net = require(script.Parent.Net)
local SfxService = require(script.Parent.SfxService)

local FloorEventService = {}

local E = GameConfig.FloorEvent
local World = GameConfig.World

local running = false
local generation = 0
local fired = false
local root: Folder? = nil

type LightSave = {
	light: Light,
	enabled: boolean,
}
type NeonSave = {
	part: BasePart,
	material: Enum.Material,
	color: Color3,
}

local lightSaves: { LightSave } = {}
local neonSaves: { NeonSave } = {}

local function randomRange(minSeconds: number, maxSeconds: number): number
	if maxSeconds <= minSeconds then
		return minSeconds
	end
	return minSeconds + math.random() * (maxSeconds - minSeconds)
end

local function floorCenter(level: number): Vector3
	local floorY = World.RoofY - level * World.FloorSpacing
	return Vector3.new(0, floorY + 6, 0)
end

local function pickMidFloor(): number?
	local on2 = false
	local on3 = false
	for _, player in Players:GetPlayers() do
		local zone = HazardService.GetZone(player)
		if zone == "Floor02" then
			on2 = true
		elseif zone == "Floor03" then
			on3 = true
		end
	end
	-- Floor 2 has ceiling lamps (stronger read); floor 3 still kills shafts + stair lamps.
	if on2 then
		return 2
	end
	if on3 then
		return 3
	end
	return nil
end

local function restoreLights()
	for _, save in lightSaves do
		if save.light.Parent then
			save.light.Enabled = save.enabled
		end
	end
	table.clear(lightSaves)
	for _, save in neonSaves do
		if save.part.Parent then
			save.part.Material = save.material
			save.part.Color = save.color
		end
	end
	table.clear(neonSaves)
	workspace:SetAttribute("BlackoutFloor", 0)
end

local function killLights(level: number)
	restoreLights()
	local world = root
	if not world then
		return
	end
	local dim = Color3.fromRGB(40, 38, 36)
	for _, d in world:GetDescendants() do
		if d:IsA("Light") and d:GetAttribute("BlackoutFloor") == level then
			table.insert(lightSaves, { light = d, enabled = d.Enabled })
			d.Enabled = false
			local parent = d.Parent
			if
				parent
				and parent:IsA("BasePart")
				and parent.Material == Enum.Material.Neon
				and parent.Name ~= "ExitLamp"
			then
				table.insert(neonSaves, { part = parent, material = parent.Material, color = parent.Color })
				parent.Material = Enum.Material.Metal
				parent.Color = dim
			end
		end
	end
	workspace:SetAttribute("BlackoutFloor", level)
end

local function notifyAll(key: string, kind: Net.NotifyKind)
	for _, player in Players:GetPlayers() do
		Net.Notify(player, key, kind)
	end
end

local function runBlackout(level: number, gen: number)
	fired = true
	local at = floorCenter(level)
	notifyAll("event.blackout.warn", "warning")
	SfxService.Play("BreakIn", at, E.TelegraphVolume)
	task.wait(E.TelegraphSeconds)
	if not running or gen ~= generation then
		return
	end
	killLights(level)
	notifyAll("event.blackout.on", "warning")
	local hold = randomRange(E.DurationMin, E.DurationMax)
	task.wait(hold)
	if gen ~= generation then
		return
	end
	restoreLights()
	SfxService.Play("GeneratorStart", at, E.RestoreVolume)
	notifyAll("event.blackout.off", "success")
end

local function scheduleLoop(gen: number)
	task.spawn(function()
		task.wait(E.MinDelay)
		local deadline = os.clock() + (E.MaxDelay - E.MinDelay)
		while running and gen == generation and not fired do
			if os.clock() > deadline then
				return
			end
			local level = pickMidFloor()
			if level then
				runBlackout(level, gen)
				return
			end
			task.wait(E.PollSeconds)
		end
	end)
end

function FloorEventService.Reset()
	generation += 1
	fired = false
	restoreLights()
	if running then
		scheduleLoop(generation)
	end
end

function FloorEventService.Start(worldRoot: Folder)
	if running then
		return
	end
	running = true
	root = worldRoot
	workspace:SetAttribute("BlackoutFloor", 0)
	generation += 1
	scheduleLoop(generation)
end

return FloorEventService
