--!strict
-- Place ids of the experience. Fill these in after publishing both places
-- (Creator Dashboard > your experience > Places). 0 = not published yet: teleports are disabled
-- and the tower runs every server as solo.

local PlacesConfig = {
	-- Shown in the lobby and printed on start, so it is easy to see which build is published.
	Build = "b20 · lift-rollback-orig",

	LobbyPlaceId = 128619231370772,
	TowerPlaceId = 104145307601846,

	-- Lobby owns live lifts; mirrored here for PlaceIds / build stamp only.
	Lifts = {
		{ id = "LiftA", countdown = 20, fullCountdown = 5 },
		{ id = "LiftB", countdown = 20, fullCountdown = 5 },
	},
	MinPartySize = 2,
	MaxPartySize = 6,

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
