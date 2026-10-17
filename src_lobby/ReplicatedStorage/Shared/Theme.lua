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
}

return Theme
