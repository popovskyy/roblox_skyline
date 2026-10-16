--!strict
-- Names of every RemoteEvent. The server creates them in ReplicatedStorage.Remotes.

local RemoteNames = {
	-- Server -> client
	StateChanged = "StateChanged",
	Notify = "Notify",
	ShowNote = "ShowNote",
	OpenStorage = "OpenStorage",

	-- Client -> server
	RequestState = "RequestState",
	StorageTransfer = "StorageTransfer",
	UseItem = "UseItem",
	ToggleFlashlight = "ToggleFlashlight",
	SetLanguage = "SetLanguage",
	ReturnToLobby = "ReturnToLobby",
}

return RemoteNames
