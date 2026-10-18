--!strict
-- Background music. All tracks are free licensed audio from the Roblox Creator Store
-- (uploaded by the verified DistroKid / APM accounts), so they play in any experience.
-- Swap ids here to change the soundtrack.

local MusicConfig = {
	Volume = 0.12, -- quiet background so sound effects stay clear
	HordeVolume = 0.2, -- a little louder while the roof horde is active
	FadeSeconds = 3,

	-- Calm, melancholic tracks for the roof base and the neighbour tower.
	Roof = {
		124181322816807, -- Deserted Embers
		123927270887272, -- Fading World Strings
		71882714223295, -- Silent Ruins Motif
		103760117708996, -- Post Apocalyptic Lullaby
	},

	-- Tense drones for the floors below.
	Below = {
		106752035160966, -- Siberian Wasteland Underscore (Ambient Only)
		139935905572584, -- Corroded Industrial Drone
		140252461454906, -- Subterranean Steel Drones
	},

	-- Roof horde bed: reuse the same verified Creator Store drones (no new invented ids).
	Horde = {
		139935905572584, -- Corroded Industrial Drone
		140252461454906, -- Subterranean Steel Drones
		106752035160966, -- Siberian Wasteland Underscore (Ambient Only)
	},
}

return MusicConfig
