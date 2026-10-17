--!strict
-- Balance and shared settings. Every tunable number lives here.

local GameConfig = {
	-- Inventory and storage
	MaxInventoryWeight = 20,
	StorageCapacity = 60,

	-- Health
	StartingHealth = 100,
	MedkitHeal = 60, -- craft primary; matches game-design-loops §2

	-- Hazards
	FallDamageThreshold = 18,
	FallDamagePerStud = 2,
	ToxicDamagePerSecond = 8,
	ToxicGraceSeconds = 2,
	AirFilterToxicReduction = 0.75,
	HazardTickSeconds = 0.25,

	-- Hunger meter: empties over time (faster below the roof), Food refills it, empty = slow health loss.
	-- Full to empty takes about 6 min below the roof and about 11 min resting on it.
	HungerMax = 100,
	HungerDrainBelow = 0.28,
	HungerDrainRoof = 0.15,
	HungerWarnAt = 25,
	FoodRestore = 35,
	HungerDamagePerSecond = 1,

	-- Flashlight: battery drains while switched on, charges next to a built Generator.
	FlashlightBatterySeconds = 240,
	FlashlightChargePerSecond = 20,
	FlashlightChargeRadius = 16,

	-- Interaction
	InteractionDistance = 12,
	InteractionCooldown = 0.35,
	PromptActivationDistance = 10,

	-- Resource nodes. Per player; normal nodes refill when the player returns to the roof.
	-- Unique nodes (Crowbar, Flashlight, notes) never refill.
	ResourceRespawnSeconds = 0,
	ResetNodesOnRoofReturn = true,

	-- Death: carried items except protected ones drop as a personal backpack at the death spot.
	DeathProtectedItems = {
		Crowbar = true,
		Flashlight = true,
		Club = true,
		Pipe = true,
		Machete = true,
	} :: { [string]: boolean },
	BackpackDropLifetimeSeconds = 900,
	-- Intentional party drops (not death backpacks).
	GroundDropLifetimeSeconds = 120,
	RespawnDelaySeconds = 3,

	-- Combat and zombies
	Zombie = {
		MaxHealth = 60,
		WalkSpeed = 11, -- players run at 16, so running away works
		Damage = 12,
		AttackCooldown = 1.2,
		AttackRange = 4.5,
		AggroRange = 45,
		RespawnSeconds = 45, -- backlog: stop respawn after floor clear (ZombieService)
		-- Design targets: tutorial 4–6, mid 12–18, deep 18–24 (scaled for 240 plate).
		PerFloor = { 5, 14, 16, 20 }, -- floors 1..4; the roof is always safe
	},

	-- Downed instead of dead: you lie there until a teammate with a Bandage lifts you up.
	-- Everyone down = the match is lost; after GameOverSeconds the party goes back to the lobby.
	ReviveHealth = 35,
	GameOverSeconds = 8,
	ReviveHoldSeconds = 3,

	-- Loot crates: each roll picks "count" from min..max; "chance" makes the item optional.
	LootTables = {
		Common = {
			{ item = "Scrap", min = 1, max = 3 },
			{ item = "Food", min = 1, max = 2, chance = 0.7 },
			{ item = "Bandage", min = 1, max = 1, chance = 0.25 },
		},
		Rare = {
			{ item = "Scrap", min = 2, max = 4 },
			{ item = "Electronics", min = 1, max = 2 },
			{ item = "Bandage", min = 1, max = 1, chance = 0.5 },
			{ item = "Medkit", min = 1, max = 1, chance = 0.3 },
			{ item = "Pipe", min = 1, max = 1, chance = 0.2 },
		},
		Gold = {
			{ item = "Electronics", min = 2, max = 3 },
			{ item = "Bandage", min = 1, max = 2 },
			{ item = "Medkit", min = 1, max = 1 },
			{ item = "Pipe", min = 1, max = 1, chance = 0.35 },
			{ item = "Machete", min = 1, max = 1, chance = 0.2 },
		},
		Diamond = {
			{ item = "Electronics", min = 3, max = 4 },
			{ item = "Cable", min = 1, max = 1 },
			{ item = "Bandage", min = 2, max = 2 },
			{ item = "Medkit", min = 1, max = 1 },
			{ item = "Machete", min = 1, max = 1, chance = 0.6 },
		},
	} :: { [string]: { { item: string, min: number, max: number, chance: number? } } },

	-- Workbench on the roof. Heal craft is the primary sustain path (loops §2).
	Recipes = {
		{ id = "Bandage", cost = { Scrap = 4 } },
		{ id = "Medkit", cost = { Scrap = 6, Electronics = 2 } },
		{ id = "Pipe", cost = { Scrap = 4 } },
		{ id = "Machete", cost = { Scrap = 5, Electronics = 2 } },
	} :: { { id: string, cost: { [string]: number } } },

	-- Soft-currency tokens (not Robux). Earn table locked to game-design-loops / economy-robux.
	Tokens = {
		KillMin = 1,
		KillMax = 2,
		FloorClearBase = 10,
		FloorClearPerLevel = 2,
		FloorClearCap = 25,
		RoofBonus = 25,
	},

	-- Testing: every upgrade costs 1 of each listed item. Never ship with this on.
	TestPrices = false,

	-- Server and saving
	MaxPlayersPerServer = 6,
	-- false: every match starts from zero (only the lobby leaderboard survives). true: progress is saved.
	PersistProgress = false,
	AutosaveIntervalSeconds = 120,
	DataStoreName = "SkylineZero_PlayerData_v1",
	SchemaVersion = 1,
	DataRetryAttempts = 3,
	DataRetryDelaySeconds = 2,

	-- World layout (studs). Locked plate: 240×240 (~10–12s sprint cross). See game-design-loops.md.
	-- Layout coords in WorldBuilder were authored at REF_FLOOR_SIZE=70; scale with World.FloorSize/70.
	World = {
		Mode = "Generated" :: "Generated" | "Manual",
		FolderName = "GeneratedWorld",
		RoofY = 396, -- top surface of the roof slab
		FloorSpacing = 24,
		FloorCount = 4,
		RoofSize = 280,
		FloorSize = 240,
		RefFloorSize = 70, -- authoring reference for layout scale helper
		SlabThickness = 2,
		NeighborOffsetX = 400, -- centre of the neighbour tower roof
	},
}

return GameConfig
