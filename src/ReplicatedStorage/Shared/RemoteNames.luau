--!strict
-- Names of every RemoteEvent. The server creates them in ReplicatedStorage.Remotes.

local RemoteNames = {
	-- Server -> client
	StateChanged = "StateChanged",
	Notify = "Notify",
	ShowNote = "ShowNote",
	OpenStorage = "OpenStorage",
	LootOpened = "LootOpened",
	HitFeedback = "HitFeedback", -- to the attacker: (zombie model, killed, hit position)
	Hurt = "Hurt", -- to the victim: (where the hit came from)
	ShowResults = "ShowResults",
	ShowRecords = "ShowRecords", -- lobby only

	-- Client -> server
	RequestState = "RequestState",
	StorageTransfer = "StorageTransfer",
	UseItem = "UseItem",
	ToggleFlashlight = "ToggleFlashlight",
	SetLanguage = "SetLanguage",
	ReturnToLobby = "ReturnToLobby",
	Attack = "Attack",
	Equip = "Equip",
	DropItem = "DropItem",
	Craft = "Craft",
	OpenCraft = "OpenCraft",
	RequestRecords = "RequestRecords", -- lobby only
}

return RemoteNames
