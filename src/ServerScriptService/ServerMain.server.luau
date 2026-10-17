--!strict
-- Server entry point: builds the world, initialises services in dependency order, then starts them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = false

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Services = script.Parent.Services
local WorldBuilder = require(script.Parent.WorldBuilder)

local Net = require(Services.Net)
local PlayerDataService = require(Services.PlayerDataService)
local MonetizationService = require(Services.MonetizationService)
local ResourceService = require(Services.ResourceService)
local StorageService = require(Services.StorageService)
local FlashlightService = require(Services.FlashlightService)
local HazardService = require(Services.HazardService)
local TutorialService = require(Services.TutorialService)
local PlayerLifecycleService = require(Services.PlayerLifecycleService)
local InteractionService = require(Services.InteractionService)
local PartyService = require(Services.PartyService)
local DamageService = require(Services.DamageService)
local ZombieService = require(Services.ZombieService)
local CombatService = require(Services.CombatService)
local CraftService = require(Services.CraftService)
local MatchService = require(Services.MatchService)
local MatchStatsService = require(Services.MatchStatsService)
local BaseUpgradeService = require(Services.BaseUpgradeService)
local DropService = require(Services.DropService)

Net.Init()
PlayerDataService.Init()
PlayerLifecycleService.Init()
ResourceService.Init()
FlashlightService.Init()
TutorialService.Init()

if GameConfig.World.Mode == "Generated" then
	local world = WorldBuilder.Build()
	InteractionService.SetInteractables(world.interactables)
	StorageService.SetStoragePart(world.storagePart)
	FlashlightService.SetGeneratorPart(world.generatorPart)
	HazardService.SetToxicZones(world.toxicZones)
	HazardService.SetVictoryZone(world.victoryZone)
	PlayerLifecycleService.SetWorld(world.interactables, world.roofDropPosition)
	CraftService.SetWorkbench(world.workbench)
	DropService.SetFolder(world.interactables)
	ZombieService.Start(world.root)
else
	warn("[ServerMain] World.Mode is Manual: wire a hand-built map into the services before playing")
end

HazardService.OnReturnedToRoof(ResourceService.OnReturnedToRoof)
HazardService.OnZoneChanged(function(player, newZone)
	MatchStatsService.ReachedZone(player, newZone)
end)
BaseUpgradeService.OnPurchased(function(player)
	MatchStatsService.Built(player)
end)

PlayerDataService.Start()
MonetizationService.Start()
StorageService.Start()
FlashlightService.Start()
HazardService.Start()
TutorialService.Start()
InteractionService.Start()
PartyService.Start()
DamageService.Start()
CombatService.Start()
CraftService.Start()
MatchService.Start()
MatchStatsService.Start()
DropService.Start()
PlayerLifecycleService.Start() -- last: it loads characters, so everything above must be ready

print(("[Skyline Zero] Server ready, build %s"):format(require(ReplicatedStorage.Shared.PlacesConfig).Build))
