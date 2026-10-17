--!strict
-- Sound effects. All ids are licensed audio from the Roblox Creator Store (ProSoundEffects / Roblox),
-- so they play in any experience. A list means one is picked at random each time.

local SoundConfig = {
	Volume = 0.7,
	MaxDistance = 70,

	Sounds = {
		Swing = { 9120972444, 9120972321, 9120972323 },
		HitBlunt = { 9113500380, 9113500510, 9113225986 },
		ZombieGroan = { 9114628818, 9113980480 },
		ZombieAttack = { 9125475729 },
		Hurt = { 9114029889 },
		Pickup = { 9113837381 },
		CrateOpen = { 9120799495, 9120798823 },
		Rubble = { 9118675035, 9118675276 },
		Build = { 9114756916, 9114755635 },
		GeneratorStart = { 9116376366 },
		Eat = { 9114225125 },
		Bandage = { 9114200237 },
		Success = { 9116394545 },
		Click = { 15675032796 },
		LootChime = { 9116394876, 9116394545 },
		LootHum = { 9116328602 },
		LootRise = { 9116420454 },
		LootUpgrade = { 9126073001 },
		LootBanner = { 9116395085 },
		BreakIn = { 9116673915 },
		-- No dedicated siren asset in HANDOFF / Creator Store list; reuse the noisy break-in cue.
		HordeSiren = { 9116673915 },
	} :: { [string]: { number } },
}

return SoundConfig
