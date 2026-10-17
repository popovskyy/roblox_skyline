--!strict
-- Every item the game knows about. Unknown IDs are rejected everywhere.

local GameConfig = require(script.Parent.GameConfig)

export type Rarity = "Common" | "Rare" | "Gold" | "Diamond"

export type ItemDef = {
	id: string,
	displayName: string,
	weight: number,
	startAmount: number,
	description: string,
	storable: boolean, -- tools stay with the player and never go into storage
	icon: string, -- emoji placeholder until real icons are drawn
	iconImage: string?, -- rbxassetid://... once an icon is uploaded; wins over the emoji
	iconTint: Color3?, -- ImageColor3 for an icon shared with another item
	color: Color3, -- slot accent colour
	weapon: WeaponStats?, -- melee weapons: tapping with one in hand swings it (stats in GameConfig.Weapons)
	rarity: Rarity?, -- weapons: hotbar frame colour (Theme.Rarity) and the rarity name next to the item name
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
		iconImage = "rbxassetid://92584142342300",
		icon = "🏏",
		color = Color3.fromRGB(150, 110, 70),
		displayName = "Дубина",
		weight = 0,
		startAmount = 1,
		description = "",
		storable = false,
		weapon = GameConfig.Weapons.Club,
		rarity = "Common",
	},
	-- Mesh: WeaponBat after Weapons pack re-upload (CombatService.MESHES).
	-- Icon art ready locally: assets/icons/svg/Bat.svg + Bat.png (scripts/build_icons.py).
	-- Until Open Cloud Image upload prints a real id, keep Club icon + Rare tint — do not invent ids.
	Bat = {
		id = "Bat",
		iconImage = "rbxassetid://92584142342300",
		iconTint = Color3.fromRGB(150, 190, 255),
		icon = "🏏",
		color = Color3.fromRGB(95, 120, 150),
		displayName = "Бита",
		weight = 1,
		startAmount = 0,
		description = "",
		storable = false,
		weapon = GameConfig.Weapons.Bat,
		rarity = "Rare",
	},
	Pipe = {
		id = "Pipe",
		iconImage = "rbxassetid://112963423988838",
		icon = "🔨",
		color = Color3.fromRGB(140, 145, 155),
		displayName = "Труба",
		weight = 2,
		startAmount = 0,
		description = "",
		storable = false,
		weapon = GameConfig.Weapons.Pipe,
		rarity = "Gold",
	},
	Machete = {
		id = "Machete",
		iconImage = "rbxassetid://112505162622574",
		icon = "🔪",
		color = Color3.fromRGB(200, 205, 215),
		displayName = "Мачете",
		weight = 2,
		startAmount = 0,
		description = "",
		storable = false,
		weapon = GameConfig.Weapons.Machete,
		rarity = "Diamond",
	},
	Bandage = {
		id = "Bandage",
		iconImage = "rbxassetid://82682798275686",
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
		iconImage = "rbxassetid://138755986318897",
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
		iconImage = "rbxassetid://124384638159297",
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
		iconImage = "rbxassetid://133647368478245",
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
		iconImage = "rbxassetid://77965608072785",
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
		iconImage = "rbxassetid://120731310353109",
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
		iconImage = "rbxassetid://78241703475664",
		resource = true,
		icon = "⚙️",
		color = Color3.fromRGB(100, 130, 170),
		displayName = "Мотор",
		weight = 3,
		startAmount = 0,
		description = "Рідкісний. Захований за завалами 4 поверху. Потрібен для мосту.",
		storable = true,
	},
	Key = {
		id = "Key",
		iconImage = "rbxassetid://109560612866046",
		icon = "🗝️",
		color = Color3.fromRGB(220, 180, 80),
		displayName = "Ключ",
		weight = 0,
		startAmount = 0,
		description = "",
		storable = true,
	},
	Crowbar = {
		id = "Crowbar",
		iconImage = "rbxassetid://75754748458147",
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
		iconImage = "rbxassetid://84730761121931",
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
	"Bat",
	"Pipe",
	"Machete",
	"Scrap",
	"Electronics",
	"Food",
	"Medkit",
	"Bandage",
	"Cable",
	"Motor",
	"Key",
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
