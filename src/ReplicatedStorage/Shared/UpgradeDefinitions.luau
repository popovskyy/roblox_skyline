--!strict
-- Base upgrades. Prices are read only from here; the client never sends a price.

local GameConfig = require(script.Parent.GameConfig)

export type UpgradeDef = {
	id: string,
	displayName: string,
	description: string,
	cost: { [string]: number },
	requires: { string }, -- upgrades that must be built first
	act: number?, -- story act this upgrade completes (terminal shows acts 0/3)
	order: number,
}

local Upgrades: { [string]: UpgradeDef } = {
	StorageCrate = {
		id = "StorageCrate",
		displayName = "Сховище",
		description = "Ящик на даху на 60 одиниць ваги.",
		cost = { Scrap = 10 },
		requires = {},
		order = 1,
	},
	Generator = {
		id = "Generator",
		displayName = "Генератор",
		description = "Вмикає світло бази, заряджає ліхтарик і відкриває двері на 4 поверх.",
		cost = { Scrap = 8, Electronics = 5 },
		requires = { "StorageCrate" },
		act = 1,
		order = 2,
	},
	AirFilter = {
		id = "AirFilter",
		displayName = "Фільтр повітря",
		description = "Зменшує шкоду від токсичного повітря на 75%.",
		cost = { Scrap = 6, Electronics = 6 },
		requires = { "Generator" },
		act = 2,
		order = 3,
	},
	Bridge = {
		id = "Bridge",
		displayName = "Міст до сусідньої вежі",
		description = "Полагодь міст і вибирайся з вежі.",
		cost = { Scrap = 12, Cable = 4, Motor = 2 },
		requires = { "Generator" },
		act = 3,
		order = 4,
	},
	Barricade = {
		id = "Barricade",
		displayName = "Барикада",
		description = "Дошки біля сходів: зомбі з орди не можуть вийти на дах.",
		cost = { Scrap = 6, Electronics = 1 },
		requires = { "StorageCrate" },
		order = 5,
	},
}

local Order = { "StorageCrate", "Generator", "AirFilter", "Bridge", "Barricade" }

local UpgradeDefinitions = {
	Upgrades = Upgrades,
	Order = Order,
}

function UpgradeDefinitions.Get(id: string): UpgradeDef?
	return Upgrades[id]
end

-- Price actually charged. GameConfig.TestPrices makes every listed item cost 1.
function UpgradeDefinitions.GetCost(def: UpgradeDef): { [string]: number }
	if not GameConfig.TestPrices then
		return def.cost
	end
	local cheap = {}
	for itemId in def.cost do
		cheap[itemId] = 1
	end
	return cheap
end

function UpgradeDefinitions.IsValid(id: any): boolean
	return type(id) == "string" and Upgrades[id] ~= nil
end

return UpgradeDefinitions
