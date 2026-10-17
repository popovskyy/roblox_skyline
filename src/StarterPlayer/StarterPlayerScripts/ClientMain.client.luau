--!strict
-- Client entry point. Controllers only draw UI and local visuals; the server owns all game state.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Make sure the shared modules have replicated before anything requires them.
local Shared = ReplicatedStorage:WaitForChild("Shared")
for _, name in
	{ "GameConfig", "ItemDefinitions", "UpgradeDefinitions", "RemoteNames", "Types", "MusicConfig", "Locale", "Theme" }
do
	Shared:WaitForChild(name)
end

local RemoteNames = require(Shared:WaitForChild("RemoteNames"))
local Controllers = script.Parent:WaitForChild("Controllers")

local ClientState = require(Controllers:WaitForChild("ClientState"))
local Lang = require(Controllers:WaitForChild("Lang"))
local HUDController = require(Controllers:WaitForChild("HUDController"))
local InventoryController = require(Controllers:WaitForChild("InventoryController"))
local InteractionController = require(Controllers:WaitForChild("InteractionController"))
local MusicController = require(Controllers:WaitForChild("MusicController"))
local ObjectiveMarkerController = require(Controllers:WaitForChild("ObjectiveMarkerController"))
local CombatController = require(Controllers:WaitForChild("CombatController"))
local LootFxController = require(Controllers:WaitForChild("LootFxController"))
local ResultsController = require(Controllers:WaitForChild("ResultsController"))
local IntroController = require(Controllers:WaitForChild("IntroController"))
local TutorialController = require(Controllers:WaitForChild("TutorialController"))
local WorldVisualsController = require(Controllers:WaitForChild("WorldVisualsController"))

local remotes = ReplicatedStorage:WaitForChild("Remotes") :: Folder
local function remote(name: string): RemoteEvent
	return remotes:WaitForChild(name) :: RemoteEvent
end

HUDController.Start()
InventoryController.Start(remotes)
InteractionController.Start(remotes)
TutorialController.Start()
WorldVisualsController.Start()
MusicController.Start()
ObjectiveMarkerController.Start()
CombatController.Start(remotes)
LootFxController.Start(remotes)
ResultsController.Start(remotes)
IntroController.Start()

remote(RemoteNames.StateChanged).OnClientEvent:Connect(function(snapshot)
	if type(snapshot) == "table" then
		ClientState.Set(snapshot)
	end
end)
remote(RemoteNames.Notify).OnClientEvent:Connect(function(message, kind)
	local text = Lang.Format(message)
	if text ~= "" then
		HUDController.Toast(text, if type(kind) == "string" then kind else nil)
	end
end)

-- Redraw everything in the new language.
Lang.Changed:Connect(function()
	local snapshot = ClientState.Get()
	if snapshot then
		ClientState.Set(snapshot)
	end
end)
remote(RemoteNames.ShowNote).OnClientEvent:Connect(TutorialController.ShowNote)
remote(RemoteNames.OpenStorage).OnClientEvent:Connect(InventoryController.OpenStorage)
remote(RemoteNames.OpenCraft).OnClientEvent:Connect(CombatController.OpenCraft)

-- Ask for the current state in case the first snapshot arrived before these listeners existed.
remote(RemoteNames.RequestState):FireServer()
