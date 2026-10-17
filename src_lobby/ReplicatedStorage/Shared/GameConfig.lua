--!strict
-- Balance and shared settings. Every tunable number lives here.

local GameConfig = {
	-- Inventory and storage
	MaxInventoryWeight = 20,
	StorageCapacity = 60,

	-- Health
	StartingHealth = 100,
	MedkitHeal = 60,

	-- Hazards
	FallDamageThreshold = 18,
	FallDamagePerStud = 2,
	ToxicDamagePerSecond = 8,
	ToxicGraceSeconds = 2,
	AirFilterToxicReduction = 0.75,
	HazardTickSeconds = 0.25,

	-- Food and hunger: each descent below the roof eats ExpeditionFoodCost Food.
	-- Without food, after HungerGraceSeconds below the roof health slowly drops.
	ExpeditionFoodCost = 1,
	HungerGraceSeconds = 180,
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
	} :: { [string]: boolean },
	BackpackDropLifetimeSeconds = 900,
	RespawnDelaySeconds = 3,

	-- Testing: every upgrade costs 1 of each listed item. Never ship with this on.
	TestPrices = false,

	-- Server and saving
	MaxPlayersPerServer = 4,
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
