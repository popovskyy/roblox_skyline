--!strict
-- Shared data shapes for server data and the state snapshot sent to clients.

export type ItemCounts = { [string]: number }

export type PlayerData = {
	schemaVersion: number,
	inventory: ItemCounts,
	storage: ItemCounts,
	upgrades: { [string]: boolean },
	flashlightCharge: number, -- seconds of battery left
	uniqueNodesTaken: { [string]: boolean },
	towerCompleted: boolean,
	tutorialStep: number,
	discoveredNotes: { [string]: boolean },
	tokens: number, -- soft currency; session-scoped while PersistProgress is false
	language: string?, -- "uk" | "ru" | "en"; nil = follow the Roblox locale
	-- Monetization stubs, unused while MonetizationConfig.Enabled = false.
	ownedPasses: { [string]: boolean },
	processedReceipts: { [string]: boolean },
}

export type TutorialView = {
	step: number,
	total: number,
	text: string,
	done: boolean,
}

export type StateSnapshot = {
	inventory: ItemCounts,
	storage: ItemCounts,
	upgrades: { [string]: boolean },
	costs: { [string]: { [string]: number } },
	weight: number,
	maxWeight: number,
	storageWeight: number,
	storageCapacity: number,
	flashlightCharge: number,
	flashlightMax: number,
	depletedNodes: { [string]: boolean },
	clearedRubble: { [string]: boolean },
	uniqueNodesTaken: { [string]: boolean },
	backpack: Vector3?,
	tutorial: TutorialView?,
	acts: number,
	saveEnabled: boolean,
	towerCompleted: boolean,
	tokens: number?,
}

return {}
