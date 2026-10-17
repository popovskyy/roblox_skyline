--!strict
-- Fall damage, toxic air, hunger and zone/expedition tracking. All health changes happen here on the server.
-- Live values the HUD needs are published as player attributes: Zone, InToxic, Hunger, Hungry.
--
-- Hunger is a meter that empties over time everywhere (faster below the roof); eating Food fills it,
-- an empty meter slowly drains health. An expedition starts when the player goes well below the roof
-- and ends after they have stood on the roof for a moment (that refills the resource nodes).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local CharacterUtil = require(script.Parent.CharacterUtil)
local DamageService = require(script.Parent.DamageService)
local Net = require(script.Parent.Net)
local PlayerDataService = require(script.Parent.PlayerDataService)

local HazardService = {}

type Tracker = {
	spawnedAt: number,
	airborne: boolean,
	minVelocityY: number,
	toxicTime: number,
	warnedToxic: boolean,
	zone: string,
	onExpedition: boolean,
	roofTime: number,
	hunger: number,
	warnedHungry: boolean,
	-- False until the player leaves the roof for a floor or takes a meaningful first action.
	hungerActive: boolean,
}

local trackers: { [Player]: Tracker } = {}
local toxicZones: { BasePart } = {}
local victoryZone: BasePart? = nil

type ZoneListener = (player: Player, newZone: string, oldZone: string) -> ()
local zoneListeners: { ZoneListener } = {}
type PlayerListener = (player: Player) -> ()
local roofReturnListeners: { PlayerListener } = {}

local FALL_START_VELOCITY = -30
local FALL_END_VELOCITY = -3
local EXPEDITION_DEPTH = 8 -- studs below the roof surface that count as leaving the base
local ROOF_RETURN_SECONDS = 2

local World = GameConfig.World

function HazardService.SetToxicZones(zones: { BasePart })
	toxicZones = zones
end

function HazardService.SetVictoryZone(zone: BasePart)
	victoryZone = zone
end

function HazardService.OnZoneChanged(listener: ZoneListener)
	table.insert(zoneListeners, listener)
end

-- Fires when an expedition ends back on the roof.
function HazardService.OnReturnedToRoof(listener: PlayerListener)
	table.insert(roofReturnListeners, listener)
end

function HazardService.IsOnExpedition(player: Player): boolean
	local t = trackers[player]
	return t ~= nil and t.onExpedition
end

function HazardService.GetZone(player: Player): string
	local t = trackers[player]
	return t and t.zone or "Roof"
end

function HazardService.ResetCharacter(player: Player)
	trackers[player] = {
		spawnedAt = os.clock(),
		airborne = false,
		minVelocityY = 0,
		toxicTime = 0,
		warnedToxic = false,
		zone = "Roof",
		onExpedition = false,
		roofTime = 0,
		hunger = GameConfig.HungerMax,
		warnedHungry = false,
		hungerActive = false,
	}
	player:SetAttribute("InToxic", false)
	player:SetAttribute("Hungry", false)
	player:SetAttribute("Hunger", GameConfig.HungerMax)
	player:SetAttribute("Zone", "Roof")
end

-- Start draining hunger (terminal read, first floor, etc.). Safe to call more than once.
function HazardService.UnlockHunger(player: Player)
	local t = trackers[player]
	if t then
		t.hungerActive = true
	end
end

-- Eating. Returns false when the player is already full, so no food is wasted.
function HazardService.Feed(player: Player): boolean
	local t = trackers[player]
	if not t or t.hunger >= GameConfig.HungerMax - 1 then
		return false
	end
	t.hunger = math.min(GameConfig.HungerMax, t.hunger + GameConfig.FoodRestore)
	t.warnedHungry = false
	player:SetAttribute("Hunger", math.floor(t.hunger))
	player:SetAttribute("Hungry", false)
	return true
end

local function isInside(part: BasePart, position: Vector3): boolean
	local localPos = part.CFrame:PointToObjectSpace(position)
	local half = part.Size / 2
	return math.abs(localPos.X) <= half.X and math.abs(localPos.Y) <= half.Y and math.abs(localPos.Z) <= half.Z
end

-- Zone names: "Roof", "Floor01".."Floor04", "Outside" (neighbour tower, falling, etc).
local function zoneFor(position: Vector3): string
	if victoryZone and isInside(victoryZone, position) then
		return "NeighborRoof"
	end
	local half = World.RoofSize / 2 + 2
	if math.abs(position.X) > half or math.abs(position.Z) > half then
		return "Outside"
	end
	if position.Y >= World.RoofY - 1 then
		return "Roof"
	end
	for level = 1, World.FloorCount do
		local floorY = World.RoofY - level * World.FloorSpacing
		if position.Y >= floorY - 1 then
			return ("Floor%02d"):format(level)
		end
	end
	return "Outside"
end

local function setZone(player: Player, t: Tracker, zone: string)
	if zone == t.zone then
		return
	end
	local old = t.zone
	t.zone = zone
	player:SetAttribute("Zone", zone)
	-- First descent unlocks hunger even if the terminal was skipped.
	if not t.hungerActive and string.sub(zone, 1, 5) == "Floor" then
		t.hungerActive = true
	end
	for _, listener in zoneListeners do
		task.spawn(listener, player, zone, old)
	end
end

local function updateFall(player: Player, t: Tracker, root: BasePart, _humanoid: Humanoid)
	if os.clock() - t.spawnedAt < 1.5 then
		t.airborne = false
		t.minVelocityY = 0
		return
	end
	-- Uses only the replicated velocity: FloorMaterial is not reliable on the server.
	-- A fall starts once the player drops faster than any ramp walk and ends when the drop stops.
	local vy = root.AssemblyLinearVelocity.Y
	if vy < FALL_START_VELOCITY then
		t.airborne = true
		t.minVelocityY = math.min(t.minVelocityY, vy)
		return
	end
	if t.airborne and vy > FALL_END_VELOCITY then
		t.airborne = false
		-- Height equivalent of the impact speed: v^2 / 2g. Walking down ramps never gets near the threshold.
		local impact = -math.min(t.minVelocityY, vy)
		t.minVelocityY = 0
		if impact > 0 then
			local height = impact * impact / (2 * workspace.Gravity)
			local over = height - GameConfig.FallDamageThreshold
			if over > 0 then
				local damage = math.floor(over * GameConfig.FallDamagePerStud)
				if damage > 0 then
					DamageService.Damage(player, damage)
					Net.Notify(player, { "hazard.fall", damage }, "warning")
				end
			end
		end
	end
end

local function updateToxic(player: Player, t: Tracker, root: BasePart, _humanoid: Humanoid, dt: number)
	local inside = false
	for _, zone in toxicZones do
		if isInside(zone, root.Position) then
			inside = true
			break
		end
	end
	if not inside then
		if t.toxicTime > 0 then
			t.toxicTime = 0
			t.warnedToxic = false
			player:SetAttribute("InToxic", false)
		end
		return
	end
	if t.toxicTime == 0 then
		player:SetAttribute("InToxic", true)
	end
	t.toxicTime += dt
	if not t.warnedToxic then
		t.warnedToxic = true
		Net.Notify(player, "hazard.toxic", "warning")
	end
	if t.toxicTime < GameConfig.ToxicGraceSeconds then
		return
	end
	local data = PlayerDataService.Get(player)
	local multiplier = 1
	if data and data.upgrades.AirFilter then
		multiplier = 1 - GameConfig.AirFilterToxicReduction
	end
	DamageService.Damage(player, GameConfig.ToxicDamagePerSecond * multiplier * dt)
end

local function updateExpedition(player: Player, t: Tracker, root: BasePart, _humanoid: Humanoid, dt: number)
	if not t.onExpedition then
		if t.zone ~= "Roof" and t.zone ~= "NeighborRoof" and root.Position.Y < World.RoofY - EXPEDITION_DEPTH then
			t.onExpedition = true
			t.roofTime = 0
		end
	elseif t.zone == "Roof" then
		t.roofTime += dt
		if t.roofTime >= ROOF_RETURN_SECONDS then
			t.onExpedition = false
			for _, listener in roofReturnListeners do
				task.spawn(listener, player)
			end
		end
	else
		t.roofTime = 0
	end

	-- Hunger meter (paused until first floor or UnlockHunger).
	if not t.hungerActive then
		if t.onExpedition then
			t.hungerActive = true
		else
			return
		end
	end
	local drain = if t.onExpedition then GameConfig.HungerDrainBelow else GameConfig.HungerDrainRoof
	local before = math.floor(t.hunger)
	t.hunger = math.max(0, t.hunger - drain * dt)
	local after = math.floor(t.hunger)
	if after ~= before then
		player:SetAttribute("Hunger", after)
	end
	local hungry = t.hunger <= GameConfig.HungerWarnAt
	if hungry ~= (player:GetAttribute("Hungry") == true) then
		player:SetAttribute("Hungry", hungry)
	end
	if t.hunger <= 0 then
		if not t.warnedHungry then
			t.warnedHungry = true
			Net.Notify(player, "hazard.hungry", "error")
		end
		DamageService.Damage(player, GameConfig.HungerDamagePerSecond * dt)
	end
end

function HazardService.Start()
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		local slowTick = accumulator >= GameConfig.HazardTickSeconds
		local slowDt = accumulator
		if slowTick then
			accumulator = 0
		end
		for player, t in trackers do
			local root = CharacterUtil.GetRoot(player)
			local humanoid = CharacterUtil.GetHumanoid(player)
			if root and humanoid then
				updateFall(player, t, root, humanoid)
				if slowTick then
					setZone(player, t, zoneFor(root.Position))
					updateToxic(player, t, root, humanoid, slowDt)
					updateExpedition(player, t, root, humanoid, slowDt)
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		trackers[player] = nil
	end)
end

function HazardService.StopTracking(player: Player)
	trackers[player] = nil
end

return HazardService
