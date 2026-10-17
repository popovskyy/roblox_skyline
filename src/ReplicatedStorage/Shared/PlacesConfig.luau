--!strict
-- Place ids of the experience. Fill these in after publishing both places
-- (Creator Dashboard > your experience > Places). 0 = not published yet: teleports are disabled
-- and the tower runs every server as solo.

local PlacesConfig = {
	-- Shown in the lobby and printed on start, so it is easy to see which build is published.
	Build = "b33 · 17.10 19:05",

	LobbyPlaceId = 128619231370772,
	TowerPlaceId = 104145307601846,

	-- Lifts in the lobby. The first player in a lift is the party leader. Group lifts let the leader pick
	-- the party size (PartySizes); until they do, the lift takes `capacity` players.
	Lifts = {
		{ id = "Solo", capacity = 1, countdown = 5 },
		{ id = "GroupA", capacity = 4, countdown = 25, choose = true },
		{ id = "GroupB", capacity = 4, countdown = 25, choose = true },
		{ id = "GroupC", capacity = 4, countdown = 25, choose = true },
	},
	PartySizes = { 2, 3, 4, 5, 6 },

	-- Once a lift is full the rest of its countdown runs this many times faster.
	FullLiftSpeedup = 3,

	-- Party hand-off from the lobby to the reserved tower server.
	PartyMapName = "SkylineZero_Parties",
	PartyTtlSeconds = 600,
	TeleportRetries = 3,

	-- Leaderboard shown in the lobby: towers completed per player.
	LeaderboardStoreName = "SkylineZero_TowersCompleted",
	LeaderboardSize = 10,
	LeaderboardRefreshSeconds = 60,
}

return PlacesConfig
