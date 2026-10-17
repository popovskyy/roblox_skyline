--!strict
-- Classes: bought with tokens in the lobby, one picked before the lift, applied in the tower.
-- No class = "Survivor" (no perks). Perks are small: a class gives a co-op role, never a free win.
-- The player's class in the tower is the "Class" player attribute (set by ClassService from the save).

local Classes = {}

export type ClassDef = {
	id: string,
	price: number, -- tokens
	startItems: { [string]: number }?, -- added to the starting inventory (a value of 0 removes the item)
	reviveSpeed: number?, -- revive hold time is divided by this
	walkSpeed: number?, -- multiplier
	flashlightDrain: number?, -- battery drain multiplier (below 1 = lasts longer)
	damage: number?, -- melee damage multiplier
	buildDiscount: number?, -- building cost multiplier
	seeResources: number?, -- studs: resource nodes within this range glow through walls
}

Classes.Order = { "Medic", "Scout", "Fighter", "Mechanic" }

Classes.Defs = {
	Medic = { id = "Medic", price = 60, startItems = { Bandage = 2 }, reviveSpeed = 2 },
	Scout = { id = "Scout", price = 80, walkSpeed = 1.15, flashlightDrain = 0.6 },
	Fighter = { id = "Fighter", price = 100, startItems = { Club = 0, Pipe = 1 }, damage = 1.15 },
	Mechanic = { id = "Mechanic", price = 120, buildDiscount = 0.8, seeResources = 30 },
} :: { [string]: ClassDef }

function Classes.Get(id: any): ClassDef?
	return if type(id) == "string" then Classes.Defs[id] else nil
end

-- The class a player is playing as (tower), or nil for no class.
function Classes.Of(player: Player): ClassDef?
	return Classes.Get(player:GetAttribute("Class"))
end

-- A building cost after the player's class discount (never below 1 of anything).
function Classes.Cost(cost: { [string]: number }, player: Player): { [string]: number }
	local def = Classes.Of(player)
	local factor = def and def.buildDiscount
	if not factor then
		return cost
	end
	local result = {}
	for itemId, amount in cost do
		result[itemId] = math.max(1, math.ceil(amount * factor))
	end
	return result
end

return Classes
