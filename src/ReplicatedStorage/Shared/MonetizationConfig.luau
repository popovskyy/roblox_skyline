--!strict
-- Monetization is OFF for the MVP. This file is the single place to switch it on later.
-- Planned direction (not final): cosmetic / light-convenience Game Passes and a
-- "backpack insurance" Developer Product. No paid resources and no paid floor skips.

export type PassDef = {
	id: number, -- Game Pass asset id from the Creator Dashboard (0 = not created yet)
	-- Effects the game understands. Leave a field nil for no effect.
	inventoryBonus: number?,
	cosmetic: string?,
}

export type ProductDef = {
	id: number, -- Developer Product id (0 = not created yet)
	-- Name of a handler registered in MonetizationService.RegisterProductHandler.
	handler: string,
}

local MonetizationConfig = {
	Enabled = false,

	GamePasses = {
		-- BiggerBackpack = { id = 0, inventoryBonus = 5 },
		-- LanternColors = { id = 0, cosmetic = "LanternColors" },
	} :: { [string]: PassDef },

	DeveloperProducts = {
		-- BackpackInsurance = { id = 0, handler = "BackpackInsurance" },
		-- Donation100 = { id = 0, handler = "Donation" },
	} :: { [string]: ProductDef },
}

return MonetizationConfig
