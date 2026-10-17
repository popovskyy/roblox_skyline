--!strict
-- Every item the game knows about. Unknown IDs are rejected everywhere.

export type ItemDef = {
	id: string,
	displayName: string,
	weight: number,
	startAmount: number,
	description: string,
	storable: boolean, -- tools stay with the player and never go into storage
	icon: string, -- emoji placeholder until real icons are drawn
	iconImage: string?, -- rbxassetid://... once an icon is uploaded; wins over the emoji
	color: Color3, -- slot accent colour
}

local Items: { [string]: ItemDef } = {
	Scrap = {
		id = "Scrap",
		icon = "🔩",
		color = Color3.fromRGB(150, 110, 80),
		displayName = "Металобрухт",
		weight = 1,
		startAmount = 0,
		description = "Основа для будь-якого поліпшення.",
		storable = true,
	},
	Electronics = {
		id = "Electronics",
		icon = "💾",
		color = Color3.fromRGB(70, 170, 110),
		displayName = "Електронні деталі",
		weight = 1,
		startAmount = 0,
		description = "Потрібні для генератора й фільтра.",
		storable = true,
	},
	Food = {
		id = "Food",
		icon = "🥫",
		color = Color3.fromRGB(220, 140, 50),
		displayName = "Їжа",
		weight = 1,
		startAmount = 2,
		description = "Кожен спуск з'їдає 1 їжу. Без неї через 3 хв почнеш слабшати.",
		storable = true,
	},
	Medkit = {
		id = "Medkit",
		icon = "🩹",
		color = Color3.fromRGB(220, 70, 70),
		displayName = "Аптечка",
		weight = 2,
		startAmount = 1,
		description = "Відновлює 35 здоров'я.",
		storable = true,
	},
	Cable = {
		id = "Cable",
		icon = "🧵",
		color = Color3.fromRGB(90, 90, 100),
		displayName = "Кабель",
		weight = 2,
		startAmount = 0,
		description = "Рідкісний. Лежить у руїнах 4 поверху. Потрібен для мосту.",
		storable = true,
	},
	Motor = {
		id = "Motor",
		icon = "⚙️",
		color = Color3.fromRGB(100, 130, 170),
		displayName = "Мотор",
		weight = 3,
		startAmount = 0,
		description = "Рідкісний. Захований за завалами 4 поверху. Потрібен для мосту.",
		storable = true,
	},
	Crowbar = {
		id = "Crowbar",
		icon = "🔧",
		color = Color3.fromRGB(180, 60, 50),
		displayName = "Лом",
		weight = 3,
		startAmount = 0,
		description = "Розбирає завали з позначкою «Лом».",
		storable = false,
	},
	Flashlight = {
		id = "Flashlight",
		icon = "🔦",
		color = Color3.fromRGB(230, 200, 60),
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
