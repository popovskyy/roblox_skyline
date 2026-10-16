--!strict
-- Every item the game knows about. Unknown IDs are rejected everywhere.

export type ItemDef = {
	id: string,
	displayName: string,
	weight: number,
	startAmount: number,
	description: string,
	storable: boolean, -- tools stay with the player and never go into storage
}

local Items: { [string]: ItemDef } = {
	Scrap = {
		id = "Scrap",
		displayName = "Металобрухт",
		weight = 1,
		startAmount = 0,
		description = "Основа для будь-якого поліпшення.",
		storable = true,
	},
	Electronics = {
		id = "Electronics",
		displayName = "Електронні деталі",
		weight = 1,
		startAmount = 0,
		description = "Потрібні для генератора й фільтра.",
		storable = true,
	},
	Food = {
		id = "Food",
		displayName = "Їжа",
		weight = 1,
		startAmount = 2,
		description = "Кожен спуск з'їдає 1 їжу. Без неї через 3 хв почнеш слабшати.",
		storable = true,
	},
	Medkit = {
		id = "Medkit",
		displayName = "Аптечка",
		weight = 2,
		startAmount = 1,
		description = "Відновлює 35 здоров'я.",
		storable = true,
	},
	Cable = {
		id = "Cable",
		displayName = "Кабель",
		weight = 2,
		startAmount = 0,
		description = "Рідкісний. Лежить у руїнах 4 поверху. Потрібен для мосту.",
		storable = true,
	},
	Motor = {
		id = "Motor",
		displayName = "Мотор",
		weight = 3,
		startAmount = 0,
		description = "Рідкісний. Захований за завалами 4 поверху. Потрібен для мосту.",
		storable = true,
	},
	Crowbar = {
		id = "Crowbar",
		displayName = "Лом",
		weight = 3,
		startAmount = 0,
		description = "Розбирає завали з позначкою «Лом».",
		storable = false,
	},
	Flashlight = {
		id = "Flashlight",
		displayName = "Ліхтарик",
		weight = 1,
		startAmount = 0,
		description = "Клавіша F. Заряджається біля генератора.",
		storable = false,
	},
}

-- Display order in the UI.
local Order = { "Scrap", "Electronics", "Food", "Medkit", "Cable", "Motor", "Crowbar", "Flashlight" }

local ItemDefinitions = {
	Items = Items,
	Order = Order,
}

function ItemDefinitions.Get(id: string): ItemDef?
	return Items[id]
end

function ItemDefinitions.IsValid(id: any): boolean
	return type(id) == "string" and Items[id] ~= nil
end

return ItemDefinitions
