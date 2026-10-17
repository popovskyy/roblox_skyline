--!strict
-- Balance and shared settings. Every tunable number lives here.

local GameConfig = {
	-- Inventory and storage
	MaxInventoryWeight = 20,
	StorageCapacity = 60,

	-- Health
	StartingHealth = 100,
	MedkitHeal = 35,

	-- Hazards
	FallDamageThreshold = 18,
	FallDamagePerStud = 2,
	ToxicDamagePerSecond = 8,
	ToxicGraceSeconds = 2,
	AirFilterToxicReduction = 0.75,
	HazardTickSeconds = 0.25,

	-- Hunger meter: empties over time (faster below the roof), Food refills it, empty = slow health loss.
	-- Full to empty takes about 6 min below the roof and about 11 min resting on it.
	-- Drain stays off until the first floor or a meaningful roof action (terminal), so the first
	-- minutes teach the loop instead of punishing AFK on spawn.
	HungerMax = 100,
	HungerDrainBelow = 0.28,
	HungerDrainRoof = 0.15,
	HungerWarnAt = 25,
	FoodRestore = 35,
	HungerDamagePerSecond = 1,

	-- First-session polish (roof idle nudge + HUD toast spacing).
	IdleNudgeSeconds = 45, -- soft ping at the terminal if still on step 1 and not moving
	IdleNudgeMoveSpeed = 2, -- horizontal studs/s that count as moving
	ToastMinIntervalSeconds = 15, -- info/success; warning/error bypass so danger still lands

	-- Flashlight: battery drains while switched on, charges next to a built Generator.
	FlashlightBatterySeconds = 240,
	FlashlightChargePerSecond = 20,
	FlashlightChargeRadius = 16,

	-- Interaction
	InteractionDistance = 12,
	InteractionCooldown = 0.35,
	PromptActivationDistance = 10,

	-- Resource nodes. Per player. Scrap/Electronics stay gone after pickup (no roof refill) so the
	-- build chain stays scarce; unique nodes never refill either. Crates use their own opened state.
	ResourceRespawnSeconds = 0,
	ResetNodesOnRoofReturn = false,

	-- Soft rubble = hands / any melee (no tool). Hard rubble = Crowbar. Hold times feel like work.
	Rubble = {
		SoftHoldSeconds = 3.0,
		HardHoldSeconds = 5.0,
	},

	-- Death: carried items except protected ones drop as a personal backpack at the death spot.
	DeathProtectedItems = {
		Crowbar = true,
		Flashlight = true,
		Club = true,
		Bat = true,
		Pipe = true,
		Machete = true,
	} :: { [string]: boolean },
	BackpackDropLifetimeSeconds = 900,
	RespawnDelaySeconds = 3,

	-- Combat and zombies
	Zombie = {
		MaxHealth = 60,
		WalkSpeed = 11, -- players run at 16, so running away works
		Damage = 12,
		AttackCooldown = 1.2,
		AttackRange = 4.5,
		AggroRange = 45,
		RespawnSeconds = 0, -- unused: zombies do not respawn
		PerFloor = { 1, 2, 3, 4 }, -- floors 1..4: one more zombie on every floor down; the roof is always safe
	},

	-- Timed roof horde: does not respawn floor zombies; only spawns a new wave up the stairs.
	-- First wave after FirstDelayMin..Max seconds of match time, then every IntervalMin..Max.
	-- Count scales with players in the server: solo = CountMin, each extra player +1, capped at CountMax.
	Horde = {
		FirstDelayMin = 480, -- 8 min
		FirstDelayMax = 600, -- 10 min
		IntervalMin = 480,
		IntervalMax = 600,
		CountMin = 6,
		CountMax = 10,
		SpawnStaggerSeconds = 0.7,
		SirenVolume = 1.35,
	},

	-- One mid-floor blackout per match (floor 2 or 3). Fires after MinDelay once someone is on a mid
	-- floor, never after MaxDelay (staggered before the first roof horde). Green exit lamps stay on.
	FloorEvent = {
		MinDelay = 180, -- first ~3 min: no second beat
		MaxDelay = 420, -- ends before horde FirstDelayMin (480)
		PollSeconds = 2,
		TelegraphSeconds = 2,
		DurationMin = 8,
		DurationMax = 12,
		TelegraphVolume = 0.55,
		RestoreVolume = 1.1,
	},

	-- Downed instead of dead: you lie there until a teammate with a Bandage lifts you up.
	-- Everyone down = the match is lost; after GameOverSeconds the party goes back to the lobby.
	ReviveHealth = 35,
	GameOverSeconds = 11, -- long enough for the results screen to count up
	ReviveHoldSeconds = 3,

	-- Loot crates: each roll picks "count" from min..max; "chance" makes the item optional.
	LootTables = {
		Common = {
			{ item = "Scrap", min = 1, max = 3 },
			{ item = "Food", min = 1, max = 2, chance = 0.7 },
			{ item = "Bandage", min = 1, max = 1, chance = 0.25 },
			{ item = "Bat", min = 1, max = 1, chance = 0.08 },
		},
		Rare = {
			{ item = "Scrap", min = 2, max = 4 },
			{ item = "Electronics", min = 1, max = 2 },
			{ item = "Bandage", min = 1, max = 1, chance = 0.5 },
			{ item = "Medkit", min = 1, max = 1, chance = 0.3 },
			{ item = "Bat", min = 1, max = 1, chance = 0.3 },
			{ item = "Pipe", min = 1, max = 1, chance = 0.2 },
		},
		Gold = {
			{ item = "Electronics", min = 2, max = 3 },
			{ item = "Bandage", min = 1, max = 2 },
			{ item = "Medkit", min = 1, max = 1 },
			{ item = "Pipe", min = 1, max = 1, chance = 0.35 },
			{ item = "Machete", min = 1, max = 1, chance = 0.2 },
			{ item = "Key", min = 1, max = 1, chance = 0.25 },
		},
		Diamond = {
			{ item = "Electronics", min = 3, max = 4 },
			{ item = "Cable", min = 1, max = 1 },
			{ item = "Bandage", min = 2, max = 2 },
			{ item = "Medkit", min = 1, max = 1 },
			{ item = "Machete", min = 1, max = 1, chance = 0.6 },
		},
	} :: { [string]: { { item: string, min: number, max: number, chance: number? } } },

	-- Loot crates. Every crate rolls its rarity per floor when the tower is built; the odds are
	-- Common / Rare / Gold / Diamond in percent.
	Loot = {
		TierOrder = { "Common", "Rare", "Gold", "Diamond" },
		TierOdds = {
			{ 80, 18, 2, 0 },
			{ 65, 28, 6, 1 },
			{ 50, 32, 14, 4 },
			{ 35, 35, 20, 10 },
		},
		-- Chance that a crate turns one tier better at the end of the opening hold.
		UpgradeChance = 0.12,
		-- Bad-luck protection: a player who has not seen a gold crate by this floor gets one next.
		PityFloor = 3,
		HoldSeconds = 0.8,
		-- Diamond crates are locked: a Key opens them, or a noisy crowbar break-in.
		BreakInSeconds = 5,
		BreakInNoiseRadius = 45,
		BreakInAlertSeconds = 12,
	},

	-- Bare hands, when nothing is held: weak but always there.
	Fists = { damage = 6, cooldown = 0.55, range = 4.5 },

	-- Melee weapons, weakest to strongest (rarity Common / Rare / Gold / Diamond). Damage only goes up
	-- with rarity; a zombie (60 HP) takes 5 / 4 / 3 / 2 hits. The Fighter class multiplies the damage.
	-- rank: higher wins when several are carried.
	Weapons = {
		Club = { damage = 12, cooldown = 0.7, range = 6, rank = 1 },
		Bat = { damage = 16, cooldown = 0.7, range = 6.3, rank = 2 },
		Pipe = { damage = 22, cooldown = 0.75, range = 6.5, rank = 3 },
		Machete = { damage = 34, cooldown = 0.6, range = 7, rank = 4 },
	} :: { [string]: { damage: number, cooldown: number, range: number, rank: number } },

	-- Tokens earned in a match (kept even when the match is lost; doubled for a win).
	Tokens = {
		-- About 25-35 for a typical lost match, double for a win: enough to feel earned, not to flood.
		PerFloor = 2, -- for the deepest floor reached (floor 3 = 6)
		Chest = { Common = 1, Rare = 2, Gold = 4, Diamond = 8 } :: { [string]: number },
		Zombie = 1,
		Build = 3,
		Revive = 2,
		WinMultiplier = 2,
	},

	-- Workbench on the roof.
	Recipes = {
		{ id = "Bandage", cost = { Food = 1, Scrap = 1 } },
		-- Medkits are rare in the floors; two bandages and a can make one.
		{ id = "Medkit", cost = { Bandage = 2, Food = 1 } },
		{ id = "Bat", cost = { Scrap = 2 } },
		{ id = "Pipe", cost = { Scrap = 4 } },
		{ id = "Machete", cost = { Scrap = 5, Electronics = 2 } },
	} :: { { id: string, cost: { [string]: number } } },

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

	-- World layout (studs). The building is lifted high so a default baseplate never overlaps it.
	World = {
		Mode = "Generated" :: "Generated" | "Manual",
		FolderName = "GeneratedWorld",
		RoofY = 396, -- top surface of the roof slab
		FloorSpacing = 24,
		FloorCount = 4,
		RoofSize = 100,
		FloorSize = 70,
		SlabThickness = 2,
		NeighborOffsetX = 150, -- centre of the neighbour tower roof
	},
}

return GameConfig
