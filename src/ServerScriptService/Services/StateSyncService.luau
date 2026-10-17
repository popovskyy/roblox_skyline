--!strict
-- Builds the per-player state snapshot and sends it to that player's client.
-- Requests made in the same frame are merged into one send.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local Net = require(script.Parent.Net)

local StateSyncService = {}

type Provider = (player: Player, snapshot: { [string]: any }) -> ()

local providers: { Provider } = {}
local pending: { [Player]: boolean } = {}

-- Services add their part of the snapshot through a provider. Called in registration order.
function StateSyncService.RegisterProvider(provider: Provider)
	table.insert(providers, provider)
end

function StateSyncService.Build(player: Player): { [string]: any }
	local snapshot = {}
	for _, provider in providers do
		provider(player, snapshot)
	end
	return snapshot
end

-- Team-wide changes (shared chest, buildings, rubble): refresh everyone.
function StateSyncService.RequestAll()
	for _, player in game:GetService("Players"):GetPlayers() do
		StateSyncService.Request(player)
	end
end

function StateSyncService.Request(player: Player)
	if pending[player] then
		return
	end
	pending[player] = true
	task.defer(function()
		pending[player] = nil
		if player.Parent then
			Net.Get(RemoteNames.StateChanged):FireClient(player, StateSyncService.Build(player))
		end
	end)
end

return StateSyncService
