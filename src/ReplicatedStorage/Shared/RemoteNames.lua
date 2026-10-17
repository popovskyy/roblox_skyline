--!strict
-- Names of every RemoteEvent. The server creates them in ReplicatedStorage.Remotes.

local RemoteNames = {
	-- Server -> client
	StateChanged = "StateChanged",
	Notify = "Notify",
	ShowNote = "ShowNote",
	OpenStorage = "OpenStorage",
	-- Designer hooks (first-session UX): live objective line + world marker retarget.
	-- Payload TBD with Design — wire HUD/ObjectiveMarker when onboarding backlog item lands.
	ObjectiveUpdate = "ObjectiveUpdate",
	ObjectiveMarker = "ObjectiveMarker",

	-- Client -> server
	RequestState = "RequestState",
	StorageTransfer = "StorageTransfer",
	UseItem = "UseItem",
	ToggleFlashlight = "ToggleFlashlight",
	SetLanguage = "SetLanguage",
	ReturnToLobby = "ReturnToLobby",
	Attack = "Attack",
	Equip = "Equip",
	Craft = "Craft",
	OpenCraft = "OpenCraft",
	-- Designer/coder hook: intentional ground drop for teammates (backlog item).
	DropItem = "DropItem",
}

return RemoteNames
