--!strict
-- Timed roof horde: siren + toast + scary music bed + orange/dark sky, then new zombies climb the
-- stair mouth onto the roof. Does not respawn floor zombies. Barricade upgrade blocks the stair exit.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Atmosphere = require(script.Parent.Parent.Atmosphere)
local BaseUpgradeService = require(script.Parent.BaseUpgradeService)
local Locale = require(ReplicatedStorage.Shared.Locale)
local Net = require(script.Parent.Net)
local StorageService = require(script.Parent.StorageService)
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
local threatGeneration = 0
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

local waveNumber = 0

-- Wave n brings n zombies, plus one per extra player.
local function hordeCount(): number
	return math.clamp(waveNumber + (partySize() - 1), H.CountMin, H.CountMax)
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

-- Barricade health lives in workspace attributes (BarricadeHp / BarricadeMax) so every client can draw it.
local B = GameConfig.Barricade
local barricadeHp = 0

local function setBarricadeHp(hp: number)
	barricadeHp = math.clamp(hp, 0, B.MaxHp)
	workspace:SetAttribute("BarricadeHp", barricadeHp)
	workspace:SetAttribute("BarricadeMax", B.MaxHp)
end

-- "Wire" collision group: blocks zombies, lets players (Default) walk straight through.
local PhysicsService = game:GetService("PhysicsService")
pcall(function()
	PhysicsService:RegisterCollisionGroup("Wire")
	PhysicsService:RegisterCollisionGroup("Zombies")
end)
PhysicsService:CollisionGroupSetCollidable("Wire", "Default", false)
PhysicsService:CollisionGroupSetCollidable("Wire", "Zombies", true)

local function applyBarricadeCollision(built: boolean)
	for _, part in barricadeParts do
		if part.Parent then
			part.CollisionGroup = "Wire"
			part.CanCollide = built
			-- Keep raycasts / pathfinding in sync with the physical block.
			part.CanQuery = true
			local mod = part:FindFirstChildOfClass("PathfindingModifier")
			if mod then
				mod.PassThrough = not built
			end
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

local function clearThreat(gen: number)
	if gen ~= threatGeneration then
		return
	end
	Atmosphere.SetHordeThreat(false, 3)
	-- Dawn: whatever is left of the horde leaves.
	ZombieService.DespawnHorde()
end

local function warnEveryone()
	SfxService.Play("HordeSiren", sirenAt, H.SirenVolume)
	task.delay(0.9, function()
		SfxService.Play("HordeSiren", sirenAt, H.SirenVolume * 0.85)
	end)
	-- Scary music bed (MusicController) + orange/dark sky for the wave.
	threatGeneration += 1
	local threatGen = threatGeneration
	Atmosphere.SetHordeThreat(true, 2)
	task.delay(H.ThreatSeconds, function()
		clearThreat(threatGen)
	end)
	-- The "WAVE n" message (releaseWave) is the warning; no second toast here.
end

-- The horde comes up from below: zombies appear on the stair landing under the roof (out of sight)
-- and climb the last flight. Behind a built barricade they stop at the boards and start breaking them.
local LANDING_Z = 9
local HOLE_MAX_Z = 15
local function spawnPositions(_behindBarricade: boolean): (Vector3, Vector3)
	local landingY = World.RoofY - World.FloorSpacing / 2 + 3
	local spawnAt = Vector3.new(
		(math.random() - 0.5) * (HOLE_X * 2 - 4),
		landingY,
		LANDING_Z + 1 + math.random() * (HOLE_MAX_Z - LANDING_Z - 2)
	)
	-- Head for the roof just outside the stair mouth.
	local home = Vector3.new(LANE_CENTER * -1 + (math.random() - 0.5) * 4, World.RoofY + 3, HOLE_MIN_Z - 6)
	return spawnAt, home
end

-- The way up: across the landing to the foot of the west (roof) ramp, up the ramp, out of the mouth.
local function climbRoute(home: Vector3): { Vector3 }
	local landingY = World.RoofY - World.FloorSpacing / 2 + 3
	local laneX = -LANE_CENTER + (math.random() - 0.5) * 2
	return {
		Vector3.new(laneX, landingY, LANDING_Z + 1),
		Vector3.new(laneX, World.RoofY + 3, HOLE_MIN_Z + 1),
		Vector3.new(laneX, World.RoofY + 3, HOLE_MIN_Z - 3),
		home,
	}
end

local function releaseWave()
	-- Re-read each wave so a mid-match Enabled = false (QA) stops further sirens/spawns.
	if not H.Enabled then
		return
	end
	warnEveryone()
	waveNumber += 1
	workspace:SetAttribute("HordeWave", waveNumber)
	for _, player in Players:GetPlayers() do
		Net.Notify(player, { "horde.wave", waveNumber }, "warning")
	end
	local count = hordeCount()
	local blocked = teamHasBarricade() and barricadeHp > 0
	applyBarricadeCollision(blocked)
	for i = 1, count do
		task.delay((i - 1) * H.SpawnStaggerSeconds, function()
			if not running then
				return
			end
			local spawnAt, home = spawnPositions(blocked)
			ZombieService.SpawnHordeZombie(spawnAt, home, climbRoute(home))
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

-- A zombie hitting the boards. When they break, the stair mouth opens until someone repairs them.
local function hitBarricade(amount: number)
	if barricadeHp <= 0 or not teamHasBarricade() then
		return
	end
	setBarricadeHp(barricadeHp - amount)
	SfxService.Play("HitBlunt", sirenAt, 0.7)
	if barricadeHp <= 0 then
		applyBarricadeCollision(false)
		SfxService.Play("Rubble", sirenAt, 1)
		for _, player in Players:GetPlayers() do
			Net.Notify(player, "barricade.broken", "error")
		end
	end
end

-- Repair from the barricade's prompt: costs scrap (team pool), restores health, closes the stairs again.
function HordeService.Repair(player: Player): (boolean, any)
	if not teamHasBarricade() then
		return false, "barricade.notBuilt"
	end
	if barricadeHp >= B.MaxHp then
		return false, "barricade.full"
	end
	if not StorageService.TrySpend(player, B.RepairCost) then
		return false, { "upgrade.notEnough", Locale.Cost(B.RepairCost) }
	end
	setBarricadeHp(barricadeHp + B.RepairAmount)
	applyBarricadeCollision(true)
	SfxService.Play("Build", sirenAt, 0.8)
	return true, nil
end

function HordeService.Reset()
	generation += 1
	waveNumber = 0
	workspace:SetAttribute("HordeWave", 0)
	setBarricadeHp(0)
	threatGeneration += 1
	Atmosphere.SetHordeThreat(false, 1)
	applyBarricadeCollision(teamHasBarricade())
	if running and H.Enabled then
		scheduleLoop(generation)
	end
end

function HordeService.Start(root: Folder)
	if running then
		return
	end
	running = true
	workspace:SetAttribute("HordeThreat", false)
	-- Barricade boards still harden on purchase even when waves are off (QA kill-switch).
	collectBarricadeParts(root)
	setBarricadeHp(0)
	ZombieService.OnBarricadeHit = function()
		hitBarricade(B.ZombieHit)
	end
	BaseUpgradeService.OnPurchased(function(_player: Player, upgradeId: string)
		if upgradeId == "Barricade" then
			setBarricadeHp(B.MaxHp)
			applyBarricadeCollision(true)
		end
	end)
	if not H.Enabled then
		return
	end
	generation += 1
	scheduleLoop(generation)
end

return HordeService
