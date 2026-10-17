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
	weapon: WeaponStats?, -- melee weapons: tapping with one in hand swings it
	resource: boolean?, -- building materials: counted in the pouch, never shown in the hotbar
	use: string?, -- what tapping with it in hand does: "heal", "eat" or "light"
}

export type WeaponStats = {
	damage: number,
	cooldown: number, -- seconds between swings
	range: number, -- studs in front of the player
	rank: number, -- higher rank wins when several are carried
}

local Items: { [string]: ItemDef } = {
	Club = {
		id = "Club",
		icon = "🏏",
		color = Color3.fromRGB(150, 110, 70),
		displayName = "Дубина",
		weight = 0,
		startAmount = 1,
		description = "",
		storable = false,
		weapon = { damage = 12, cooldown = 0.7, range = 6, rank = 1 },
	},
	Pipe = {
		id = "Pipe",
		icon = "🔨",
		color = Color3.fromRGB(140, 145, 155),
		displayName = "Труба",
		weight = 2,
		startAmount = 0,
		description = "",
		storable = false,
		weapon = { damage = 22, cooldown = 0.75, range = 6.5, rank = 2 },
	},
	Machete = {
		id = "Machete",
		icon = "🔪",
		color = Color3.fromRGB(200, 205, 215),
		displayName = "Мачете",
		weight = 2,
		startAmount = 0,
		description = "",
		storable = false,
		weapon = { damage = 34, cooldown = 0.6, range = 7, rank = 3 },
	},
	Bandage = {
		id = "Bandage",
		icon = "🩹",
		color = Color3.fromRGB(235, 220, 200),
		displayName = "Бинт",
		weight = 1,
		startAmount = 0,
		description = "",
		storable = true,
	},
	Scrap = {
		id = "Scrap",
		resource = true,
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
		resource = true,
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
		use = "eat",
		icon = "🥫",
		color = Color3.fromRGB(220, 140, 50),
		displayName = "Їжа",
		weight = 1,
		startAmount = 3,
		description = "Кожен спуск з'їдає 1 їжу. Без неї через 3 хв почнеш слабшати.",
		storable = true,
	},
	Medkit = {
		id = "Medkit",
		use = "heal",
		icon = "💉",
		color = Color3.fromRGB(220, 70, 70),
		displayName = "Аптечка",
		weight = 2,
		startAmount = 1,
		description = "Відновлює 35 здоров'я.",
		storable = true,
	},
	Cable = {
		id = "Cable",
		resource = true,
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
		resource = true,
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
		use = "light",
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
local Order = {
	"Club",
	"Pipe",
	"Machete",
	"Scrap",
	"Electronics",
	"Food",
	"Medkit",
	"Bandage",
	"Cable",
	"Motor",
	"Crowbar",
	"Flashlight",
}

local ItemDefinitions = {
	Items = Items,
	Order = Order,
}

function ItemDefinitions.Get(id: string): ItemDef?
	return Items[id]
end

-- The strongest weapon among the carried items, or nil.
function ItemDefinitions.BestWeapon(inventory: { [string]: number }): ItemDef?
	local best: ItemDef? = nil
	for id, count in inventory do
		local def = Items[id]
		if def and def.weapon and count > 0 and (not best or def.weapon.rank > (best.weapon :: WeaponStats).rank) then
			best = def
		end
	end
	return best
end

function ItemDefinitions.IsValid(id: any): boolean
	return type(id) == "string" and Items[id] ~= nil
end

return ItemDefinitions
