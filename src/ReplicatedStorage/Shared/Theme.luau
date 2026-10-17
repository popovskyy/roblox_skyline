--!strict
-- Fonts used across both places. Oswald for headings and big numbers, Montserrat for everything else.
-- Both families include Cyrillic, so Ukrainian and Russian text keeps the same look.

local function family(name: string, weight: Enum.FontWeight): Font
	return Font.new("rbxasset://fonts/families/" .. name .. ".json", weight)
end

local Theme = {
	Display = family("Oswald", Enum.FontWeight.Bold), -- titles, signs, counters
	Heading = family("Oswald", Enum.FontWeight.Medium),
	Bold = family("Montserrat", Enum.FontWeight.Bold), -- buttons, labels that must stand out
	Body = family("Montserrat", Enum.FontWeight.Medium), -- regular text
	Semi = family("Montserrat", Enum.FontWeight.SemiBold),

	-- HUD colour tokens (docs/design/HUD_SPEC.md). Colour is never the only signal: states also get a word badge.
	Colors = {
		Panel = Color3.fromHex("0F0E0C"), -- with BackgroundTransparency 0.35
		PanelSolid = Color3.fromHex("1E1C18"),
		Slot = Color3.fromHex("14120F"), -- transparency 0.18
		Stroke = Color3.fromHex("EEE6D0"), -- UIStroke transparency 0.65
		Cream = Color3.fromHex("EEE6D0"),
		CreamDim = Color3.fromHex("CFC6AE"),
		Muted = Color3.fromHex("A89F8A"),
		Amber = Color3.fromHex("E3A436"),
		AmberText = Color3.fromHex("F2C46B"),
		Hunger = Color3.fromHex("B4C27A"),
		Danger = Color3.fromHex("E0574A"),
		DangerBg = Color3.fromHex("8A2A20"),
		DangerText = Color3.fromHex("FF9C8F"),
		Heal = Color3.fromHex("9FD18B"),
		Toxic = Color3.fromHex("2F6F64"),
		ToxicFog = Color3.fromHex("6FB3A6"),
	},

	-- Rarity colours, shared by loot crates and weapon slots.
	Rarity = {
		Common = Color3.fromRGB(225, 210, 180),
		Rare = Color3.fromRGB(90, 160, 255),
		Gold = Color3.fromRGB(255, 196, 60),
		Diamond = Color3.fromRGB(110, 240, 255),
	} :: { [string]: Color3 },
}

return Theme
