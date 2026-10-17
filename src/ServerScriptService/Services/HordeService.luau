--!strict
-- Timed roof horde: siren + toast, then new zombies climb the stair mouth onto the roof.
-- Does not respawn floor zombies. Barricade upgrade blocks the stair exit (server collision).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local BaseUpgradeService = require(script.Parent.BaseUpgradeService)
local Net = require(script.Parent.Net)
local SfxService = require(script.Parent.SfxService)
local ZombieService = require(script.Parent.ZombieService)

local HordeService = {}

local H = GameConfig.Horde
local World = GameConfig.World

-- Stair mouth on the roof (must match WorldBuilder HOLE / LANE constants).
local HOLE_X = 9
local HOLE_MIN_Z = -15
local LANE_CENTER = (HOLE_X + 0.5) / 2

local running = false
local generation = 0
local barricadeParts: { BasePart } = {}
local sirenAt = Vector3.new(LANE_CENTER, World.RoofY + 3, HOLE_MIN_Z)

local function randomRange(minSeconds: number, maxSeconds: number): number
	if maxSeconds <= minSeconds then
		return minSeconds
	end
	return minSeconds + math.random() * (maxSeconds - minSeconds)
end

local function partySize(): number
	return math.max(1, #Players:GetPlayers())
end

local function hordeCount(): number
	local size = partySize()
	return math.clamp(H.CountMin + (size - 1), H.CountMin, H.CountMax)
end

local function teamHasBarricade(): boolean
	-- Session mode shares upgrades across the server; any loaded member is enough.
	for _, player in Players:GetPlayers() do
		if BaseUpgradeService.Owns(player, "Barricade") then
			return true
		end
	end
	return false
end

local function applyBarricadeCollision(built: boolean)
	for _, part in barricadeParts do
		if part.Parent then
			part.CanCollide = built
		end
	end
end

local function collectBarricadeParts(root: Folder)
	table.clear(barricadeParts)
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("BarricadeBlock") == true then
			table.insert(barricadeParts, d)
		end
	end
	applyBarricadeCollision(teamHasBarricade())
end

local function warnEveryone()
	SfxService.Play("HordeSiren", sirenAt, H.SirenVolume)
	task.delay(0.9, function()
		SfxService.Play("HordeSiren", sirenAt, H.SirenVolume * 0.85)
	end)
	for _, player in Players:GetPlayers() do
		Net.Notify(player, "horde.warning", "warning")
	end
end

-- Spawn just inside the stair shaft (behind a built barricade) or pouring onto the roof.
local function spawnPositions(behindBarricade: boolean): (Vector3, Vector3)
	local home = Vector3.new(LANE_CENTER + (math.random() - 0.5) * 4, World.RoofY + 3, HOLE_MIN_Z - 6)
	if behindBarricade then
		local spawnAt = Vector3.new(
			LANE_CENTER + (math.random() - 0.5) * 5,
			World.RoofY - 4 + math.random() * 2,
			HOLE_MIN_Z + 4 + math.random() * 3
		)
		return spawnAt, home
	end
	local spawnAt = Vector3.new(
		LANE_CENTER + (math.random() - 0.5) * 6,
		World.RoofY + 3,
		HOLE_MIN_Z - 2 + (math.random() - 0.5) * 2
	)
	return spawnAt, home
end

local function releaseWave()
	warnEveryone()
	local count = hordeCount()
	local blocked = teamHasBarricade()
	applyBarricadeCollision(blocked)
	for i = 1, count do
		task.delay((i - 1) * H.SpawnStaggerSeconds, function()
			if not running then
				return
			end
			local spawnAt, home = spawnPositions(blocked)
			ZombieService.SpawnHordeZombie(spawnAt, home)
		end)
	end
end

local function scheduleLoop(gen: number)
	task.spawn(function()
		local firstWait = randomRange(H.FirstDelayMin, H.FirstDelayMax)
		task.wait(firstWait)
		while running and gen == generation do
			releaseWave()
			local gap = randomRange(H.IntervalMin, H.IntervalMax)
			task.wait(gap)
		end
	end)
end

function HordeService.Reset()
	generation += 1
	applyBarricadeCollision(teamHasBarricade())
	if running then
		scheduleLoop(generation)
	end
end

function HordeService.Start(root: Folder)
	if running then
		return
	end
	running = true
	collectBarricadeParts(root)
	BaseUpgradeService.OnPurchased(function(_player: Player, upgradeId: string)
		if upgradeId == "Barricade" then
			applyBarricadeCollision(true)
		end
	end)
	generation += 1
	scheduleLoop(generation)
end

return HordeService
